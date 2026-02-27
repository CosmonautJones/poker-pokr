import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:poker_trainer/core/providers/database_provider.dart';
import 'package:poker_trainer/features/trainer/data/mappers/hand_mapper.dart';
import 'package:poker_trainer/features/trainer/presentation/widgets/hole_card_selector.dart';
import 'package:poker_trainer/features/trainer/presentation/widgets/stack_picker.dart';
import 'package:poker_trainer/features/trainer/providers/hand_setup_provider.dart';
import 'package:poker_trainer/poker/models/game_type.dart';

class CreateHandScreen extends ConsumerStatefulWidget {
  const CreateHandScreen({super.key});

  @override
  ConsumerState<CreateHandScreen> createState() => _CreateHandScreenState();
}

class _CreateHandScreenState extends ConsumerState<CreateHandScreen> {
  final _sbController = TextEditingController(text: '1');
  final _bbController = TextEditingController(text: '2');
  final _anteController = TextEditingController(text: '0');
  final List<TextEditingController> _nameControllers = [];
  final List<TextEditingController> _stackControllers = [];
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Initialize from the current setup state.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncFromState();
    });
  }

  void _syncFromState() {
    final setup = ref.read(handSetupProvider);
    _sbController.text = _formatNum(setup.smallBlind);
    _bbController.text = _formatNum(setup.bigBlind);
    _anteController.text = _formatNum(setup.ante);
    _rebuildPlayerControllers(setup.playerCount);
  }

  void _rebuildPlayerControllers(int count) {
    final setup = ref.read(handSetupProvider);
    // Dispose old controllers beyond the count.
    while (_nameControllers.length > count) {
      _nameControllers.removeLast().dispose();
      _stackControllers.removeLast().dispose();
    }
    // Add new controllers up to count.
    while (_nameControllers.length < count) {
      final i = _nameControllers.length;
      _nameControllers.add(TextEditingController(
        text: i < setup.playerNames.length
            ? setup.playerNames[i]
            : 'Player ${i + 1}',
      ));
      _stackControllers.add(TextEditingController(
        text: i < setup.stacks.length
            ? _formatNum(setup.stacks[i])
            : _formatNum(setup.bigBlind * 100),
      ));
    }
    if (mounted) setState(() {});
  }

  String _formatNum(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _sbController.dispose();
    _bbController.dispose();
    _anteController.dispose();
    for (final c in _nameControllers) {
      c.dispose();
    }
    for (final c in _stackControllers) {
      c.dispose();
    }
    super.dispose();
  }

  /// Sync text field values into the handSetupProvider state.
  void _syncFieldsToState() {
    final notifier = ref.read(handSetupProvider.notifier);
    final setup = ref.read(handSetupProvider);

    notifier.setSmallBlind(double.tryParse(_sbController.text) ?? 1);
    notifier.setBigBlind(double.tryParse(_bbController.text) ?? 2);
    notifier.setAnte(double.tryParse(_anteController.text) ?? 0);

    for (int i = 0; i < setup.playerCount; i++) {
      if (i < _nameControllers.length) {
        notifier.setPlayerName(i, _nameControllers[i].text);
      }
      if (i < _stackControllers.length) {
        final stack = double.tryParse(_stackControllers[i].text);
        if (stack != null) notifier.setPlayerStack(i, stack);
      }
    }
  }

  void _onStartHand() {
    if (!_formKey.currentState!.validate()) return;

    _syncFieldsToState();

    // Store setup for the replay screen to pick up.
    ref.read(activeHandSetupProvider.notifier).state =
        ref.read(handSetupProvider);

    // Navigate to replay with handId=0 to indicate a new hand.
    context.go('/trainer/replay/0');
  }

  Future<void> _onSaveSetup() async {
    if (!_formKey.currentState!.validate()) return;

    _syncFieldsToState();
    final setup = ref.read(handSetupProvider);

    // Show a dialog to enter a title.
    final title = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController(
          text: '${setup.smallBlind}/${setup.bigBlind} '
              '${setup.playerCount}-handed',
        );
        return AlertDialog(
          title: const Text('Save Setup'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Title',
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
      final companion = HandMapper.setupToSavedCompanion(
        setup,
        title: title.isEmpty ? null : title,
      );
      await ref.read(handsDaoProvider).insertSavedSetup(companion);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Setup saved for practice')),
        );
        context.go('/trainer');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save setup: $e')),
        );
      }
    }
  }

  Future<void> _openStackPicker(int playerIndex) async {
    final currentStack =
        double.tryParse(_stackControllers[playerIndex].text) ?? 200;
    final bb = double.tryParse(_bbController.text) ?? 2;
    final result = await StackPickerBottomSheet.show(
      context,
      currentStack: currentStack,
      bigBlind: bb,
    );
    if (result != null) {
      _stackControllers[playerIndex].text = _formatNum(result);
      ref.read(handSetupProvider.notifier).setPlayerStack(playerIndex, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final setup = ref.watch(handSetupProvider);
    final notifier = ref.read(handSetupProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Hand'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          children: [
            // -- Game Type --
            Text(
              'Game Type',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            SegmentedButton<GameType>(
              segments: const [
                ButtonSegment(
                  value: GameType.texasHoldem,
                  label: Text("Hold'em"),
                ),
                ButtonSegment(
                  value: GameType.omaha,
                  label: Text('Omaha'),
                ),
              ],
              selected: {setup.gameType},
              onSelectionChanged: (selected) {
                notifier.setGameType(selected.first);
              },
            ),
            const SizedBox(height: 16),

            // -- Player Count --
            Text(
              'Players: ${setup.playerCount}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Slider(
              value: setup.playerCount.toDouble(),
              min: 2,
              max: 9,
              divisions: 7,
              label: '${setup.playerCount}',
              onChanged: (v) {
                ref.read(handSetupProvider.notifier).setPlayerCount(v.round());
                _rebuildPlayerControllers(v.round());
              },
            ),
            const SizedBox(height: 16),

            // -- Blinds --
            Text(
              'Blinds & Ante',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _sbController,
                    decoration: const InputDecoration(
                      labelText: 'SB',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      final val = double.tryParse(v);
                      if (val == null || val <= 0) return 'Must be > 0';
                      final bb = double.tryParse(_bbController.text);
                      if (bb != null && val >= bb) return 'Must be < BB';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _bbController,
                    decoration: const InputDecoration(
                      labelText: 'BB',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      final val = double.tryParse(v);
                      if (val == null || val <= 0) return 'Must be > 0';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _anteController,
                    decoration: const InputDecoration(
                      labelText: 'Ante',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // -- Straddle --
            if (setup.playerCount >= 3) ...[
              SwitchListTile(
                title: const Text('Straddle'),
                subtitle: setup.straddleEnabled
                    ? Text(
                        '${_formatNum(setup.straddleAmount)} '
                        '(${_formatNum(setup.straddleMultiplier)}x BB)',
                      )
                    : null,
                value: setup.straddleEnabled,
                contentPadding: EdgeInsets.zero,
                onChanged: (v) => notifier.setStraddleEnabled(v),
              ),
              if (setup.straddleEnabled)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Wrap(
                    spacing: 8,
                    children: [2.0, 3.0, 5.0].map((mult) {
                      return ChoiceChip(
                        label: Text('${mult.toStringAsFixed(0)}x'),
                        selected: setup.straddleMultiplier == mult,
                        onSelected: (_) =>
                            notifier.setStraddleMultiplier(mult),
                      );
                    }).toList(),
                  ),
                ),
            ],
            const SizedBox(height: 8),

            // -- Dealer Position --
            Text(
              'Dealer Position',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: List.generate(setup.playerCount, (i) {
                final isSelected = i == setup.dealerIndex;
                return ChoiceChip(
                  label: Text('${i + 1}'),
                  selected: isSelected,
                  onSelected: (_) {
                    ref.read(handSetupProvider.notifier).setDealerIndex(i);
                  },
                );
              }),
            ),
            const SizedBox(height: 24),

            // -- Player Details --
            Text(
              'Players',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Tap cards to pick, long-press to clear',
              style: TextStyle(
                color: Colors.grey.shade300,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () {
                      for (int i = 0; i < setup.playerCount; i++) {
                        notifier.dealRandomHoleCards(i);
                      }
                    },
                    icon: const Icon(Icons.casino, size: 16),
                    label: const Text('Deal All'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () {
                      for (int i = 0; i < setup.playerCount; i++) {
                        notifier.clearPlayerHoleCards(i);
                      }
                    },
                    icon: const Icon(Icons.clear, size: 16),
                    label: const Text('Clear All'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (int i = 0; i < setup.playerCount; i++)
              if (i < _nameControllers.length)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Row 1: Seat number, Name, Stack
                      Row(
                        children: [
                          // Seat number
                          SizedBox(
                            width: 22,
                            child: Text(
                              '${i + 1}',
                              style: TextStyle(
                                color: i == setup.dealerIndex
                                    ? Colors.amber
                                    : Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          // Name
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _nameControllers[i],
                              decoration: InputDecoration(
                                labelText: 'Name',
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                suffixIcon: i == setup.dealerIndex
                                    ? const Tooltip(
                                        message: 'Dealer',
                                        child: Icon(Icons.circle,
                                            color: Colors.amber, size: 12),
                                      )
                                    : null,
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Required';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Stack with tap-to-scroll-pick
                          Expanded(
                            flex: 2,
                            child: GestureDetector(
                              onLongPress: () => _openStackPicker(i),
                              child: TextFormField(
                                controller: _stackControllers[i],
                                decoration: InputDecoration(
                                  labelText: 'Stack',
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      Icons.tune,
                                      size: 16,
                                      color: Colors.grey.shade500,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 24,
                                      minHeight: 24,
                                    ),
                                    onPressed: () => _openStackPicker(i),
                                    tooltip: 'Pick stack amount',
                                  ),
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d*\.?\d{0,2}')),
                                ],
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Required';
                                  final val = double.tryParse(v);
                                  if (val == null || val <= 0) return '> 0';
                                  return null;
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Row 2: Hole cards
                      Padding(
                        padding: const EdgeInsets.only(left: 22, top: 6),
                        child: HoleCardSelector(
                          playerIndex: i,
                          cardCount: setup.gameType.holeCardCount,
                          holeCards: setup.holeCards != null &&
                                  i < setup.holeCards!.length
                              ? setup.holeCards![i]
                              : null,
                          unavailableCardValues:
                              notifier.usedCardValues(i),
                          onCardSelected: (cardIndex, card) =>
                              notifier.setPlayerHoleCard(i, cardIndex, card),
                          onCardCleared: (cardIndex) =>
                              notifier.clearPlayerHoleCard(i, cardIndex),
                          onRandomDeal: () =>
                              notifier.dealRandomHoleCards(i),
                        ),
                      ),
                    ],
                  ),
                ),
            const SizedBox(height: 24),

            // -- Action Buttons --
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _onSaveSetup,
                    icon: const Icon(Icons.bookmark_add),
                    label: const Text('Save Setup'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 52),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _onStartHand,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start Hand'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 52),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
