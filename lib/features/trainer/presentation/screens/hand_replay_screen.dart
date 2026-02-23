import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:poker_trainer/core/providers/database_provider.dart';
import 'package:poker_trainer/features/trainer/data/mappers/hand_mapper.dart';
import 'package:poker_trainer/features/trainer/domain/hand_setup.dart';
import 'package:poker_trainer/features/trainer/presentation/widgets/action_bar.dart';
import 'package:poker_trainer/features/trainer/presentation/widgets/poker_table_widget.dart';
import 'package:poker_trainer/features/trainer/providers/hand_replay_provider.dart';
import 'package:poker_trainer/features/trainer/providers/hand_setup_provider.dart';
import 'package:poker_trainer/poker/models/action.dart';

class HandReplayScreen extends ConsumerStatefulWidget {
  final int handId;

  const HandReplayScreen({super.key, required this.handId});

  @override
  ConsumerState<HandReplayScreen> createState() => _HandReplayScreenState();
}

class _HandReplayScreenState extends ConsumerState<HandReplayScreen> {
  HandSetup? _setup;
  bool _isLoading = true;
  String? _error;
  bool _historyExpanded = false;

  /// Whether this is a new hand (handId == 0) or a saved hand.
  bool get _isNewHand => widget.handId == 0;

  @override
  void initState() {
    super.initState();
    _loadSetup();
  }

  Future<void> _loadSetup() async {
    if (_isNewHand) {
      // New hand: read from the activeHandSetupProvider.
      final activeSetup = ref.read(activeHandSetupProvider);
      if (activeSetup != null) {
        setState(() {
          _setup = activeSetup;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'No active hand setup found.';
          _isLoading = false;
        });
      }
    } else {
      // Saved hand: load from database and replay actions.
      try {
        final dao = ref.read(handsDaoProvider);
        final hand = await dao.getHand(widget.handId);
        final dbActions = await dao.getActionsForHand(widget.handId);
        final setup = HandMapper.handToSetup(hand);
        final actions = HandMapper.actionsFromDb(dbActions);

        setState(() {
          _setup = setup;
          _isLoading = false;
        });

        // Replay all saved actions after the provider builds.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_setup != null) {
            final notifier = ref.read(handReplayProvider(_setup!).notifier);
            for (final action in actions) {
              try {
                notifier.applyAction(action);
              } catch (e) {
                // Stop replaying if an action is invalid.
                break;
              }
            }
          }
        });
      } catch (e) {
        setState(() {
          _error = 'Failed to load hand: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveHand() async {
    if (_setup == null) return;

    final notifier = ref.read(handReplayProvider(_setup!).notifier);
    final replayState = ref.read(handReplayProvider(_setup!));
    final allStates = notifier.allStates;

    // Show a dialog to enter a title.
    final title = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController(
          text: '${_setup!.smallBlind}/${_setup!.bigBlind} '
              '${_setup!.playerCount}-handed',
        );
        return AlertDialog(
          title: const Text('Save Hand'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Title (optional)',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (title == null) return; // User cancelled.

    try {
      final companion = HandMapper.gameStateToCompanion(
        _setup!,
        replayState.gameState,
        title: title.isEmpty ? null : title,
      );
      final actionCompanions = HandMapper.actionsToCompanions(
        0, // Will be replaced by the DAO.
        replayState.actionHistory,
        allStates,
      );

      await ref.read(handsDaoProvider).insertHandWithActions(
            companion,
            actionCompanions,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hand saved successfully')),
        );
        context.go('/trainer');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Hand Replay')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _setup == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Hand Replay')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
              const SizedBox(height: 16),
              Text(_error ?? 'Unknown error'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go('/trainer'),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    final setup = _setup!;
    final replayState = ref.watch(handReplayProvider(setup));
    final notifier = ref.read(handReplayProvider(setup).notifier);
    final gs = replayState.gameState;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isNewHand ? 'New Hand' : 'Hand #${widget.handId}',
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/trainer'),
        ),
        actions: [
          // Undo
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: replayState.canUndo ? () => notifier.undo() : null,
            tooltip: 'Undo',
          ),
          // Redo
          IconButton(
            icon: const Icon(Icons.redo),
            onPressed: replayState.canRedo ? () => notifier.redo() : null,
            tooltip: 'Redo',
          ),
          // Save (when hand is complete)
          if (replayState.isComplete)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveHand,
              tooltip: 'Save Hand',
            ),
          // History log
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              setState(() {
                _historyExpanded = !_historyExpanded;
              });
            },
            tooltip: 'Action History',
          ),
        ],
      ),
      body: Column(
        children: [
          // Table area
          Expanded(
            child: Stack(
              children: [
                PokerTableWidget(gameState: gs),
                // Hand complete overlay
                if (replayState.isComplete)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 8,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Hand Complete',
                              style: TextStyle(
                                color: Colors.amber,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (gs.winnerIndices != null &&
                                gs.winnerIndices!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'Winner${gs.winnerIndices!.length > 1 ? "s" : ""}: '
                                  '${gs.winnerIndices!.map((i) => gs.players[i].name).join(", ")}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                OutlinedButton(
                                  onPressed: () => context.go('/trainer'),
                                  child: const Text('Back'),
                                ),
                                const SizedBox(width: 12),
                                FilledButton.icon(
                                  onPressed: _saveHand,
                                  icon: const Icon(Icons.save, size: 18),
                                  label: const Text('Save'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                // Action history panel
                if (_historyExpanded)
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: _ActionHistoryPanel(
                      actions: replayState.actionHistory,
                      playerNames:
                          gs.players.map((p) => p.name).toList(),
                      onClose: () =>
                          setState(() => _historyExpanded = false),
                    ),
                  ),
              ],
            ),
          ),
          // Action bar (only when hand is not complete)
          if (!replayState.isComplete)
            ActionBar(
              currentPlayerIndex: gs.currentPlayerIndex,
              legalActions: replayState.legalActions,
              currentPot: gs.pot,
              onAction: (action) => notifier.applyAction(action),
            ),
        ],
      ),
    );
  }
}

/// Side panel showing action history log.
class _ActionHistoryPanel extends StatelessWidget {
  final List<PokerAction> actions;
  final List<String> playerNames;
  final VoidCallback onClose;

  const _ActionHistoryPanel({
    required this.actions,
    required this.playerNames,
    required this.onClose,
  });

  String _formatChips(double amount) {
    if (amount == amount.roundToDouble() && amount < 10000) {
      return amount.toStringAsFixed(0);
    }
    return amount.toStringAsFixed(2);
  }

  String _actionLabel(PokerAction action) {
    final name = action.playerIndex < playerNames.length
        ? playerNames[action.playerIndex]
        : 'P${action.playerIndex}';
    return switch (action.type) {
      ActionType.fold => '$name folds',
      ActionType.check => '$name checks',
      ActionType.call => '$name calls ${_formatChips(action.amount)}',
      ActionType.bet => '$name bets ${_formatChips(action.amount)}',
      ActionType.raise => '$name raises to ${_formatChips(action.amount)}',
      ActionType.allIn => '$name all-in ${_formatChips(action.amount)}',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: Colors.grey.shade900.withValues(alpha: 0.95),
        border: Border(
          left: BorderSide(color: Colors.grey.shade700),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Action History',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: onClose,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Action list
          Expanded(
            child: actions.isEmpty
                ? const Center(
                    child: Text(
                      'No actions yet',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: actions.length,
                    itemBuilder: (context, index) {
                      final action = actions[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 3),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 20,
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                _actionLabel(action),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _actionColor(action.type),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Color _actionColor(ActionType type) {
    return switch (type) {
      ActionType.fold => Colors.grey,
      ActionType.check => Colors.blueGrey.shade300,
      ActionType.call => Colors.green.shade300,
      ActionType.bet => Colors.amber.shade300,
      ActionType.raise => Colors.amber.shade300,
      ActionType.allIn => Colors.deepOrange.shade300,
    };
  }
}
