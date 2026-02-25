# Implementation Plan: Straddle, Omaha, and Interactive Table UI

## Phase 1: Core Model Changes (Foundation)

These changes touch shared data models and must land first since everything else depends on them.

### Step 1.1: Add `GameType` enum
**File:** `lib/poker/models/game_type.dart` (new)
```dart
enum GameType {
  texasHoldem,  // 2 hole cards, best 5 from any combination
  omaha,        // 4 hole cards, must use exactly 2 hole + 3 community
}
```
- `holeCardCount` getter: returns 2 for Hold'em, 4 for Omaha
- `displayName` getter: "Texas Hold'em" / "Omaha"

### Step 1.2: Add straddle + gameType fields to `HandSetup`
**File:** `lib/features/trainer/domain/hand_setup.dart`
- Add `GameType gameType` (default: `texasHoldem`)
- Add `bool straddleEnabled` (default: `false`)
- Add `double straddleMultiplier` (default: `2.0`, stakeholder wants 5.0 option)
- Update `copyWith()`, `HandSetup.defaults()` factory
- These are setup-time config, not runtime state

### Step 1.3: Add straddle + gameType fields to `GameState`
**File:** `lib/poker/models/game_state.dart`
- Add `double straddle` (default: `0` = no straddle)
- Add `int? straddlePlayerIndex` (who posted it)
- Add `GameType gameType` (default: `texasHoldem`)
- Update `copyWith()` and constructor

### Step 1.4: Update `HandSetupNotifier` provider
**File:** `lib/features/trainer/providers/hand_setup_provider.dart`
- Add `setGameType(GameType)` method
- Add `setStraddleEnabled(bool)`, `setStraddleMultiplier(double)` methods
- Update `dealRandomHoleCards()` to deal `gameType.holeCardCount` cards instead of hardcoded 2
- Update `setPlayerHoleCard()` to support card indices 0-3 for Omaha

---

## Phase 2: Engine Changes (Straddle + Omaha Dealing)

### Step 2.1: Update `GameEngine.createInitialState()` for straddle
**File:** `lib/poker/engine/game_engine.dart`
- Add params: `double straddle`, `int? straddlePlayerIndex`, `GameType gameType`
- After posting SB/BB, if `straddle > 0`:
  - Determine straddle player (default: UTG = seat after BB for multi-way)
  - For heads-up with straddle: NOT supported (straddles are 3+ player only); skip if `isHeadsUp`
  - Post straddle: deduct from stack, add to pot, set `currentBet` and `currentBet` to straddle amount
  - Set `lastRaiseSize` to straddle amount (for min-raise calc)
  - Shift `firstToAct` to the player AFTER the straddler
  - The straddler will get last action preflop (the action wraps around to them)
- Store `straddle` and `straddlePlayerIndex` in the returned `GameState`

**Position logic with straddle (6-player, dealer=0):**
```
Seat 0: Dealer (BTN)
Seat 1: SB ($1)
Seat 2: BB ($2)
Seat 3: Straddle ($10 at 5x) — acts LAST preflop
Seat 4: First to act preflop
Seat 5: Second to act
Seat 0: Third (BTN)
Seat 1: Fourth (SB)
Seat 2: Fifth (BB)
Seat 3: Sixth — LAST (straddler's "option")
```

### Step 2.2: Update card dealing for Omaha
**File:** `lib/poker/engine/game_engine.dart`
- Change `deck.dealMany(2)` → `deck.dealMany(gameType.holeCardCount)`
- When pre-assigned `holeCards` are provided, validate length matches game type

### Step 2.3: Update `LegalActionSet` (minor)
**File:** `lib/poker/engine/legal_actions.dart`
- No changes needed to the computation — it already uses `state.currentBet` and `state.lastRaiseSize`, which will be set correctly by the straddle posting logic
- The straddler's "option" (check or raise) works automatically because when action reaches them, their `currentBet` == `state.currentBet` (the straddle), so `toCall == 0` → can check or raise
- Confirm via tests

### Step 2.4: Update `StreetProgression`
**File:** `lib/poker/engine/street_progression.dart`
- `isBettingRoundComplete()` — no changes needed; it checks `playersActedThisStreet >= activeNonAllInPlayers.length`, which handles the straddle case naturally since the straddler has to act too
- Verify the straddler is counted correctly via tests

---

## Phase 3: Hand Evaluator — Omaha Support

### Step 3.1: Add `evaluateBestHandOmaha()` to `HandEvaluator`
**File:** `lib/poker/engine/hand_evaluator.dart`
- New public static method:
```dart
static EvaluatedHand evaluateBestHandOmaha(
  List<PokerCard> holeCards,     // exactly 4
  List<PokerCard> communityCards, // 3-5
) {
  assert(holeCards.length == 4);
  // Must use exactly 2 from hole + exactly 3 from community
  // C(4,2) * C(min(5,community.length), 3) combinations
  EvaluatedHand? best;
  for (final holePair in _combinations(holeCards, 2)) {
    for (final communityTriple in _combinations(communityCards, 3)) {
      final hand = evaluate5([...holePair, ...communityTriple]);
      if (best == null || hand > best) best = hand;
    }
  }
  return best!;
}
```
- Make `_combinations` public (or add a public wrapper) since it's now used by two methods

### Step 3.2: Add a game-type-aware dispatch method
**File:** `lib/poker/engine/hand_evaluator.dart`
- New method:
```dart
static EvaluatedHand evaluateBest(
  List<PokerCard> holeCards,
  List<PokerCard> communityCards,
  GameType gameType,
) {
  return gameType == GameType.omaha
      ? evaluateBestHandOmaha(holeCards, communityCards)
      : evaluateBestHand(holeCards, communityCards);
}
```

### Step 3.3: Update `_completeHand()` and `determineWinners()` to be game-type-aware
**File:** `lib/poker/engine/game_engine.dart`
- `_completeHand()` calls `HandEvaluator.evaluateBestHand()` — change to `HandEvaluator.evaluateBest(holeCards, community, state.gameType)`
- `determineWinners()` also needs the game type passed through
- Add `GameType gameType` param to `HandEvaluator.determineWinners()` and `showdown()`

---

## Phase 4: Database Schema Updates

### Step 4.1: Add columns to `Hands` table
**File:** `lib/features/trainer/data/tables/hands_table.dart`
- Add `IntColumn get gameType => integer().withDefault(const Constant(0))();` (0=Hold'em, 1=Omaha)
- Add `RealColumn get straddle => real().withDefault(const Constant(0.0))();`

### Step 4.2: Bump schema version + migration
**File:** `lib/core/database/app_database.dart`
- Bump `schemaVersion` to `2`
- Add migration for v1→v2: `ALTER TABLE hands ADD COLUMN game_type INTEGER NOT NULL DEFAULT 0; ALTER TABLE hands ADD COLUMN straddle REAL NOT NULL DEFAULT 0.0;`

### Step 4.3: Update `HandMapper`
**File:** `lib/features/trainer/data/mappers/hand_mapper.dart`
- `handToSetup()` — map `hand.gameType` → `GameType.values[hand.gameType]`, map `hand.straddle`
- `setupToCompanion()` — include `gameType` and `straddle` in companion
- `gameStateToCompanion()` — same

### Step 4.4: Regenerate Drift code
- Run `dart run build_runner build` to regenerate `app_database.g.dart`, `hands_dao.g.dart`

---

## Phase 5: Provider / Replay Updates

### Step 5.1: Update `HandReplayNotifier.build()`
**File:** `lib/features/trainer/providers/hand_replay_provider.dart`
- Pass `gameType`, `straddle`, and `straddleMultiplier` through to `GameEngine.createInitialState()`
- Update the hole-card resolution logic: deal `gameType.holeCardCount` cards instead of hardcoded 2
- When checking `allAssigned`, verify `h.length == gameType.holeCardCount`

### Step 5.2: Update `EducationalContextCalculator`
**File:** `lib/features/trainer/domain/educational_context.dart`
- Update `_positionLabel()` — when straddle is active, the straddler position should show "STR" badge or "UTG (Straddle)"
- The position map might need adjustment if the straddle shifts perceived positions

---

## Phase 6: UI Changes — Create Hand Screen

### Step 6.1: Add Game Type selector to `CreateHandScreen`
**File:** `lib/features/trainer/presentation/screens/create_hand_screen.dart`
- Add a `SegmentedButton` or `ToggleButtons` at the top: **Texas Hold'em** | **Omaha**
- Wired to `notifier.setGameType()`
- When switching game types, clear existing hole cards (different card count)

### Step 6.2: Add Straddle toggle to `CreateHandScreen`
**File:** `lib/features/trainer/presentation/screens/create_hand_screen.dart`
- Below the Blinds & Ante row, add a `SwitchListTile`: "Straddle"
- When enabled, show a `TextFormField` or `DropdownButton` for multiplier (2x, 3x, 5x, custom)
- Display the computed straddle amount: e.g. "Straddle: $10 (5x BB)"
- Only show when `playerCount >= 3` (straddles don't apply heads-up)

### Step 6.3: Update `HoleCardSelector` for 4 cards
**File:** `lib/features/trainer/presentation/widgets/hole_card_selector.dart`
- Add `int cardCount` param (default: 2)
- Dynamically render `cardCount` `_CardSlot` widgets instead of hardcoded 2
- Update callbacks: instead of `onCard1Selected`/`onCard2Selected`, use `ValueChanged<(int, PokerCard)> onCardSelected` and `ValueChanged<int> onCardCleared`
- Or simpler: keep individual callbacks but add `onCard3Selected`, `onCard4Selected`, etc.
- **Recommended approach:** Refactor to take a list-based API:
  - `int cardCount`
  - `void Function(int cardIndex, PokerCard card) onCardSelected`
  - `void Function(int cardIndex) onCardCleared`

### Step 6.4: Update `CreateHandScreen` to pass cardCount to `HoleCardSelector`
- Pass `setup.gameType.holeCardCount` as `cardCount`
- Wire up the generic callbacks

---

## Phase 7: UI Changes — Table Widget + Player Seats

### Step 7.1: Update `PlayerSeat` to display 4 cards for Omaha
**File:** `lib/features/trainer/presentation/widgets/player_seat.dart`
- Already iterates `player.holeCards` — so 4 cards will render automatically
- Adjust sizing: when > 2 cards, shrink card width slightly or use 2x2 grid layout
- Add a "STR" badge similar to "D" dealer chip when `isStraddler` is true

### Step 7.2: Update `PokerTableWidget` to pass straddle info
**File:** `lib/features/trainer/presentation/widgets/poker_table_widget.dart`
- Pass `isStraddler: i == gameState.straddlePlayerIndex` to `PlayerSeat`

### Step 7.3: Build `InteractiveTableSetup` widget (new)
**File:** `lib/features/trainer/presentation/widgets/interactive_table_setup.dart` (new)
- Reuses the ellipse seat layout from `PokerTableWidget._computeSeatPositions()`
- Each seat is wrapped in `GestureDetector` → on tap, opens `PlayerConfigBottomSheet`
- Center of table shows: game type, blinds, ante, straddle toggle
- Bottom: "Start Hand" button
- Reads from and writes to `handSetupProvider`

### Step 7.4: Build `PlayerConfigBottomSheet` (new)
**File:** `lib/features/trainer/presentation/widgets/player_config_sheet.dart` (new)
- Shows: player name field, stack field (with stack picker), hole card selector
- Uses existing `CardPickerBottomSheet` and `StackPickerBottomSheet`
- Returns updated values to the caller

### Step 7.5: Integrate into navigation
**File:** `lib/features/trainer/presentation/screens/create_hand_screen.dart`
- Add a toggle between "List View" (current form) and "Table View" (interactive table)
- Or replace the current form entirely with the table view
- **Recommended:** Add an icon button in the AppBar to toggle views, keeping both options

---

## Phase 8: Tests

### Step 8.1: Engine tests — Straddle
**File:** `test/poker/engine/game_engine_test.dart`
- Test: 6-player with straddle posts correct amounts (SB=1, BB=2, STR=10)
- Test: pot = SB + BB + straddle after initial state
- Test: `currentBet` = straddle amount
- Test: first to act is player after straddler
- Test: straddler gets option (check/raise) when action wraps back
- Test: straddle player's stack reduced correctly
- Test: no straddle in heads-up (silently ignored)
- Test: straddle player all-in if stack < straddle amount

### Step 8.2: Evaluator tests — Omaha
**File:** `test/poker/engine/hand_evaluator_test.dart`
- Test: Omaha evaluator must use exactly 2 hole cards (player has 4 hearts on board with Ah in hand but only 1 heart hole card → NOT a flush)
- Test: Omaha evaluator must use exactly 3 community cards
- Test: Omaha vs Hold'em same cards, different results (verify the constraint matters)
- Test: Best hand selection across C(4,2)*C(5,3)=60 combinations
- Test: Omaha with < 5 community cards (flop: C(4,2)*C(3,3)=6 combos)

### Step 8.3: Integration tests
- Test: Full hand with straddle — deal through showdown
- Test: Full Omaha hand — deal 4 cards, evaluate at showdown
- Test: `HandSetup` → `GameEngine` → `HandReplayNotifier` round-trip for both game types

### Step 8.4: Provider tests
**File:** `test/features/trainer/providers/hand_setup_provider_test.dart`
- Test: `setGameType()` updates state
- Test: `setStraddleEnabled()` / `setStraddleMultiplier()` updates state
- Test: `dealRandomHoleCards()` deals correct count per game type

---

## File Change Summary

| File | Change Type |
|------|------------|
| `lib/poker/models/game_type.dart` | **NEW** |
| `lib/poker/models/game_state.dart` | Modified — add straddle + gameType fields |
| `lib/features/trainer/domain/hand_setup.dart` | Modified — add straddle + gameType fields |
| `lib/poker/engine/game_engine.dart` | Modified — straddle posting, Omaha dealing, game-type-aware eval |
| `lib/poker/engine/hand_evaluator.dart` | Modified — add `evaluateBestHandOmaha()`, `evaluateBest()` |
| `lib/poker/engine/legal_actions.dart` | Verify only (likely no changes needed) |
| `lib/poker/engine/street_progression.dart` | Verify only (likely no changes needed) |
| `lib/features/trainer/providers/hand_setup_provider.dart` | Modified — new setters |
| `lib/features/trainer/providers/hand_replay_provider.dart` | Modified — pass through new fields |
| `lib/features/trainer/domain/educational_context.dart` | Modified — straddle position label |
| `lib/features/trainer/presentation/screens/create_hand_screen.dart` | Modified — game type + straddle UI |
| `lib/features/trainer/presentation/widgets/hole_card_selector.dart` | Modified — dynamic card count |
| `lib/features/trainer/presentation/widgets/player_seat.dart` | Modified — 4-card layout, straddle badge |
| `lib/features/trainer/presentation/widgets/poker_table_widget.dart` | Modified — pass straddle info |
| `lib/features/trainer/presentation/widgets/interactive_table_setup.dart` | **NEW** |
| `lib/features/trainer/presentation/widgets/player_config_sheet.dart` | **NEW** |
| `lib/features/trainer/data/tables/hands_table.dart` | Modified — new columns |
| `lib/features/trainer/data/mappers/hand_mapper.dart` | Modified — map new fields |
| `lib/core/database/app_database.dart` | Modified — schema v2 + migration |
| `lib/core/database/app_database.g.dart` | Regenerated |
| `test/poker/engine/game_engine_test.dart` | Modified — straddle tests |
| `test/poker/engine/hand_evaluator_test.dart` | Modified — Omaha tests |
| `test/features/trainer/providers/hand_setup_provider_test.dart` | Modified — new setter tests |

---

## Execution Order

1. **Phase 1** (models) → 2. **Phase 2** (engine) → 3. **Phase 3** (evaluator) → run tests
4. **Phase 4** (database) → regenerate → 5. **Phase 5** (providers)
6. **Phase 6** (create screen UI) → 7. **Phase 7** (table UI) → 8. **Phase 8** (tests)

Each phase can be committed independently. Phases 1-3 are the core logic. Phases 4-5 wire it through the data layer. Phases 6-7 are pure UI. Phase 8 validates everything.
