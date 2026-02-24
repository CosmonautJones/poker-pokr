import 'package:flutter/material.dart';
import 'package:poker_trainer/features/trainer/domain/poker_glossary.dart';

/// Bottom sheet displaying the poker glossary grouped by category.
///
/// Call [PokerGlossarySheet.show] to present it.
class PokerGlossarySheet extends StatelessWidget {
  /// Optional term to highlight and auto-scroll to.
  final String? highlightTerm;

  const PokerGlossarySheet({super.key, this.highlightTerm});

  /// Show the glossary as a modal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    String? highlightTerm,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      builder: (_) => PokerGlossarySheet(highlightTerm: highlightTerm),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = PokerGlossary.categories;

    return Column(
      children: [
        // Drag handle
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade600,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.menu_book_rounded,
                  size: 20, color: Colors.amber.shade300),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Poker Glossary',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.of(context).pop(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Content
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: categories.length,
            itemBuilder: (context, catIndex) {
              final category = categories[catIndex];
              final entries = PokerGlossary.byCategory(category);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category header
                  Padding(
                    padding:
                        const EdgeInsets.fromLTRB(16, 16, 16, 6),
                    child: Text(
                      category,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _categoryColor(category),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  // Entries
                  ...entries.map((entry) {
                    final isHighlighted = highlightTerm != null &&
                        (entry.abbreviation.toLowerCase() ==
                                highlightTerm!.toLowerCase() ||
                            entry.term.toLowerCase() ==
                                highlightTerm!.toLowerCase());

                    return Container(
                      color: isHighlighted
                          ? Colors.amber.withValues(alpha: 0.1)
                          : null,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 60,
                            child: Text(
                              entry.abbreviation,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isHighlighted
                                    ? Colors.amber.shade200
                                    : Colors.white,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (entry.term != entry.abbreviation)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 2),
                                    child: Text(
                                      entry.term,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white.withValues(alpha: 0.85),
                                      ),
                                    ),
                                  ),
                                Text(
                                  entry.definition,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color:
                                        Colors.white.withValues(alpha: 0.6),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  static Color _categoryColor(String category) {
    return switch (category) {
      PokerGlossary.categoryPositions => Colors.blue.shade300,
      PokerGlossary.categoryBetting => Colors.amber.shade300,
      PokerGlossary.categoryConcepts => Colors.green.shade300,
      PokerGlossary.categoryHands => Colors.purple.shade300,
      PokerGlossary.categoryStreets => Colors.teal.shade300,
      _ => Colors.grey.shade300,
    };
  }
}
