import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:poker_trainer/features/trainer/providers/hand_setup_provider.dart';

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

  void _onStartHand() {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(handSetupProvider.notifier);
    final setup = ref.read(handSetupProvider);

    // Apply text field values to the state.
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

    // Store setup for the replay screen to pick up.
    ref.read(activeHandSetupProvider.notifier).state =
        ref.read(handSetupProvider);

    // Navigate to replay with handId=0 to indicate a new hand.
    context.go('/trainer/replay/0');
  }

  @override
  Widget build(BuildContext context) {
    final setup = ref.watch(handSetupProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Hand'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
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
                    decoration: const InputDecoration(labelText: 'Small Blind'),
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
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _bbController,
                    decoration: const InputDecoration(labelText: 'Big Blind'),
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
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _anteController,
                    decoration: const InputDecoration(labelText: 'Ante'),
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
            const SizedBox(height: 24),

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
            const SizedBox(height: 8),
            for (int i = 0; i < setup.playerCount; i++)
              if (i < _nameControllers.length)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      // Seat number
                      SizedBox(
                        width: 28,
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
                      // Stack
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _stackControllers[i],
                          decoration: const InputDecoration(
                            labelText: 'Stack',
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
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
                    ],
                  ),
                ),
            const SizedBox(height: 24),

            // -- Start Button --
            FilledButton.icon(
              onPressed: _onStartHand,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Hand'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
