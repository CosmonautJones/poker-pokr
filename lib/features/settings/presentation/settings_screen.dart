import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poker_trainer/core/providers/database_provider.dart';
import 'package:poker_trainer/core/theme/poker_theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final pt = context.poker;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
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
