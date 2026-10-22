# Changelog

All notable changes to TableSense (poker-pokr) are recorded here. The format
follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the
project uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-10-21

First versioned release of the app running as the
[live web demo](https://cosmonautjones.github.io/poker-pokr/). The
`pubspec.yaml` version moves from the Flutter template default `1.0.0+1`
(never released) to `0.1.0+2`. The build number keeps going up.

### Added
- Poker trainer: hand engine, session bookkeeper, trainer UI and GitHub Pages
  deploy with drift web support. Includes an educational context strip and
  branching (undo/redo) through a hand.
- Hand setup: choose cards and stacks, random hole cards
  ([#1](https://github.com/CosmonautJones/poker-pokr/pull/1)), save setups for repeated practice
  ([#12](https://github.com/CosmonautJones/poker-pokr/pull/12)), and save mid-hand ([#11](https://github.com/CosmonautJones/poker-pokr/pull/11)).
- Contextual pro tips and a poker glossary ([#3](https://github.com/CosmonautJones/poker-pokr/pull/3)), a hand evaluator with
  correct winner determination ([#4](https://github.com/CosmonautJones/poker-pokr/pull/4)), and interactive lessons
  ([#11](https://github.com/CosmonautJones/poker-pokr/pull/11)).
- Straddle betting, the Omaha game type and an interactive table
  ([#8](https://github.com/CosmonautJones/poker-pokr/pull/8)). Also pot-limit betting for Omaha, a 4-color deck and
  side-by-side hole cards ([#10](https://github.com/CosmonautJones/poker-pokr/pull/10)).
- Auto-play mode and editing cards mid-hand ([#20](https://github.com/CosmonautJones/poker-pokr/pull/20)), a real-time Monte
  Carlo equity calculator ([#20](https://github.com/CosmonautJones/poker-pokr/pull/20)), outs training and an auto-play button
  ([#30](https://github.com/CosmonautJones/poker-pokr/pull/30)).
- Better daily use: Deal Again, a dashboard and collapsible equity
  ([#23](https://github.com/CosmonautJones/poker-pokr/pull/23)).
- Progression: haptics, a daily streak with XP and levels, a lesson-complete
  celebration, and Settings controls for haptics and resetting progression
  ([#33](https://github.com/CosmonautJones/poker-pokr/pull/33)).
- Test suites for domain logic and providers ([#6](https://github.com/CosmonautJones/poker-pokr/pull/6)), lesson screens
  ([#17](https://github.com/CosmonautJones/poker-pokr/pull/17)) and audit fixes ([#19](https://github.com/CosmonautJones/poker-pokr/pull/19)).

### Changed
- Mobile-first layout across screens ([#2](https://github.com/CosmonautJones/poker-pokr/pull/2)). Ten shows as "10" instead of
  "T", plus theme tokens and larger touch targets ([#5](https://github.com/CosmonautJones/poker-pokr/pull/5)).
- Table and UI polish: animations and decluttering ([#7](https://github.com/CosmonautJones/poker-pokr/pull/7)), a premium
  table with a gold theme and 3D cards ([#9](https://github.com/CosmonautJones/poker-pokr/pull/9)), and flutter_animate
  effects ([#13](https://github.com/CosmonautJones/poker-pokr/pull/13)). Also a tighter layout and compact controls
  ([#22](https://github.com/CosmonautJones/poker-pokr/pull/22)), plus tabular figures, consistent icons and centralized theme
  colors ([#31](https://github.com/CosmonautJones/poker-pokr/pull/31)).
- Brand refresh to **TableSense**, with matching PWA theme colors and an iOS
  fullscreen status bar ([#26](https://github.com/CosmonautJones/poker-pokr/pull/26), [#27](https://github.com/CosmonautJones/poker-pokr/pull/27)).
- README describes the real app, its features, the demo and its limitations
  ([#51](https://github.com/CosmonautJones/poker-pokr/pull/51)).

### Fixed
- The big blind's preflop option is no longer skipped after a fold or an exact
  all-in call. The hand-complete actions wrap inside the card on mobile
  ([#51](https://github.com/CosmonautJones/poker-pokr/pull/51)).
- Betting: the turn no longer auto-calls ([#11](https://github.com/CosmonautJones/poker-pokr/pull/11)), the playersYetToAct
  bug is fixed ([#18](https://github.com/CosmonautJones/poker-pokr/pull/18)), a pot-limit all-in is fixed ([#30](https://github.com/CosmonautJones/poker-pokr/pull/30)), and
  multi-way tie equity is fixed ([#31](https://github.com/CosmonautJones/poker-pokr/pull/31)).
- Fixed 38 audit findings across the engine, data and presentation layers,
  including data-loss and error-handling bugs ([#10](https://github.com/CosmonautJones/poker-pokr/pull/10), [#18](https://github.com/CosmonautJones/poker-pokr/pull/18),
  [#19](https://github.com/CosmonautJones/poker-pokr/pull/19)).
- Layout: seat overlap, landscape layout and animation performance
  ([#21](https://github.com/CosmonautJones/poker-pokr/pull/21), [#32](https://github.com/CosmonautJones/poker-pokr/pull/32)), PREFLOP badge clipping ([#29](https://github.com/CosmonautJones/poker-pokr/pull/29)), and
  hand-replay spacing in the fullscreen PWA ([#28](https://github.com/CosmonautJones/poker-pokr/pull/28)).
- Web build and compile failures ([#16](https://github.com/CosmonautJones/poker-pokr/pull/16), [#24](https://github.com/CosmonautJones/poker-pokr/pull/24), [#25](https://github.com/CosmonautJones/poker-pokr/pull/25)),
  a missing test import ([#14](https://github.com/CosmonautJones/poker-pokr/pull/14)) and sparkle particle jitter
  ([#15](https://github.com/CosmonautJones/poker-pokr/pull/15)).

### Known limitations
- Winning stacks are not settled after showdown. Older saved histories that
  relied on the skipped big-blind option can stop at the mismatched action
  ([#51](https://github.com/CosmonautJones/poker-pokr/pull/51)).

[Unreleased]: https://github.com/CosmonautJones/poker-pokr/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/CosmonautJones/poker-pokr/releases/tag/v0.1.0
