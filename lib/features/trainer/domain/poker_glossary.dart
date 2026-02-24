/// Poker glossary — definitions for common poker terms and acronyms.
///
/// Pure Dart - no Flutter imports.
library;

class GlossaryEntry {
  final String term;
  final String abbreviation;
  final String definition;
  final String category;

  const GlossaryEntry({
    required this.term,
    required this.abbreviation,
    required this.definition,
    required this.category,
  });
}

class PokerGlossary {
  PokerGlossary._();

  // -----------------------------------------------------------------------
  // Categories
  // -----------------------------------------------------------------------

  static const categoryPositions = 'Positions';
  static const categoryBetting = 'Betting';
  static const categoryConcepts = 'Concepts';
  static const categoryHands = 'Hands & Cards';
  static const categoryStreets = 'Streets';

  // -----------------------------------------------------------------------
  // All entries
  // -----------------------------------------------------------------------

  static const List<GlossaryEntry> entries = [
    // Positions
    GlossaryEntry(
      term: 'Button',
      abbreviation: 'BTN',
      definition:
          'The dealer position. Acts last post-flop, giving the biggest informational advantage.',
      category: categoryPositions,
    ),
    GlossaryEntry(
      term: 'Small Blind',
      abbreviation: 'SB',
      definition:
          'Seat directly left of the button. Posts the small forced bet before cards are dealt.',
      category: categoryPositions,
    ),
    GlossaryEntry(
      term: 'Big Blind',
      abbreviation: 'BB',
      definition:
          'Seat two left of the button. Posts the larger forced bet. Also used as a unit of measurement for stack sizes.',
      category: categoryPositions,
    ),
    GlossaryEntry(
      term: 'Under the Gun',
      abbreviation: 'UTG',
      definition:
          'First to act preflop, directly left of the big blind. The tightest opening range is recommended here.',
      category: categoryPositions,
    ),
    GlossaryEntry(
      term: 'Under the Gun +1',
      abbreviation: 'UTG+1',
      definition:
          'Second earliest position. Still a tight opening range, but slightly wider than UTG.',
      category: categoryPositions,
    ),
    GlossaryEntry(
      term: 'Under the Gun +2',
      abbreviation: 'UTG+2',
      definition: 'Third earliest position at a full table.',
      category: categoryPositions,
    ),
    GlossaryEntry(
      term: 'Middle Position',
      abbreviation: 'MP',
      definition:
          'Seats in the middle of the table order. Moderate opening ranges.',
      category: categoryPositions,
    ),
    GlossaryEntry(
      term: 'Lojack',
      abbreviation: 'LJ',
      definition:
          'Three seats right of the button. The transition from middle to late position.',
      category: categoryPositions,
    ),
    GlossaryEntry(
      term: 'Hijack',
      abbreviation: 'HJ',
      definition:
          'Two seats right of the button. Late-middle position with a wider opening range.',
      category: categoryPositions,
    ),
    GlossaryEntry(
      term: 'Cutoff',
      abbreviation: 'CO',
      definition:
          'Seat directly right of the button. Second-best position, can open a wide range.',
      category: categoryPositions,
    ),

    // Betting — basic actions
    GlossaryEntry(
      term: 'Fold',
      abbreviation: 'Fold',
      definition:
          'Surrender your hand and forfeit any chips already in the pot. You cannot win the hand after folding.',
      category: categoryBetting,
    ),
    GlossaryEntry(
      term: 'Check',
      abbreviation: 'Check',
      definition:
          'Pass the action without betting when no bet is facing you. You stay in the hand at no additional cost.',
      category: categoryBetting,
    ),
    GlossaryEntry(
      term: 'Bet',
      abbreviation: 'Bet',
      definition:
          'Place the first wager on a street when no one has bet yet. Minimum bet is one big blind.',
      category: categoryBetting,
    ),
    GlossaryEntry(
      term: 'Call',
      abbreviation: 'Call',
      definition:
          'Match the current bet to stay in the hand. Does not increase the bet amount.',
      category: categoryBetting,
    ),
    GlossaryEntry(
      term: 'Raise',
      abbreviation: 'Raise',
      definition:
          'Increase the current bet. The minimum raise size equals the previous raise amount. Other players must respond to the new bet.',
      category: categoryBetting,
    ),

    // Betting — advanced
    GlossaryEntry(
      term: 'Pot Odds',
      abbreviation: 'Pot Odds',
      definition:
          'The ratio of the current pot to the cost of a call. Expressed as X:1 or a percentage. If your equity exceeds the pot odds percentage, calling is profitable.',
      category: categoryBetting,
    ),
    GlossaryEntry(
      term: 'Continuation Bet',
      abbreviation: 'C-Bet',
      definition:
          'A bet made by the preflop aggressor on the flop. Common strategy to maintain initiative.',
      category: categoryBetting,
    ),
    GlossaryEntry(
      term: 'Three-Bet',
      abbreviation: '3-Bet',
      definition:
          'A re-raise over an opening raise. The third bet in a sequence: blind, raise, re-raise.',
      category: categoryBetting,
    ),
    GlossaryEntry(
      term: 'Four-Bet',
      abbreviation: '4-Bet',
      definition:
          'A raise over a 3-bet. Typically signals a very strong hand or a bluff.',
      category: categoryBetting,
    ),
    GlossaryEntry(
      term: 'All-In',
      abbreviation: 'All-In',
      definition:
          'Betting all remaining chips. Cannot be forced to fold once all-in.',
      category: categoryBetting,
    ),
    GlossaryEntry(
      term: 'Check-Raise',
      abbreviation: 'X/R',
      definition:
          'Checking with the intent to raise after an opponent bets. A strong aggressive play.',
      category: categoryBetting,
    ),
    GlossaryEntry(
      term: 'Donk Bet',
      abbreviation: 'Donk',
      definition:
          'Betting into the preflop aggressor out of position on a new street. Once considered bad, now used strategically.',
      category: categoryBetting,
    ),
    GlossaryEntry(
      term: 'Overbet',
      abbreviation: 'Overbet',
      definition:
          'A bet larger than the pot. Used to polarize your range or maximize value.',
      category: categoryBetting,
    ),

    // Concepts
    GlossaryEntry(
      term: 'Stack-to-Pot Ratio',
      abbreviation: 'SPR',
      definition:
          'Effective stack divided by the pot. Low SPR (<4) favors committing with top pair+. High SPR (>10) favors speculative hands and set mining.',
      category: categoryConcepts,
    ),
    GlossaryEntry(
      term: 'Expected Value',
      abbreviation: 'EV',
      definition:
          'The average amount you expect to win or lose over many repetitions of the same decision.',
      category: categoryConcepts,
    ),
    GlossaryEntry(
      term: 'Equity',
      abbreviation: 'Equity',
      definition:
          'Your share of the pot based on the probability of winning. 50% equity in a 100 pot = 50 expected.',
      category: categoryConcepts,
    ),
    GlossaryEntry(
      term: 'Implied Odds',
      abbreviation: 'Implied',
      definition:
          'Pot odds adjusted for expected future bets. Drawing hands with good implied odds can call despite bad immediate pot odds.',
      category: categoryConcepts,
    ),
    GlossaryEntry(
      term: 'Position',
      abbreviation: 'Position',
      definition:
          'Your seat relative to the dealer button. Acting later gives more information and is a major advantage.',
      category: categoryConcepts,
    ),
    GlossaryEntry(
      term: 'Range',
      abbreviation: 'Range',
      definition:
          'The set of all possible hands a player could hold in a given situation.',
      category: categoryConcepts,
    ),
    GlossaryEntry(
      term: 'Outs',
      abbreviation: 'Outs',
      definition:
          'The number of unseen cards that complete your draw. Multiply outs by 2 on the turn (or 4 on the flop) for a rough equity percentage.',
      category: categoryConcepts,
    ),
    GlossaryEntry(
      term: 'Fold Equity',
      abbreviation: 'Fold Equity',
      definition:
          'The extra value gained when opponents fold to your bet. A bluff is profitable when your fold equity plus pot equity exceed the bet cost.',
      category: categoryConcepts,
    ),
    GlossaryEntry(
      term: 'In Position',
      abbreviation: 'IP',
      definition:
          'Acting after your opponent. A major strategic advantage.',
      category: categoryConcepts,
    ),
    GlossaryEntry(
      term: 'Out of Position',
      abbreviation: 'OOP',
      definition:
          'Acting before your opponent. A strategic disadvantage requiring tighter play.',
      category: categoryConcepts,
    ),

    // Hands & Cards
    GlossaryEntry(
      term: 'Pocket Pair',
      abbreviation: 'PP',
      definition: 'Two hole cards of the same rank, e.g. pocket kings (KK).',
      category: categoryHands,
    ),
    GlossaryEntry(
      term: 'Suited',
      abbreviation: 's',
      definition:
          'Hole cards of the same suit, e.g. AKs. Adds ~3% equity vs offsuit.',
      category: categoryHands,
    ),
    GlossaryEntry(
      term: 'Offsuit',
      abbreviation: 'o',
      definition: 'Hole cards of different suits, e.g. AKo.',
      category: categoryHands,
    ),
    GlossaryEntry(
      term: 'Connectors',
      abbreviation: 'Conn',
      definition:
          'Hole cards of consecutive ranks, e.g. 9T. Suited connectors (9Ts) can make straights and flushes.',
      category: categoryHands,
    ),
    GlossaryEntry(
      term: 'Top Pair',
      abbreviation: 'TP',
      definition:
          'Pairing with the highest card on the board using one of your hole cards.',
      category: categoryHands,
    ),
    GlossaryEntry(
      term: 'Set / Trips',
      abbreviation: 'Set',
      definition:
          'Three of a kind. A "set" is when you hold a pocket pair that matches a board card; "trips" is when you use one hole card with a board pair.',
      category: categoryHands,
    ),

    // Streets
    GlossaryEntry(
      term: 'Preflop',
      abbreviation: 'Preflop',
      definition:
          'The first betting round, after hole cards are dealt but before any community cards.',
      category: categoryStreets,
    ),
    GlossaryEntry(
      term: 'Flop',
      abbreviation: 'Flop',
      definition:
          'The first three community cards dealt face up, followed by the second betting round.',
      category: categoryStreets,
    ),
    GlossaryEntry(
      term: 'Turn',
      abbreviation: 'Turn',
      definition:
          'The fourth community card, followed by the third betting round.',
      category: categoryStreets,
    ),
    GlossaryEntry(
      term: 'River',
      abbreviation: 'River',
      definition:
          'The fifth and final community card, followed by the last betting round.',
      category: categoryStreets,
    ),
    GlossaryEntry(
      term: 'Showdown',
      abbreviation: 'Showdown',
      definition:
          'When remaining players reveal their hands to determine the winner after all betting is complete.',
      category: categoryStreets,
    ),
  ];

  // -----------------------------------------------------------------------
  // Lookup helpers
  // -----------------------------------------------------------------------

  /// Lookup a term by its abbreviation (case-insensitive).
  static GlossaryEntry? lookup(String abbreviation) {
    final lower = abbreviation.toLowerCase();
    for (final entry in entries) {
      if (entry.abbreviation.toLowerCase() == lower) return entry;
    }
    return null;
  }

  /// All unique categories in display order.
  static List<String> get categories => const [
        categoryPositions,
        categoryBetting,
        categoryConcepts,
        categoryHands,
        categoryStreets,
      ];

  /// Entries filtered by category.
  static List<GlossaryEntry> byCategory(String category) {
    return entries.where((e) => e.category == category).toList();
  }
}
