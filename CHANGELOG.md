# Changelog

## [Unreleased]

- `--browser [PORT]`: a browser spectator view of the match — the
  initial cut serves a frozen snapshot of the starting board (SVG
  grid, one colored robot icon per warrior, a color/life/square
  legend) from a stdlib-only HTTP server (`SpectatorServer`) on a
  background thread and opens it in the default browser
  (`BrowserOpener`: `open`/`start`/`xdg-open`). Rendering is split
  into `SvgBoard` (transparent-background SVG drawing) and
  `SpectatorPage` (dark-themed HTML that snapshots the game at
  construction, so serving never races the match loop).
- RULES.md gained rules 41 (unparsable pilot reply = rule 21 solo
  conflict) and 42 (Battleship-style HIT/MISS attack feedback),
  documenting behavior already implemented.
- `--seed` now really reproduces a match: `Game` derives its default
  conflict-roll generator from the same `random`, so seeded runs get
  identical rolls, not just identical placement.
- Rule 43: committing more attack/defense points than current life is
  an invalid action, punished as a solo conflict.
- Rule 44: an attack aimed off the board costs the attacker half the
  committed points (rounded up) and reports OFF THE BOARD to the
  attacker.
- Rule 46: dead robots take no further part in the turn — a dead loser
  never returns home, a dead winner conquers nothing, and a robot
  killed before the ranged phase neither fires nor counter-fires.
- Rule 18 amended: a returner whose origin square is now owned by a
  rival fights nobody — it retreats to a free neighbor (rule 19) or
  dies (rule 20).
- Rule 45 + `--timeout SECONDS` (default 60): a pilot that fails to
  answer in time is declared brain dead and its robot is removed from
  the match (`Game#remove_robot`) instead of hanging everyone.
- `--announcer [PROVIDER/MODEL]`: a radio play-by-play announcer in
  the booth — `Announcer` (an LLM persona with its own chat history
  for cross-turn continuity) narrates the lineup, every turn's recap,
  brain-dead removals, and the final result; `SaySpeaker` speaks each
  call aloud through the platform's text-to-speech (`say` on macOS,
  PowerShell's System.Speech on Windows, the first available of
  `spd-say`/`espeak-ng`/`espeak` on Linux — silent with a one-time
  warning when none is installed). The persona is an announcer brain
  template editable like any warrior's: the gem's shipped
  `examples/warriors/_announcer.md` by default (front matter picks
  `lms/openai/gpt-oss-20b` and temperature), or any file via
  `--announcer FILE` (parsed by the new `PromptTemplate`, since it
  can live outside the warriors directory).
- `--warriors` now defaults to the gem's shipped `examples/warriors`
  (the `examples/` directory ships with the gem), so a bare `rwars`
  runs the five example brains out of the box.

## [0.1.1] - 2026-09-17

- Phase 1 engine foundation: `Position`, `Direction`, `Board`,
  `RollGenerator`/`FixedRollGenerator`, `Robot`, `Action`,
  `OccupancyMap`, `Territory`, `MoveResolver`, `ConflictResolver`,
  `IllegalMoveResolver`, `RangedCombatResolver` — 100% line/branch
  coverage.
- Phase 1 turn orchestrator: `TurnResolver` (rule 40's full sequence,
  including cascading return conflicts and displacement-or-death) and
  `Game` (setup, `play_turn`, win/tie detection, `--life` starting-life
  override) — 100% line/branch coverage.
- LLM warrior layer: `ActionParser` (STAY/MOVE/ATTACK/DEFEND grammar,
  unparsable → `Action.invalid`), `SensingReport` (rule 33–35 report
  with HIT/MISS attack feedback), `Warrior`, `LLMPilot`, `ModelSpec`
  ("<provider>/<model id>" front-matter convention), and
  `GameRules` (the canonical rules recap shipped as
  `lib/robot_wars/game_rules.md`, handed to every robot as its system
  prompt).
- `rwars` CLI (`bin/rwars`, shipped as the gem executable): runs a
  match of LLM-backed warriors from a directory of RobotLab `*.md`
  prompt templates, with `--size/--width/--height`, `--life`,
  `--max-turns`, `--seed`, and `--model` override; pilots are prompted
  concurrently (one thread per warrior); per-turn transcript with
  action recap, conflicts, ownership claims, and HIT/MISS lines.
- Example warrior templates in `examples/warriors/` (warmonger,
  oppressor, sentinel, opportunist, wanderer) and a runnable
  random-action match in `examples/01_random_match.rb`.

## [0.1.0] - 2026-09-16

- Initial gem skeleton
