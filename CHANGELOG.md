# Changelog

## [Unreleased]

- Phase 1 engine foundation: `Position`, `Direction`, `Board`,
  `RollGenerator`/`FixedRollGenerator`, `Robot`, `Action`,
  `OccupancyMap`, `Territory`, `MoveResolver`, `ConflictResolver`,
  `IllegalMoveResolver`, `RangedCombatResolver` — 100% line/branch
  coverage.
- Phase 1 turn orchestrator: `TurnResolver` (rule 40's full sequence,
  including cascading return conflicts and displacement-or-death) and
  `Game` (setup, `play_turn`, win/tie detection) — 100% line/branch
  coverage.

## [0.1.0] - 2026-09-16

- Initial gem skeleton
