import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:poker_trainer/core/database/app_database.dart';
import 'package:poker_trainer/core/utils/currency_formatter.dart';
import 'package:poker_trainer/core/utils/date_formatter.dart';
import 'package:poker_trainer/features/bookkeeper/providers/sessions_provider.dart';

class AddSessionScreen extends ConsumerStatefulWidget {
  final int? sessionId;

  const AddSessionScreen({super.key, this.sessionId});

  @override
  ConsumerState<AddSessionScreen> createState() => _AddSessionScreenState();
}

class _AddSessionScreenState extends ConsumerState<AddSessionScreen> {
  final _formKey = GlobalKey<FormState>();

  late DateTime _selectedDate;
  int _gameType = 0; // 0=NLH, 1=PLO
  int _format = 0; // 0=Cash, 1=Tournament
  final _locationController = TextEditingController();
  final _stakesController = TextEditingController();
  final _buyInController = TextEditingController();
  final _cashOutController = TextEditingController();
  final _hoursController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isEditing = false;
  bool _isLoading = true;
  bool _isSaving = false;
  Session? _existingSession;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _isEditing = widget.sessionId != null;

    if (_isEditing) {
      _loadSession();
    } else {
      _isLoading = false;
    }
  }

  void _loadSession() {
    // We load the session data from the stream provider
    // Use addPostFrameCallback to ensure ref is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sessionsAsync = ref.read(sessionsStreamProvider);
      sessionsAsync.whenData((sessions) {
        final session = sessions.where((s) => s.id == widget.sessionId).firstOrNull;
        if (session != null && mounted) {
          setState(() {
            _existingSession = session;
            _selectedDate = session.date;
            _gameType = session.gameType;
            _format = session.format;
            _locationController.text = session.location;
            _stakesController.text = session.stakes;
            _buyInController.text = session.buyIn.toStringAsFixed(2);
            _cashOutController.text = session.cashOut.toStringAsFixed(2);
            _hoursController.text = session.hoursPlayed.toStringAsFixed(1);
            _notesController.text = session.notes ?? '';
            _isLoading = false;
          });
        } else if (mounted) {
          setState(() => _isLoading = false);
        }
      });
    });
  }

  double get _profitLoss {
    final buyIn = double.tryParse(_buyInController.text) ?? 0;
    final cashOut = double.tryParse(_cashOutController.text) ?? 0;
    return cashOut - buyIn;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final buyIn = double.parse(_buyInController.text);
      final cashOut = double.parse(_cashOutController.text);
      final profitLoss = cashOut - buyIn;
      final hours = double.parse(_hoursController.text);
      final notes = _notesController.text.trim();

      if (_isEditing && _existingSession != null) {
        final companion = SessionsCompanion(
          id: Value(widget.sessionId!),
          date: Value(_selectedDate),
          gameType: Value(_gameType),
          format: Value(_format),
          location: Value(_locationController.text.trim()),
          stakes: Value(_stakesController.text.trim()),
          buyIn: Value(buyIn),
          cashOut: Value(cashOut),
          profitLoss: Value(profitLoss),
          hoursPlayed: Value(hours),
          notes: Value(notes.isEmpty ? null : notes),
          createdAt: Value(_existingSession!.createdAt),
          updatedAt: Value(DateTime.now()),
        );
        await ref.read(updateSessionProvider)(companion);
      } else {
        final companion = SessionsCompanion.insert(
          date: _selectedDate,
          gameType: Value(_gameType),
          format: Value(_format),
          location: _locationController.text.trim(),
          stakes: _stakesController.text.trim(),
          buyIn: buyIn,
          cashOut: cashOut,
          profitLoss: profitLoss,
          hoursPlayed: hours,
          notes: Value(notes.isEmpty ? null : notes),
        );
        await ref.read(addSessionProvider)(companion);
      }

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save session: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    _stakesController.dispose();
    _buyInController.dispose();
    _cashOutController.dispose();
    _hoursController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Edit Session' : 'Add Session'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final profitLoss = _profitLoss;
    final profitColor = profitLoss >= 0
        ? Colors.green.shade400
        : Colors.red.shade400;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Session' : 'Add Session'),
        actions: [
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.check),
                  tooltip: 'Save',
                  onPressed: _save,
                ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Date picker
            _DatePickerTile(
              date: _selectedDate,
              onTap: _pickDate,
            ),
            const SizedBox(height: 20),

            // Game type
            Text(
              'Game Type',
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('NLH')),
                ButtonSegment(value: 1, label: Text('PLO')),
              ],
              selected: {_gameType},
              onSelectionChanged: (selected) {
                setState(() => _gameType = selected.first);
              },
            ),
            const SizedBox(height: 20),

            // Format
            Text(
              'Format',
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('Cash')),
                ButtonSegment(value: 1, label: Text('Tournament')),
              ],
              selected: {_format},
              onSelectionChanged: (selected) {
                setState(() => _format = selected.first);
              },
            ),
            const SizedBox(height: 20),

            // Location
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                hintText: 'e.g. Bellagio, Home Game',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Location is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Stakes
            TextFormField(
              controller: _stakesController,
              decoration: const InputDecoration(
                labelText: 'Stakes',
                hintText: 'e.g. 1/2, 2/5',
                prefixIcon: Icon(Icons.monetization_on_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Stakes are required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Buy-in and Cash-out row
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _buyInController,
                    decoration: const InputDecoration(
                      labelText: 'Buy-in',
                      prefixText: '\$ ',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}'),
                      ),
                    ],
                    onChanged: (_) => setState(() {}),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      final parsed = double.tryParse(value);
                      if (parsed == null || parsed <= 0) {
                        return 'Must be > 0';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _cashOutController,
                    decoration: const InputDecoration(
                      labelText: 'Cash-out',
                      prefixText: '\$ ',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}'),
                      ),
                    ],
                    onChanged: (_) => setState(() {}),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      final parsed = double.tryParse(value);
                      if (parsed == null || parsed < 0) {
                        return 'Must be >= 0';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Profit/Loss display
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Profit / Loss',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.formatSigned(profitLoss),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: profitColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Hours played
            TextFormField(
              controller: _hoursController,
              decoration: const InputDecoration(
                labelText: 'Hours Played',
                prefixIcon: Icon(Icons.access_time),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(r'^\d*\.?\d{0,1}'),
                ),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Hours played is required';
                }
                final parsed = double.tryParse(value);
                if (parsed == null || parsed <= 0) {
                  return 'Must be > 0';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Notes
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                prefixIcon: Icon(Icons.notes),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              minLines: 2,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 24),

            // Save button
            FilledButton(
              onPressed: _isSaving ? null : _save,
              child: Text(_isEditing ? 'Update Session' : 'Save Session'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _DatePickerTile extends StatelessWidget {
  final DateTime date;
  final VoidCallback onTap;

  const _DatePickerTile({
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Date',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormatter.formatDate(date),
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ),
            const Spacer(),
            Icon(
              Icons.edit_outlined,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
