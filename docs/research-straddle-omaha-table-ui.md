# Research: Straddle Betting, Omaha Support, and Table UI

## Current State of the Codebase

The app is a **Flutter/Dart poker trainer** using Riverpod for state management, Drift for persistence, and go_router for navigation. It currently supports:

- **Texas Hold'em only** — 2 hole cards per player, best-5-from-7 evaluation
- **Blinds** — Small blind and big blind with correct positional logic (heads-up and multi-way)
- **Ante** — Per-player ante already implemented
- **2-9 players** at a table
- **Poker table widget** — Oval felt table with player seats positioned around an ellipse
- **Hand creation screen** — Players can set names, stacks, and pick individual hole cards
- **Full game engine** — fold, check, call, bet, raise, all-in with legal action validation
- **Hand evaluator** — Ranks 5-card hands, picks best-5-from-7, supports showdown

### Key Files Involved

| Area | File | Current Role |
|------|------|-------------|
| Game state | `lib/poker/models/game_state.dart` | Holds blinds, ante, pot, players, community cards. **No straddle field.** |
| Player state | `lib/poker/models/player.dart` | Name, stack, hole cards (2), bet amounts. **No game-type-dependent card count.** |
| Game engine | `lib/poker/engine/game_engine.dart` | Creates initial state, posts blinds/antes, deals 2 hole cards. **No straddle logic.** |
| Hand evaluator | `lib/poker/engine/hand_evaluator.dart` | `evaluateBestHand(holeCards, community)` — combines all cards and picks best 5 from any combination. **No Omaha "must use exactly 2" constraint.** |
| Hand setup | `lib/features/trainer/domain/hand_setup.dart` | Config for new hands. **No game type or straddle fields.** |
| Create screen | `lib/features/trainer/presentation/screens/create_hand_screen.dart` | Form with player count, blinds, ante, dealer, per-player names/stacks/cards. **No straddle toggle, no game type selector.** |
| Table widget | `lib/features/trainer/presentation/widgets/poker_table_widget.dart` | Oval table with seats around ellipse, community cards, pot display. **Already has a table-like visual.** |
| Player seat | `lib/features/trainer/presentation/widgets/player_seat.dart` | Shows name, stack, hole cards, status badges. |
| Hole card selector | `lib/features/trainer/presentation/widgets/hole_card_selector.dart` | Two card slots per player. **Hardcoded to 2 slots.** |

---

## Feature 1: Straddle Betting

### What Is a Straddle?

A straddle is a **voluntary blind bet** made before cards are dealt, typically by the UTG (under-the-gun) player. It effectively creates a third blind that increases the stakes.

### Straddle Rules

- **Standard size**: Usually 2x the big blind (e.g., $4 straddle in a $1/$2 game)
- **Stakeholder request**: 5x the big blind to "boost the pot and take away position"
- **Position**: The straddler gets **last action preflop** (before the flop), overriding normal position
- **Timing**: Must be placed before cards are dealt
- **Effect on action**: Preflop action starts to the **left of the straddler**, and the straddler closes the action

### Types of Straddles (for future consideration)

| Type | Who Can Post | Common In |
|------|-------------|-----------|
| **UTG Straddle** | Player to the left of BB | Most casinos |
| **Mississippi Straddle** | Any player | Southern US, home games |
| **Button Straddle** | Player on the button | Some casinos |
| **Double/Re-Straddle** | Player left of UTG straddle | High-action games |

### What Needs to Change

#### 1. `HandSetup` — Add straddle configuration
```dart
class HandSetup {
  // ... existing fields ...
  final bool straddleEnabled;
  final double straddleMultiplier; // e.g., 2.0 (standard) or 5.0 (stakeholder request)
  final int? straddlePlayerIndex; // null = auto (UTG), or specific seat
}
```

#### 2. `GameState` — Track straddle state
```dart
class GameState {
  // ... existing fields ...
  final double straddle;          // 0 if no straddle
  final int? straddlePlayerIndex; // who posted it
}
```

#### 3. `GameEngine.createInitialState()` — Post the straddle
After posting SB and BB, if straddle is enabled:
- The UTG player (seat after BB) posts the straddle amount
- Deduct from their stack, add to pot
- Set `currentBet` to the straddle amount (not BB)
- **First to act preflop** shifts to the player **left of the straddler**
- **Straddler acts last** preflop (like the BB normally does)

```
Positions (6-player, dealer = seat 0):
  Seat 0: Dealer
  Seat 1: Small Blind ($1)
  Seat 2: Big Blind ($2)
  Seat 3: UTG — posts straddle ($10 at 5x BB)
  Seat 4: First to act preflop
  Seat 5: Acts second
  ...
  Seat 3: Straddler acts LAST preflop
```

#### 4. `LegalActionSet` — Adjust min-raise calculations
- When a straddle is active, the `currentBet` is the straddle amount, not BB
- Min raise should be based on straddle size
- The straddler can "check" or raise when action returns to them (like BB in an unstraddled hand)

#### 5. `CreateHandScreen` — Add straddle toggle
- Add a toggle/switch for "Enable Straddle"
- Show straddle amount (either fixed multiplier or custom)
- Optionally show which player will straddle (default: UTG)

### Estimated Complexity: **Medium**
- Engine changes are localized to `createInitialState()` and first-to-act logic
- Legal action computation needs minor adjustments for the new `currentBet`
- The straddler's "option" (to check or raise when action returns) follows existing BB logic

---

## Feature 2: Omaha (PLO) Support

### Key Differences from Texas Hold'em

| Aspect | Texas Hold'em | Omaha |
|--------|--------------|-------|
| Hole cards | 2 | **4** |
| Hand construction | Any combination of hole + community | **Must use exactly 2 hole cards + exactly 3 community cards** |
| Starting hand combos | 1,326 | **270,725** |
| Betting structure | Usually No-Limit | Usually **Pot-Limit** |
| Typical hand strength | Two pair is often good | Need straights/flushes to win |
| Starting combos from 4 cards | n/a | **6 different 2-card sub-hands** |

### What Needs to Change

#### 1. Add a `GameType` enum
```dart
enum GameType {
  texasHoldem,  // 2 hole cards, any combination
  omaha,        // 4 hole cards, must use exactly 2
}
```

#### 2. `HandSetup` — Add game type
```dart
class HandSetup {
  // ... existing fields ...
  final GameType gameType;
}
```

#### 3. `GameEngine.createInitialState()` — Deal correct number of cards
```dart
final cardsPerPlayer = setup.gameType == GameType.omaha ? 4 : 2;
final hand = holeCards != null ? holeCards[i] : deck.dealMany(cardsPerPlayer);
```

#### 4. `HandEvaluator` — Omaha evaluation (the big change)

The current evaluator (`evaluateBestHand`) combines all 7 cards and picks the best 5 from **any** combination. This is correct for Hold'em but **wrong for Omaha**.

For Omaha, we need:
```dart
static EvaluatedHand evaluateBestHandOmaha(
  List<PokerCard> holeCards,    // exactly 4
  List<PokerCard> communityCards, // exactly 5 (at showdown)
) {
  // Must use exactly 2 from hole cards + exactly 3 from community
  // Try all C(4,2) * C(5,3) = 6 * 10 = 60 combinations
  EvaluatedHand? best;
  for (final holePair in combinations(holeCards, 2)) {
    for (final communityTriple in combinations(communityCards, 3)) {
      final hand = evaluate5([...holePair, ...communityTriple]);
      if (best == null || hand > best) best = hand;
    }
  }
  return best!;
}
```

This is the **critical difference** — the `_combinations` helper already exists in the evaluator, so this is straightforward to implement.

#### 5. `HoleCardSelector` — Support 4 card slots for Omaha
Currently hardcoded to 2 slots. Needs to dynamically show 2 or 4 based on game type.

#### 6. `PlayerSeat` widget — Display 4 hole cards
The seat widget iterates over `player.holeCards` already, so showing 4 cards should work with minor layout adjustments (might need to shrink card size or stack them).

#### 7. `CreateHandScreen` — Add game type selector
A toggle or dropdown at the top: "Texas Hold'em" / "Omaha"

#### 8. Pot-Limit Betting (optional but recommended for Omaha)
Omaha is traditionally pot-limit. The `LegalActionSet` would need a pot-limit max calculation:
```
Max raise = current pot + (amount to call) + (amount to call again)
```
This could be added as a `BettingStructure` enum: `noLimit`, `potLimit`, `fixedLimit`.

### Estimated Complexity: **Medium-High**
- The hand evaluator change is the most critical and nuanced piece
- Card dealing and display are straightforward
- Pot-limit betting is a nice-to-have but adds complexity

---

## Feature 3: Table-View UI for Assigning Hands

### Current State
The app **already has** a poker table widget (`PokerTableWidget`) that displays:
- An oval felt table with a gradient and border
- Player seats positioned around an ellipse
- Community cards in the center
- Pot display
- Dealer button indicator

However, this widget is **read-only during the hand replay** — players can't interact with it to assign cards.

The card assignment currently happens in the **Create Hand Screen** as a flat list form, not on the table.

### What the Stakeholder Wants
A **visual table UI** where you can **tap on a player seat to select/assign their hand**. Instead of the current flat form, the user would see the table and tap seats to configure them.

### Implementation Approach

#### Option A: Table-Based Hand Setup (Recommended)
Replace or supplement the create-hand form with an interactive table view:

1. **Reuse `PokerTableWidget`** layout but make seats tappable
2. **Tap a seat** → opens a bottom sheet or overlay to:
   - Edit player name
   - Set stack amount
   - Pick hole cards (using existing `CardPickerBottomSheet`)
3. **Visual feedback** — seats that have cards assigned show them; empty seats show placeholders
4. **Center of table** — show game settings (blinds, straddle toggle, game type)

```
┌──────────────────────────────────────┐
│          [Seat 4]  [Seat 5]          │
│    [Seat 3]                [Seat 6]  │
│                                      │
│              BB: $2                   │
│         Straddle: $10                │
│         Game: Omaha                  │
│                                      │
│    [Seat 2]                [Seat 7]  │
│          [Seat 1]  [Hero]            │
│                                      │
│         [ Start Hand ]               │
└──────────────────────────────────────┘
```

#### What Needs to Change

1. **New `InteractiveTableSetup` widget** — wraps the table ellipse layout with `GestureDetector` on each seat
2. **Seat tap handler** — opens `PlayerConfigSheet` (bottom sheet) with name, stack, hole card picker
3. **Table center** — displays game configuration (blinds, ante, straddle, game type) with edit capability
4. **Navigation** — either replace `CreateHandScreen` or add a "Table View" toggle
5. **State** — reuse existing `HandSetupProvider` for all the data; the UI just changes from form to visual

#### Complexity: **Medium**
- Most of the visual components already exist (table layout, card picker, stack picker)
- Main work is making the table interactive and wiring up the config bottom sheets
- The `_computeSeatPositions` ellipse math is already done

---

## Implementation Priority Recommendation

| Priority | Feature | Reason |
|----------|---------|--------|
| 1 | **Straddle betting** | Most localized change; engine + UI toggle |
| 2 | **Game type selector** (Hold'em / Omaha) | Moderate scope; evaluator is the critical piece |
| 3 | **Interactive table UI** | Largest visual overhaul but builds on existing components |

### Suggested Order of Work

1. **Add `GameType` enum and straddle fields** to `HandSetup` and `GameState`
2. **Update `GameEngine.createInitialState()`** for straddle posting and action order
3. **Update `HandEvaluator`** with `evaluateBestHandOmaha()` using the 2+3 rule
4. **Update card dealing** to deal 4 cards for Omaha
5. **Update `CreateHandScreen`** with game type dropdown and straddle toggle
6. **Update `HoleCardSelector`** for dynamic 2/4 card slots
7. **Build interactive table setup** widget on top of existing `PokerTableWidget`
8. **Add pot-limit betting** option (optional, for Omaha authenticity)

---

## Sources

### Straddle Rules
- [WinStar: Poker Straddle Explained](https://www.winstar.com/blog/poker-straddle-explained-what-it-is-and-how-it-works/)
- [Upswing Poker: What is a Straddle?](https://upswingpoker.com/what-is-a-straddle/)
- [PokerNews: Explaining the Straddle](https://www.pokernews.com/strategy/explaining-the-straddle-it-s-not-as-obscene-as-it-sounds-19317.htm)
- [PokerCoaching: All About Straddles](https://pokercoaching.com/blog/poker-straddles/)
- [GTO Wizard: Preflop Strategy in Straddled Pots](https://blog.gtowizard.com/preflop-strategy-in-straddled-pots/)

### Omaha vs Hold'em
- [TightPoker: Texas Hold'em vs Omaha](https://www.tightpoker.com/the-difference-between-texas-holdem-and-omaha/)
- [WinStar: Difference Between Hold'em and Omaha](https://www.winstar.com/blog/difference-between-texas-holdem-and-omaha/)
- [CardPlayer: Texas Hold'em vs Omaha](https://www.cardplayer.com/rules-of-poker/texas-holdem-vs-omaha)
- [PokerNews: How to Play Omaha](https://www.pokernews.com/poker-rules/omaha-poker.htm)

### Table UI References
- [sergij14/poker-table: React + Framer Motion poker table](https://github.com/sergij14/poker-table)
- [infocular/responsive-poker-table: CSS poker table layout](https://github.com/infocular/responsive-poker-table)
- [CodePen: Poker Table CSS Layout](https://codepen.io/y0n1/pen/bzerPy)
