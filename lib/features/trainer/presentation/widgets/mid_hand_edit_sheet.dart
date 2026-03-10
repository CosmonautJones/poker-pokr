import 'package:flutter/material.dart';
import 'package:poker_trainer/core/theme/poker_theme.dart';
import 'package:poker_trainer/features/trainer/presentation/widgets/card_picker.dart';
import 'package:poker_trainer/poker/engine/card_conflict_checker.dart';
import 'package:poker_trainer/poker/models/card.dart';
import 'package:poker_trainer/poker/models/game_state.dart';
import 'package:poker_trainer/poker/models/street.dart';

/// Result returned from the edit sheet.
sealed class EditResult {}

class HoleCardEdit extends EditResult {
  final int playerIndex;
  final List<PokerCard> newCards;
  HoleCardEdit({required this.playerIndex, required this.newCards});
}

class CommunityCardEdit extends EditResult {
  final List<PokerCard> newCommunityCards;
  CommunityCardEdit({required this.newCommunityCards});
}

/// Bottom sheet for editing hole cards and community cards mid-hand.
class MidHandEditSheet extends StatefulWidget {
  final GameState gameState;

  /// If non-null, start on the hole cards tab with this player selected.
  final int? initialPlayerIndex;

  const MidHandEditSheet({
    super.key,
    required this.gameState,
    this.initialPlayerIndex,
  });

  /// Show the edit sheet and return an [EditResult] or null if cancelled.
  static Future<EditResult?> show(
    BuildContext context, {
    required GameState gameState,
    int? initialPlayerIndex,
  }) {
    return showModalBottomSheet<EditResult>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      builder: (_) => MidHandEditSheet(
        gameState: gameState,
        initialPlayerIndex: initialPlayerIndex,
      ),
    );
  }

  @override
  State<MidHandEditSheet> createState() => _MidHandEditSheetState();
}

class _MidHandEditSheetState extends State<MidHandEditSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialPlayerIndex != null ? 0 : 0,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;

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
        // Title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Icon(Icons.edit_rounded, size: 18, color: pt.accent),
              const SizedBox(width: 8),
              const Text(
                'Edit Cards',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
        // Tab bar
        TabBar(
          controller: _tabController,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Hole Cards'),
            Tab(text: 'Community Cards'),
          ],
        ),
        // Tab views
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _HoleCardsTab(
                gameState: widget.gameState,
                initialPlayerIndex: widget.initialPlayerIndex,
              ),
              _CommunityCardsTab(gameState: widget.gameState),
            ],
          ),
        ),
      ],
    );
  }
}

/// Tab for editing player hole cards.
class _HoleCardsTab extends StatelessWidget {
  final GameState gameState;
  final int? initialPlayerIndex;

  const _HoleCardsTab({required this.gameState, this.initialPlayerIndex});

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: gameState.players.length,
      itemBuilder: (context, index) {
        final player = gameState.players[index];
        final unavailable = CardConflictChecker.usedCardValues(
          gameState,
          excludePlayerIndex: index,
        );

        return ListTile(
          leading: CircleAvatar(
            radius: 16,
            backgroundColor: player.isFolded
                ? pt.badgeFold.withValues(alpha: 0.3)
                : pt.seatBackground,
            child: Text(
              '${index + 1}',
              style: TextStyle(
                fontSize: 12,
                color: player.isFolded ? pt.textMuted : Colors.white,
              ),
            ),
          ),
          title: Text(
            player.name,
            style: TextStyle(
              fontSize: 14,
              color: player.isFolded ? pt.textMuted : null,
              decoration: player.isFolded ? TextDecoration.lineThrough : null,
            ),
          ),
          subtitle: Text(
            player.holeCards.map((c) => c.toString()).join(' '),
            style: TextStyle(
              fontSize: 13,
              fontFamily: 'monospace',
              color: pt.textMuted,
            ),
          ),
          trailing: Icon(Icons.edit, size: 18, color: pt.accent),
          onTap: () => _editPlayerCards(context, index, player.holeCards, unavailable),
        );
      },
    );
  }

  Future<void> _editPlayerCards(
    BuildContext context,
    int playerIndex,
    List<PokerCard> currentCards,
    Set<int> unavailable,
  ) async {
    final newCards = List<PokerCard>.of(currentCards);
    var changed = false;

    for (int i = 0; i < currentCards.length; i++) {
      // Build unavailable set excluding the card we're editing.
      final excluded = Set<int>.of(unavailable);
      for (int j = 0; j < newCards.length; j++) {
        if (j != i) excluded.add(newCards[j].value);
      }

      final picked = await CardPickerBottomSheet.show(
        context,
        unavailableCardValues: excluded,
        initialCard: newCards[i],
      );

      if (picked != null && picked != newCards[i]) {
        newCards[i] = picked;
        changed = true;
      }
    }

    if (changed && context.mounted) {
      Navigator.of(context).pop(HoleCardEdit(
        playerIndex: playerIndex,
        newCards: newCards,
      ));
    }
  }
}

/// Tab for editing community cards.
class _CommunityCardsTab extends StatelessWidget {
  final GameState gameState;

  const _CommunityCardsTab({required this.gameState});

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final community = gameState.communityCards;
    final hasCommunity = community.isNotEmpty;

    // All cards in use (all hole cards + current community).
    final allUsed = CardConflictChecker.usedCardValues(gameState);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!hasCommunity)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'No community cards dealt yet.\n'
                'Community cards will appear here after the flop.',
                style: TextStyle(color: pt.textMuted, fontSize: 13),
              ),
            ),
          if (hasCommunity) ...[
            Text(
              _streetLabel(community.length),
              style: TextStyle(
                color: pt.accent,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(community.length, (i) {
                return _CommunityCardSlot(
                  card: community[i],
                  onTap: () => _editCommunityCard(
                    context,
                    i,
                    community,
                    allUsed,
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }

  String _streetLabel(int count) {
    if (count >= 5) return 'River';
    if (count >= 4) return 'Turn';
    if (count >= 3) return 'Flop';
    return 'Pre-flop';
  }

  Future<void> _editCommunityCard(
    BuildContext context,
    int cardIndex,
    List<PokerCard> community,
    Set<int> allUsed,
  ) async {
    // Exclude everything except the card being edited.
    final excluded = Set<int>.of(allUsed);
    excluded.remove(community[cardIndex].value);

    final picked = await CardPickerBottomSheet.show(
      context,
      unavailableCardValues: excluded,
      initialCard: community[cardIndex],
    );

    if (picked != null && picked != community[cardIndex] && context.mounted) {
      final newCommunity = List<PokerCard>.of(community);
      newCommunity[cardIndex] = picked;
      Navigator.of(context).pop(CommunityCardEdit(
        newCommunityCards: newCommunity,
      ));
    }
  }
}

class _CommunityCardSlot extends StatelessWidget {
  final PokerCard card;
  final VoidCallback onTap;

  const _CommunityCardSlot({required this.card, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final suitColor = (card.suit == Suit.hearts || card.suit == Suit.diamonds)
        ? pt.suitRed
        : pt.suitBlack;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 64,
        decoration: BoxDecoration(
          color: pt.cardFace,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: pt.accent.withValues(alpha: 0.5), width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 2,
              offset: Offset(1, 1),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              card.rank.symbol,
              style: TextStyle(
                color: suitColor,
                fontSize: 17,
                fontWeight: FontWeight.bold,
                height: 1,
              ),
            ),
            Text(
              card.suit.symbol,
              style: TextStyle(
                color: suitColor,
                fontSize: 15,
                height: 1,
              ),
            ),
            const SizedBox(height: 2),
            Icon(Icons.edit, size: 10, color: pt.accent.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }
}
