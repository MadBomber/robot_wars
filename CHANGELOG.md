# Changelog

## [Unreleased]

- Rule 47 (ruled by Dewayne): the board is a standard math plot —
  square (0,0) is the southwest corner, x grows east, y grows north,
  so `MOVE north` lands on (x, y+1). `Direction`'s y-axis flipped
  (N/S and the NE/SE, NW/SW diagonal pairs swapped offsets), the
  browser spectator now draws (0,0) at the bottom left with row
  labels counting up from the bottom (north still renders upward),
  and the pilots' rules recap (`game_rules.md`) states the
  convention explicitly — previously a pilot had no way to know
  which way y grew. The board's x-coordinate labels also moved from
  above the grid to below it, so both axes read off the origin
  corner like a standard plot.
- The announcer no longer slows the match: `Booth` runs the announcer
  on its own worker thread, so `--announcer` commentary (LLM call +
  speech) happens concurrently with the turns and the browser stream.
  Announcements never overlap (one serial worker) and stay in order;
  a booth that falls behind coalesces everything queued into one
  catch-up call so commentary tracks the live board instead of
  narrating history. A failing announcer is warned about and dropped
  rather than ending the match, and the finale is fully spoken before
  the process exits. The one exception to the concurrency: turn 1
  waits (`Booth#drain`) until the announcer has finished its
  introduction.
- The turn-event stream: `TurnResolver::Report#events` is the ordered,
  typed record of everything a turn did — declared actions, solo
  conflicts, conflicts, displacements, ranged effects, deaths, and
  territory claims — each event with a `#to_s` transcript line and a
  `#to_h` JSON shape. New event types `Declared`, `Displaced`, `Death`;
  `Claim` and ranged `Effect` learned to narrate and serialize, and
  `Effect` now carries the attacked square. `TurnNarrator` renders a
  report into the play-by-play lines used by BOTH the terminal
  transcript and the browser panel; the transcript now also announces
  displacements, counter-fire, unchallenged-defense premiums, and
  deaths — outcomes it previously kept silent — and HIT/MISS lines
  name the attacked square and damage.
- `--browser [PORT]` is now a LIVE spectator: one SSE update per
  resolved turn re-renders the board (robot icons with life numbers,
  territory shaded in the owner's color), the legend (fallen warriors
  keep a dimmed † row, colors stay roster-stable), the status line,
  and a scrolling play-by-play panel of the exact transcript lines.
  `SpectatorServer` grew a thread-per-connection `/events` SSE
  endpoint with latest-update replay for late joiners, and
  `SpectatorUpdate` builds each turn's idempotent JSON payload
  (fragments + full log + the turn's events) on the match thread —
  still no dependencies beyond the standard library. The final update
  closes the browser's stream, so the finished board stays on screen
  after the process exits.
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
