import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poker_trainer/core/providers/database_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
            leading: Icon(Icons.info_outline, color: colorScheme.primary),
            title: const Text('About'),
            subtitle: const Text('Poker Trainer v1.0.0'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Poker Trainer',
                applicationVersion: '1.0.0',
                applicationIcon: Icon(
                  Icons.casino,
                  size: 48,
                  color: colorScheme.primary,
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
            leading: Icon(Icons.dark_mode, color: colorScheme.primary),
            title: const Text('Theme'),
            subtitle: const Text('Dark'),
            trailing: Icon(
              Icons.check_circle,
              color: colorScheme.primary,
              size: 20,
            ),
          ),
          const Divider(indent: 16, endIndent: 16, height: 32),
          // Data section
          _SectionHeader(title: 'Data'),
          ListTile(
            leading: Icon(Icons.file_upload_outlined, color: colorScheme.primary),
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
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: Text(
              'Clear All Data',
              style: textTheme.bodyLarge?.copyWith(color: Colors.red),
            ),
            subtitle: Text(
              'Delete all sessions and hands permanently',
              style: textTheme.bodySmall?.copyWith(
                color: Colors.red.withValues(alpha: 0.7),
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
                    Icons.casino,
                    size: 32,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Poker Trainer',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Version 1.0.0',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
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
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 36),
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
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
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
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
