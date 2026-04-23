import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:poker_trainer/core/progression/achievements_provider.dart';
import 'package:poker_trainer/core/progression/progression_provider.dart';
import 'package:poker_trainer/core/providers/database_provider.dart';
import 'package:poker_trainer/core/services/haptic_service.dart';
import 'package:poker_trainer/core/theme/poker_theme.dart';
import 'package:poker_trainer/features/onboarding/providers/onboarding_provider.dart';
import 'package:poker_trainer/features/settings/domain/personalization.dart';
import 'package:poker_trainer/features/settings/providers/personalization_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final pt = context.poker;
    final hapticsEnabled = ref.watch(hapticsEnabledProvider);
    final stats = ref.watch(userStatsProvider);
    final personalization = ref.watch(personalizationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          _SectionHeader(title: 'Feel'),
          SwitchListTile(
            secondary: Icon(Icons.vibration_rounded, color: pt.goldPrimary),
            title: const Text('Haptic feedback'),
            subtitle: const Text(
              'Vibrations on taps, wins, and lesson progress',
            ),
            value: hapticsEnabled,
            onChanged: (v) async {
              await ref.read(hapticsEnabledProvider.notifier).set(v);
              if (v) {
                ref.read(hapticServiceProvider).medium();
              }
            },
          ),
          const Divider(indent: 16, endIndent: 16, height: 32),
          _SectionHeader(title: 'Appearance'),
          ListTile(
            leading: Icon(Icons.casino_rounded, color: pt.goldPrimary),
            title: const Text('Table felt'),
            subtitle: Text(
              _feltLabel(personalization.felt),
              style: textTheme.bodySmall?.copyWith(color: pt.textMuted),
            ),
            trailing: _FeltSwatches(selected: personalization.felt),
            onTap: () => _openFeltPicker(context, ref, personalization.felt),
          ),
          ListTile(
            leading: Icon(Icons.style_rounded, color: pt.goldPrimary),
            title: const Text('Card back'),
            subtitle: Text(
              _cardBackLabel(personalization.cardBack),
              style: textTheme.bodySmall?.copyWith(color: pt.textMuted),
            ),
            trailing: _CardBackSwatches(selected: personalization.cardBack),
            onTap: () =>
                _openCardBackPicker(context, ref, personalization.cardBack),
          ),
          const Divider(indent: 16, endIndent: 16, height: 32),
          _SectionHeader(title: 'Audio'),
          ListTile(
            leading: Icon(Icons.volume_up_rounded, color: pt.goldPrimary),
            title: const Text('Sound effects'),
            subtitle: const Text('Audio coming soon'),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SegmentedButton<SoundProfile>(
              segments: const [
                ButtonSegment(value: SoundProfile.off, label: Text('Off')),
                ButtonSegment(
                    value: SoundProfile.subtle, label: Text('Subtle')),
                ButtonSegment(value: SoundProfile.full, label: Text('Full')),
              ],
              selected: {personalization.sound},
              onSelectionChanged: (values) {
                if (values.isEmpty) return;
                ref
                    .read(personalizationProvider.notifier)
                    .setSound(values.first);
              },
            ),
          ),
          const Divider(indent: 16, endIndent: 16, height: 32),
          _SectionHeader(title: 'Progression'),
          ListTile(
            leading: Icon(Icons.star_rounded, color: pt.goldPrimary),
            title: const Text('Lifetime XP'),
            subtitle: Text(
              '${stats.totalXp} XP • Level ${stats.level} • '
              '${stats.handsPlayed} hands • '
              '${stats.lessonsCompleted} lessons',
            ),
          ),
          ListTile(
            leading: Icon(
              Icons.local_fire_department_rounded,
              color: pt.allInGlow,
            ),
            title: const Text('Current streak'),
            subtitle: Text(
              stats.streakDays == 0
                  ? 'No streak yet'
                  : '${stats.streakDays} days '
                      '(best ${stats.bestStreakDays})',
            ),
          ),
          ListTile(
            leading: Icon(Icons.emoji_events_rounded, color: pt.goldPrimary),
            title: const Text('Achievements'),
            subtitle: const Text('View your unlocked badges'),
            trailing: Icon(Icons.chevron_right_rounded, color: pt.textMuted),
            onTap: () => context.push('/achievements'),
          ),
          ListTile(
            leading: Icon(Icons.restart_alt_rounded, color: pt.textMuted),
            title: const Text('Reset progression'),
            subtitle: const Text('Clears streak, XP, and level'),
            onTap: () => _showResetProgressionDialog(context, ref),
          ),
          const Divider(indent: 16, endIndent: 16, height: 32),
          _SectionHeader(title: 'General'),
          ListTile(
            leading: Icon(Icons.info_rounded, color: pt.goldPrimary),
            title: const Text('About'),
            subtitle: const Text('TableSense v1.0.0'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'TableSense',
                applicationVersion: '1.0.0',
                applicationIcon: Icon(
                  Icons.insights_rounded,
                  size: 48,
                  color: pt.goldPrimary,
                ),
                children: [
                  const Text(
                    'A poker session tracker and hand trainer to help '
                    'you improve your game.',
                  ),
                ],
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.replay_rounded, color: pt.goldPrimary),
            title: const Text('Replay intro'),
            subtitle: const Text('Show the welcome tour again'),
            onTap: () async {
              await ref.read(onboardingSeenProvider.notifier).setSeen(false);
              if (context.mounted) {
                context.go('/onboarding');
              }
            },
          ),
          ListTile(
            leading: Icon(Icons.dark_mode_rounded, color: pt.goldPrimary),
            title: const Text('Theme'),
            subtitle: const Text('Dark'),
            trailing: Icon(
              Icons.check_circle_rounded,
              color: pt.goldPrimary,
              size: 20,
            ),
          ),
          const Divider(indent: 16, endIndent: 16, height: 32),
          _SectionHeader(title: 'Data'),
          ListTile(
            leading: Icon(Icons.file_upload_rounded, color: pt.goldPrimary),
            title: const Text('Export Data'),
            subtitle: const Text('Export sessions and hands'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Coming soon'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.delete_forever_rounded, color: pt.loss),
            title: Text(
              'Clear All Data',
              style: textTheme.bodyLarge?.copyWith(color: pt.loss),
            ),
            subtitle: Text(
              'Delete all sessions and hands permanently',
              style: textTheme.bodySmall?.copyWith(
                color: pt.loss.withValues(alpha: 0.7),
              ),
            ),
            onTap: () => _showClearDataDialog(context, ref),
          ),
          const Divider(indent: 16, endIndent: 16, height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.insights_rounded,
                    size: 32,
                    color: pt.goldDark,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'TableSense',
                    style: textTheme.bodyMedium?.copyWith(
                      color: pt.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Version 1.0.0',
                    style: textTheme.bodySmall?.copyWith(
                      color: pt.textMuted.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _feltLabel(TableFeltColor c) {
    switch (c) {
      case TableFeltColor.classicGreen:
        return 'Classic green';
      case TableFeltColor.midnightBlue:
        return 'Midnight blue';
      case TableFeltColor.royalPurple:
        return 'Royal purple';
      case TableFeltColor.charcoalElite:
        return 'Charcoal elite';
    }
  }

  static String _cardBackLabel(CardBackStyle c) {
    switch (c) {
      case CardBackStyle.classicBlue:
        return 'Classic blue';
      case CardBackStyle.royalCrimson:
        return 'Royal crimson';
      case CardBackStyle.noirGold:
        return 'Noir gold';
      case CardBackStyle.emeraldPattern:
        return 'Emerald pattern';
    }
  }

  void _openFeltPicker(
      BuildContext context, WidgetRef ref, TableFeltColor current) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return _FeltPickerSheet(selected: current, onSelect: (c) {
          ref.read(personalizationProvider.notifier).setFelt(c);
        });
      },
    );
  }

  void _openCardBackPicker(
      BuildContext context, WidgetRef ref, CardBackStyle current) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return _CardBackPickerSheet(selected: current, onSelect: (c) {
          ref.read(personalizationProvider.notifier).setCardBack(c);
        });
      },
    );
  }

  void _showResetProgressionDialog(BuildContext context, WidgetRef ref) {
    final pt = context.poker;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(Icons.warning_amber_rounded, color: pt.accent, size: 36),
        title: const Text('Reset progression?'),
        content: const Text(
          'This clears your streak, XP, and level. Saved hands and '
          'sessions are not affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('Cancel', style: TextStyle(color: pt.textMuted)),
          ),
          FilledButton(
            onPressed: () async {
              await ref.read(userStatsProvider.notifier).resetAll();
              await ref.read(achievementsProvider.notifier).reset();
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog(BuildContext context, WidgetRef ref) {
    final pt = context.poker;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(Icons.warning_amber_rounded, color: pt.loss, size: 36),
        title: const Text('Clear All Data?'),
        content: const Text(
          'This will permanently delete all your poker sessions and saved '
          'hands. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: pt.textMuted),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: pt.loss,
              minimumSize: const Size(0, 40),
            ),
            onPressed: () async {
              final db = ref.read(databaseProvider);
              await db.customStatement('DELETE FROM session_tags');
              await db.customStatement('DELETE FROM sessions');
              await db.customStatement('DELETE FROM tags');
              await db.customStatement('DELETE FROM hand_actions');
              await db.customStatement('DELETE FROM hands');
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('All data cleared'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              }
            },
            child: const Text('Clear All Data'),
          ),
        ],
      ),
    );
  }
}

class _FeltSwatches extends StatelessWidget {
  final TableFeltColor selected;

  const _FeltSwatches({required this.selected});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final c in TableFeltColor.values)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: _Swatch(
              color: PersonalizationSettings.feltOverrides(c).feltCenter,
              border: PersonalizationSettings.feltOverrides(c).feltHighlight,
              selected: c == selected,
            ),
          ),
      ],
    );
  }
}

class _CardBackSwatches extends StatelessWidget {
  final CardBackStyle selected;

  const _CardBackSwatches({required this.selected});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final c in CardBackStyle.values)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: _Swatch(
              color: PersonalizationSettings.cardBackOverrides(c)
                  .cardBackPrimary,
              border: PersonalizationSettings.cardBackOverrides(c)
                  .cardBackSecondary,
              selected: c == selected,
            ),
          ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  final Color color;
  final Color border;
  final bool selected;

  const _Swatch({
    required this.color,
    required this.border,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? pt.goldPrimary : border.withValues(alpha: 0.8),
          width: selected ? 2 : 1,
        ),
      ),
    );
  }
}

class _FeltPickerSheet extends StatelessWidget {
  final TableFeltColor selected;
  final ValueChanged<TableFeltColor> onSelect;

  const _FeltPickerSheet({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Choose table felt',
                style: textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            for (final c in TableFeltColor.values)
              _FeltOption(
                color: c,
                selected: selected == c,
                onTap: () {
                  onSelect(c);
                  Navigator.of(context).pop();
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _FeltOption extends StatelessWidget {
  final TableFeltColor color;
  final bool selected;
  final VoidCallback onTap;

  const _FeltOption({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final overrides = PersonalizationSettings.feltOverrides(color);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: RadialGradient(
                  colors: [overrides.feltCenter, overrides.feltEdge],
                ),
                border: Border.all(
                  color: overrides.feltHighlight.withValues(alpha: 0.7),
                ),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.style_rounded,
                  size: 20, color: Colors.white70),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(_labelFor(color)),
            ),
            if (selected)
              Icon(Icons.check_circle_rounded, color: pt.goldPrimary),
          ],
        ),
      ),
    );
  }

  static String _labelFor(TableFeltColor c) {
    switch (c) {
      case TableFeltColor.classicGreen:
        return 'Classic green';
      case TableFeltColor.midnightBlue:
        return 'Midnight blue';
      case TableFeltColor.royalPurple:
        return 'Royal purple';
      case TableFeltColor.charcoalElite:
        return 'Charcoal elite';
    }
  }
}

class _CardBackPickerSheet extends StatelessWidget {
  final CardBackStyle selected;
  final ValueChanged<CardBackStyle> onSelect;

  const _CardBackPickerSheet(
      {required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Choose card back',
                style: textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            for (final c in CardBackStyle.values)
              _CardBackOption(
                style: c,
                selected: selected == c,
                onTap: () {
                  onSelect(c);
                  Navigator.of(context).pop();
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _CardBackOption extends StatelessWidget {
  final CardBackStyle style;
  final bool selected;
  final VoidCallback onTap;

  const _CardBackOption({
    required this.style,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final overrides = PersonalizationSettings.cardBackOverrides(style);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Row(
              children: [
                _MiniCardBack(
                  primary: overrides.cardBackPrimary,
                  secondary: overrides.cardBackSecondary,
                ),
                const SizedBox(width: 6),
                _MiniCardBack(
                  primary: overrides.cardBackPrimary,
                  secondary: overrides.cardBackSecondary,
                ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(_labelFor(style)),
            ),
            if (selected)
              Icon(Icons.check_circle_rounded, color: pt.goldPrimary),
          ],
        ),
      ),
    );
  }

  static String _labelFor(CardBackStyle c) {
    switch (c) {
      case CardBackStyle.classicBlue:
        return 'Classic blue';
      case CardBackStyle.royalCrimson:
        return 'Royal crimson';
      case CardBackStyle.noirGold:
        return 'Noir gold';
      case CardBackStyle.emeraldPattern:
        return 'Emerald pattern';
    }
  }
}

class _MiniCardBack extends StatelessWidget {
  final Color primary;
  final Color secondary;

  const _MiniCardBack({required this.primary, required this.secondary});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        gradient: LinearGradient(
          colors: [primary, secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white24, width: 1),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: pt.goldPrimary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
