import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:poker_trainer/core/progression/achievements.dart';
import 'package:poker_trainer/core/progression/achievements_provider.dart';
import 'package:poker_trainer/core/progression/progression_provider.dart';
import 'package:poker_trainer/core/providers/database_provider.dart';
import 'package:poker_trainer/core/services/haptic_service.dart';
import 'package:poker_trainer/core/theme/poker_theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final pt = context.poker;
    final hapticsEnabled = ref.watch(hapticsEnabledProvider);
    final stats = ref.watch(userStatsProvider);
    final achievements = ref.watch(achievementsProvider);
    final totalAchievements = AchievementCatalog.all.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          // Feel
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
                // Preview the new setting right away for immediate feedback.
                ref.read(hapticServiceProvider).medium();
              }
            },
          ),
          const Divider(indent: 16, endIndent: 16, height: 32),
          // Progression
          _SectionHeader(title: 'Progression'),
          ListTile(
            leading: Icon(Icons.star_rounded, color: pt.goldPrimary),
            title: const Text('Lifetime XP'),
            subtitle: Text(
              '${stats.totalXp} XP \u2022 Level ${stats.level} \u2022 '
              '${stats.handsPlayed} hands \u2022 '
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
            subtitle: Text(
              '${achievements.unlockedCount} of $totalAchievements unlocked',
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.go('/settings/achievements'),
          ),
          ListTile(
            leading: Icon(Icons.restart_alt_rounded, color: pt.textMuted),
            title: const Text('Reset progression'),
            subtitle: const Text(
              'Clears streak, XP, level, and achievements',
            ),
            onTap: () => _showResetProgressionDialog(context, ref),
          ),
          const Divider(indent: 16, endIndent: 16, height: 32),
          // About section
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
          // Data section
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
          // Version footer
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
              await ref.read(achievementsProvider.notifier).resetAll();
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
