import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:poker_trainer/core/database/app_database.dart';
import 'package:poker_trainer/core/providers/database_provider.dart';
import 'package:poker_trainer/core/utils/date_formatter.dart';
import 'package:poker_trainer/features/trainer/data/mappers/hand_mapper.dart';
import 'package:poker_trainer/features/trainer/presentation/screens/lessons_list_screen.dart';
import 'package:poker_trainer/features/trainer/providers/hand_setup_provider.dart';
import 'package:poker_trainer/features/trainer/providers/hands_provider.dart';
import 'package:poker_trainer/poker/models/game_type.dart';

class HandListScreen extends ConsumerStatefulWidget {
  const HandListScreen({super.key});

  @override
  ConsumerState<HandListScreen> createState() => _HandListScreenState();
}

class _HandListScreenState extends ConsumerState<HandListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trainer'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Saved'),
            Tab(text: 'Hands'),
            Tab(text: 'Lessons'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const _SavedSetupsTab(),
          _HandsTab(),
          const LessonsListScreen(),
        ],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (context, _) {
          // Show FAB on the Saved and Hands tabs, hide on Lessons.
          if (_tabController.index == 2) return const SizedBox.shrink();
          return FloatingActionButton(
            onPressed: () => context.go('/trainer/create'),
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }
}

class _SavedSetupsTab extends ConsumerWidget {
  const _SavedSetupsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setupsAsync = ref.watch(savedSetupsStreamProvider);

    return setupsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              'Failed to load saved setups',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      data: (setups) {
        if (setups.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.bookmark_border,
                  size: 64,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(height: 16),
                Text(
                  'No saved setups yet',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey.shade500,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap + to create and save a hand setup for practice',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 80),
          itemCount: setups.length,
          itemBuilder: (context, index) {
            final hand = setups[index];
            return _SavedSetupTile(hand: hand);
          },
        );
      },
    );
  }
}

class _SavedSetupTile extends ConsumerWidget {
  final Hand hand;

  const _SavedSetupTile({required this.hand});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = hand.title ?? 'Setup #${hand.id}';
    final gameTypeLabel =
        GameType.values[hand.gameType] == GameType.omaha ? 'PLO' : "NLH";
    final subtitle =
        '${hand.playerCount} players  |  '
        '${hand.smallBlind}/${hand.bigBlind}  |  '
        '$gameTypeLabel';

    return Dismissible(
      key: ValueKey(hand.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: Colors.red.shade800,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Setup'),
            content: Text('Are you sure you want to delete "$title"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        ref.read(handsDaoProvider).deleteHand(hand.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$title deleted')),
        );
      },
      child: Card(
        child: ListTile(
          leading: const Icon(Icons.bookmark, size: 24),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: IconButton(
            icon: const Icon(Icons.play_arrow),
            tooltip: 'Practice',
            onPressed: () => _practiceSetup(context, ref),
          ),
          onTap: () => _practiceSetup(context, ref),
        ),
      ),
    );
  }

  void _practiceSetup(BuildContext context, WidgetRef ref) {
    final setup = HandMapper.handToSetup(hand);
    ref.read(activeHandSetupProvider.notifier).state = setup;
    context.go('/trainer/replay/0');
  }
}

class _HandsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final handsAsync = ref.watch(playedHandsStreamProvider);

    return handsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              'Failed to load hands',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      data: (hands) {
        if (hands.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.style_outlined,
                  size: 64,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(height: 16),
                Text(
                  'No saved hands yet',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey.shade500,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap + to create your first hand',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 80),
          itemCount: hands.length,
          itemBuilder: (context, index) {
            final hand = hands[index];
            return _HandListTile(hand: hand);
          },
        );
      },
    );
  }
}

class _HandListTile extends ConsumerWidget {
  final Hand hand;

  const _HandListTile({required this.hand});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = hand.title ?? 'Hand #${hand.id}';
    final subtitle =
        '${hand.playerCount} players  |  '
        '${hand.smallBlind}/${hand.bigBlind}';
    final dateStr = DateFormatter.formatDateTime(hand.createdAt);

    return Dismissible(
      key: ValueKey(hand.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: Colors.red.shade800,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Hand'),
            content: Text('Are you sure you want to delete "$title"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        ref.read(handsDaoProvider).deleteHand(hand.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$title deleted')),
        );
      },
      child: Card(
        child: ListTile(
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: Text(
            dateStr,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade500,
                ),
          ),
          onTap: () => context.go('/trainer/replay/${hand.id}'),
        ),
      ),
    );
  }
}
