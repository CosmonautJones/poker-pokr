# TableSense

TableSense is a poker practice and session tracking app built with Flutter. Work through a simulated hand, undo a decision to explore another line, or keep a local record of your sessions. Practice chips are simulated; there are no online opponents, accounts, payments, or real-money play.

[Open the live web demo](https://cosmonautjones.github.io/poker-pokr/)

The demo is the last build published from `main`. Changes on a feature branch or draft pull request are not in the live app until merged and deployed.

## Try a hand

Choose **Quick Deal** on Home for six players, 1/2 blinds, and 200-chip starting stacks. You control each seat's decisions. Follow the highlighted player, choose an action, and continue through the board to showdown. **Undo** and **Redo** let you revisit decisions; **Deal Again** starts a fresh hand with fresh stacks.

Use **New Hand** for a custom setup, or **Lessons** for guided drawing-hand and hand-protection scenarios.

## Current features

- Custom hands with 2–9 seats, No-Limit Hold'em or Pot-Limit Omaha, configurable blinds, antes, stacks, dealer position, optional straddle, and selected or random hole cards.
- Manual actions, random auto-play, undo/redo, alternate branches, card editing, action history, saved hands, and reusable setups.
- Position explanations, pot odds, Monte Carlo equity estimates, outs practice, a glossary, and six scenarios across two lessons.
- Session records for buy-in, cash-out, duration, stakes, location, and notes, plus profit summaries and charts.
- Locally saved XP, levels, practice streaks, and haptic preferences.

## Run locally

Use a Flutter SDK whose bundled Dart satisfies `^3.11.0`, with Chrome available for web development. This polish pass used Flutter 3.41.2 / Dart 3.11.0. Dependencies and platform requirements are in [pubspec.yaml](pubspec.yaml).

From the repository root:

```sh
flutter pub get
dart compile js -O4 -o web/drift_worker.js web/drift_worker.dart
```

The web database also needs `web/sqlite3.wasm`. Download the version matching the locked `sqlite3` dependency (currently 2.9.4):

```sh
curl -L -o web/sqlite3.wasm https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-2.9.4/sqlite3.wasm
flutter run -d chrome
```

In Windows PowerShell, use `curl.exe` for the download command. The worker and Wasm file are generated/downloaded assets; neither is included in the source checkout. Keep their versions aligned with `pubspec.lock` when updating dependencies.

The stack uses Riverpod for state, GoRouter for navigation, Drift/SQLite for sessions and hands, SharedPreferences for progression, fl_chart for reports, and flutter_animate for transitions. The poker engine is pure Dart. Platform folders exist for mobile and desktop; their presence does not mean every target has been tested.

## Focused checks

```sh
flutter test test/poker/engine/street_progression_test.dart test/poker/engine/game_engine_test.dart test/poker/engine/straddle_test.dart test/poker/engine/pot_calculator_test.dart
```

These short checks cover turn order, street transitions, representative full hands, straddles, and side-pot construction. They do not certify every poker rule or every screen. For a specific source change, run `dart analyze <changed-file>` as well.

## Current limitations

- Data stays on the current device/browser. There is no account sync or implemented export/backup; clearing browser storage can remove saved records.
- Auto-play chooses random legal actions, not poker strategy. Equity and outs displays are learning estimates, not solver advice.
- Completed hands show winners and hand descriptions, but the engine does not credit pot winnings back into displayed stacks. Each new deal starts with the setup's original stacks.
- Older saved hands recorded when a betting option was incorrectly skipped can stop at the affected action during replay. The app reports the action number; this correction does not migrate those histories.
- Manual mobile verification of the already-live demo covered a six-seat Hold'em hand at 390 × 844. The unpublished patch has engine-test coverage; Omaha, all seat counts, native devices, and other viewport sizes still need hands-on coverage.

## Web publication

[deploy-web.yml](.github/workflows/deploy-web.yml) builds and publishes GitHub Pages on a push to `main` or a manual workflow dispatch. It compiles the database worker, downloads SQLite Wasm, and builds with `--base-href "/poker-pokr/"`. Feature-branch pushes and draft PRs do not trigger this workflow.
