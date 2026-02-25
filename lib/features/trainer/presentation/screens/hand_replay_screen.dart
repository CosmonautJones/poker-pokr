import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:poker_trainer/core/providers/database_provider.dart';
import 'package:poker_trainer/core/theme/poker_theme.dart';
import 'package:poker_trainer/features/trainer/data/mappers/hand_mapper.dart';
import 'package:poker_trainer/features/trainer/domain/hand_setup.dart';
import 'package:poker_trainer/features/trainer/domain/pro_tips.dart';
import 'package:poker_trainer/features/trainer/presentation/widgets/action_bar.dart';
import 'package:poker_trainer/features/trainer/presentation/widgets/context_strip.dart';
import 'package:poker_trainer/features/trainer/presentation/widgets/poker_glossary_sheet.dart';
import 'package:poker_trainer/features/trainer/presentation/widgets/poker_table_widget.dart';
import 'package:poker_trainer/features/trainer/presentation/widgets/pro_tip_banner.dart';
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
                break;
              }
            }
            // Load saved branches.
            _loadBranches();
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

  Future<void> _loadBranches() async {
    if (_setup == null || _isNewHand) return;

    try {
      final dao = ref.read(handsDaoProvider);
      final branches = await dao.getBranchesForHand(widget.handId);
      if (branches.isEmpty) return;

      final notifier = ref.read(handReplayProvider(_setup!).notifier);
      for (final branch in branches) {
        final branchActions = await dao.getActionsForHand(branch.id);
        final actions = HandMapper.actionsFromDb(branchActions);
        notifier.loadBranch(
          forkAtActionIndex: branch.branchAtActionIndex ?? 0,
          actions: actions,
          dbHandId: branch.id,
        );
      }
    } catch (_) {
      // Branch loading is best-effort; don't block the UI.
    }
  }

  void _showHistorySheet(BuildContext context, HandSetup setup) {
    final replayState = ref.read(handReplayProvider(setup));
    final notifier = ref.read(handReplayProvider(setup).notifier);
    final gs = replayState.gameState;

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      builder: (_) => _ActionHistoryPanel(
        actions: replayState.actionHistory,
        playerNames: gs.players.map((p) => p.name).toList(),
        branches: replayState.branches,
        activeBranchIndex: replayState.activeBranchIndex,
        onClose: () => Navigator.of(context).pop(),
        onForkAtAction: (index) {
          notifier.forkAtAction(index);
          Navigator.of(context).pop();
        },
        onSwitchBranch: (index) {
          notifier.switchToBranch(index);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  Future<void> _saveHand() async {
    if (_setup == null) return;

    final notifier = ref.read(handReplayProvider(_setup!).notifier);
    final allBranches = notifier.allBranches;

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
      final dao = ref.read(handsDaoProvider);

      // Save the main line (branch 0).
      final (mainInfo, mainStates) = allBranches[0];
      final mainActions = mainStates.last.actionHistory;
      final companion = HandMapper.gameStateToCompanion(
        _setup!,
        mainStates.last,
        title: title.isEmpty ? null : title,
      );
      final actionCompanions = HandMapper.actionsToCompanions(
        0,
        mainActions,
        mainStates,
      );
      final parentId =
          await dao.insertBranchWithActions(companion, actionCompanions);

      // Save additional branches.
      for (var i = 1; i < allBranches.length; i++) {
        final (branchInfo, branchStates) = allBranches[i];
        final branchActions = branchStates.last.actionHistory;
        // Branch actions only include those after the fork point.
        final forkIdx = branchInfo.forkAtActionIndex;
        final newActions = branchActions.sublist(forkIdx);
        final newStates = branchStates.sublist(forkIdx);

        final branchCompanion = HandMapper.gameStateToCompanion(
          _setup!,
          branchStates.last,
          title: branchInfo.label,
          parentHandId: parentId,
          branchAtActionIndex: forkIdx,
        );
        final branchActionCompanions = HandMapper.actionsToCompanions(
          0,
          newActions,
          newStates,
          startIndex: forkIdx,
        );
        await dao.insertBranchWithActions(
            branchCompanion, branchActionCompanions);
      }

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
    final pt = context.poker;

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
              Icon(Icons.error_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.error),
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
    final hasBranches = replayState.branches.length > 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          hasBranches
              ? replayState.branches[replayState.activeBranchIndex].label
              : (_isNewHand ? 'New Hand' : 'Hand #${widget.handId}'),
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
          // Save (when hand is complete or has branches)
          if (replayState.isComplete || hasBranches)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveHand,
              tooltip: 'Save Hand',
            ),
          // Glossary
          IconButton(
            icon: const Icon(Icons.menu_book_rounded),
            onPressed: () => PokerGlossarySheet.show(context),
            tooltip: 'Poker Glossary',
          ),
          // History log
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _showHistorySheet(context, setup),
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
                          border: Border.all(color: pt.accent),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Hand Complete',
                              style: TextStyle(
                                color: pt.accent,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (gs.winnerIndices != null &&
                                gs.winnerIndices!.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'Winner${gs.winnerIndices!.length > 1 ? "s" : ""}: '
                                  '${gs.winnerIndices!.map((i) => gs.players[i].name).join(", ")}',
                                  style: TextStyle(
                                    color: pt.textMuted,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              // Show winning hand description(s).
                              if (gs.handDescriptions.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    gs.winnerIndices!
                                        .where((i) =>
                                            gs.handDescriptions
                                                .containsKey(i))
                                        .map((i) =>
                                            gs.handDescriptions[i]!)
                                        .toSet()
                                        .join(' / '),
                                    style: TextStyle(
                                      color: pt.accentMuted,
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                            ],
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
              ],
            ),
          ),
          // Educational context strip
          if (!replayState.isComplete)
            ContextStrip(context_: replayState.educationalContext),
          // Pro tip banner
          if (!replayState.isComplete)
            ProTipBanner(
              tip: ProTipEngine.compute(replayState.educationalContext),
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

/// Side panel showing action history log with branch support.
class _ActionHistoryPanel extends StatefulWidget {
  final List<PokerAction> actions;
  final List<String> playerNames;
  final List<dynamic> branches;
  final int activeBranchIndex;
  final VoidCallback onClose;
  final void Function(int actionIndex) onForkAtAction;
  final void Function(int branchIndex) onSwitchBranch;

  const _ActionHistoryPanel({
    required this.actions,
    required this.playerNames,
    required this.branches,
    required this.activeBranchIndex,
    required this.onClose,
    required this.onForkAtAction,
    required this.onSwitchBranch,
  });

  @override
  State<_ActionHistoryPanel> createState() => _ActionHistoryPanelState();
}

class _ActionHistoryPanelState extends State<_ActionHistoryPanel> {
  int? _selectedActionIndex;

  String _formatChips(double amount) {
    if (amount == amount.roundToDouble() && amount < 10000) {
      return amount.toStringAsFixed(0);
    }
    return amount.toStringAsFixed(2);
  }

  String _actionLabel(PokerAction action) {
    final name = action.playerIndex < widget.playerNames.length
        ? widget.playerNames[action.playerIndex]
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

  Color _actionColor(BuildContext context, ActionType type) {
    final pt = context.poker;
    return switch (type) {
      ActionType.fold => pt.textMuted,
      ActionType.check => pt.actionCheck,
      ActionType.call => pt.profit,
      ActionType.bet => pt.accent,
      ActionType.raise => pt.accent,
      ActionType.allIn => pt.actionAllIn,
    };
  }

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final hasBranches = widget.branches.length > 1;
    final activeBranch = widget.branches[widget.activeBranchIndex];
    final forkAt = activeBranch.forkAtActionIndex as int;

    return Column(
      children: [
        // Drag handle
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: pt.cardBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Action History',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: widget.onClose,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 48,
                  minHeight: 48,
                ),
              ),
            ],
          ),
        ),
        // Branch switcher
        if (hasBranches)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(widget.branches.length, (i) {
                  final branch = widget.branches[i];
                  final isActive = i == widget.activeBranchIndex;
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: ChoiceChip(
                      label: Text(
                        branch.label as String,
                        style: const TextStyle(fontSize: 11),
                      ),
                      selected: isActive,
                      onSelected: (_) => widget.onSwitchBranch(i),
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                  );
                }),
              ),
            ),
          ),
        const Divider(height: 1),
        // Action list
        Expanded(
          child: widget.actions.isEmpty
              ? Center(
                  child: Text(
                    'No actions yet',
                    style: TextStyle(color: pt.textMuted, fontSize: 13),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: widget.actions.length,
                  itemBuilder: (context, index) {
                    final action = widget.actions[index];
                    final isSelected = _selectedActionIndex == index;
                    final isDivergencePoint =
                        hasBranches && index == forkAt && forkAt > 0;

                    return Column(
                      children: [
                        if (isDivergencePoint)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 2),
                            child: Row(
                              children: [
                                Icon(Icons.call_split,
                                    size: 12, color: pt.accent),
                                const SizedBox(width: 4),
                                Text(
                                  'Branch point',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: pt.accent,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        InkWell(
                          onTap: () {
                            setState(() {
                              _selectedActionIndex =
                                  isSelected ? null : index;
                            });
                          },
                          child: Container(
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.08)
                                : null,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 24,
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      color: pt.borderSubtle,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    _actionLabel(action),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: _actionColor(
                                          context, action.type),
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  GestureDetector(
                                    onTap: () {
                                      widget.onForkAtAction(index + 1);
                                      setState(
                                          () => _selectedActionIndex = null);
                                    },
                                    child: Tooltip(
                                      message:
                                          'Fork here \u2014 try a different line',
                                      child: Icon(
                                        Icons.call_split,
                                        size: 18,
                                        color: pt.accent,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }
}
