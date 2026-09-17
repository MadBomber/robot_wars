# RobotWars

> **Note:** This gem is still in development. It is waiting on the
> release of some of its dependencies before it can be published.

RobotWars is a component of the [RobotLab](https://github.com/MadBomber/robot_lab)
multi-robot LLM orchestration project: a turn-based game in which RobotLab
robots compete on a 2D grid board until only one remains.

![RobotWars game board](docs/game_board.svg)

## Game Concept

A turn-based, last-robot-standing game. Robots move on a bounded grid,
fight for squares, claim territory by conquest or occupation, shell each
other blind from across the board, and die at 0 life points — or by
having nowhere left to stand.

The complete numbered rule set lives in **[RULES.md](RULES.md)**; the
design discussion behind each rule is logged in `notes.md`.

> **Status:** phase 1 (headless engine) has a working core. `RobotWars::Game`
> runs full matches turn by turn — movement, the life-point economy,
> square conflicts (including cascading returns and displacement-or-death),
> ranged combat, death processing, and territory — end to end, with no
> graphics. The `rwars` CLI and an example runner exist (below). Still
> missing: the structured turn-event stream for phase 2 (the browser
> spectator view) to consume.

```ruby
board = RobotWars::Board.new(width: 10, height: 10)
game = RobotWars::Game.start(board: board, robot_ids: %w[alpha bravo charlie delta])

until game.over?
  actions = game.alive_robots.to_h { |robot| [robot, your_strategy.decide(robot, game)] }
  game.play_turn(actions)
end

game.winner # => the last robot standing, or nil for a tie
```

See `examples/01_random_match.rb` for a runnable match (random actions,
printed turn by turn) — `bundle exec ruby examples/01_random_match.rb`.

## The `rwars` CLI — LLM-backed warriors

`rwars` runs a real match with each warrior's actions decided by an LLM,
built from a human-authored prompt file (RobotLab's `.md` template
format: YAML front matter + a personality body). One file per warrior;
the filename (minus `.md`) becomes that warrior's id (files starting
with `_` are never warriors: shared partials, or the shipped
`_announcer.md` announcer brain). A warrior file
carries only its model choice and personality — the rules of the game
are the gem's job: `RobotWars::GameRules` (shipped as
`lib/robot_wars/game_rules.md`) is handed to every robot as its system
prompt, so all warriors everywhere play by the same canonical rules.

Each warrior's `.md` front matter picks its own brain via the `model:`
field, written as `<provider>/<model id>` — the RubyLLM provider name,
a slash, then the model id as that provider knows it (e.g.
`apfel/apple-foundationmodel`, `ollama/llama3`). Pass
`--model PROVIDER/MODEL` to force every warrior onto the same one
regardless of what its template says. Nothing is hardcoded: providers
that ship outside ruby_llm (as `ruby_llm-providers-<name>` gems) are
required on demand, and a template that names no model falls through to
RobotLab's config cascade.

Most of the example warriors in `examples/warriors/` pick **Apfel** —
Apple's on-device Foundation Model, served locally by the `apfel` CLI.
No API key, no cloud calls, no per-token cost:

```bash
brew install apfel   # once, per machine
apfel --serve        # start the local server (127.0.0.1:11434)

bin/rwars            # examples/warriors is the default roster
```

The gem ships its `examples/` directory, so `--warriors` defaults to
the installed gem's `examples/warriors`; point it at your own
directory to field your own roster.

Apfel requires an Apple Silicon Mac on macOS 26+ with Apple
Intelligence enabled. See the
[`ruby_llm-providers-apfel`](https://apfel.franzai.com/) gem for
details.

Each turn, a warrior is sent a sensing report (RULES.md 33-35: its own
position and life, and the full map of owned squares — never another
robot's position) and must reply with exactly one line:

```
STAY
MOVE <north|northeast|east|southeast|south|southwest|west|northwest>
ATTACK <x>,<y> <points>
DEFEND <points>
```

A reply that doesn't parse — or one that commits more points than the
warrior's current life — is treated as an illegal-move-style penalty
(RULES.md 21, 41, 43) rather than crashing the match, and a pilot that
fails to reply within the time limit is declared brain dead and removed
from the match entirely (RULES.md 45). Run `bin/rwars --help` for all
options, including `--seed` for a reproducible match, `--timeout` for
the brain-dead limit, and `--max-turns` as a safety valve against
stalemates.

Pass `--announcer` to put a radio play-by-play announcer in the booth:
an LLM persona that narrates the lineup, every turn's recap, and the
final result — and speaks each call aloud through the platform's
text-to-speech (`say` on macOS, PowerShell's System.Speech on Windows,
`spd-say`/`espeak-ng`/`espeak` on Linux). Its brain is a template
editable exactly like a warrior's: the gem's
shipped `examples/warriors/_announcer.md` by default (front matter
picks `lms/openai/gpt-oss-20b`), or your own file anywhere via
`--announcer path/to/my_announcer.md`. The match and the booth run
as a broadcast pipeline: turn 1 waits for the opening call, and from
then on the robots play turn N+1 while the announcer is calling
turn N. Each turn's story lands on every channel at once — the
terminal transcript, the browser update, and the start of the
announcer's call — so what you see always matches what you hear,
commentary never trails by more than one turn, and every turn gets
its own call.

Pass `--browser` to watch the match live in a web browser: a
spectator page served from a background thread (no extra
dependencies) and opened in your default browser. Every resolved turn
streams an update over Server-Sent Events — warriors move across the
board wearing their life points, owned squares are shaded in their
owner's color, the legend tracks life and position (the fallen keep a
dimmed row), and a play-by-play panel scrolls the same lines the
terminal prints. This is the referee's God view: it shows everything
the warriors' own rule-33 sensing hides. When the match ends the
final board stays on screen. Bare `--browser` picks a free port;
`--browser PORT` fixes it.

`examples/warriors/` has five ready-made brains with distinct
personalities — a fight between them exercises very different play
styles:

| Warrior | Strategy |
|---|---|
| `warmonger.md` | Relentlessly aggressive; attacks almost every turn |
| `oppressor.md` | Warmonger's clone on a different brain (`lms/openai/gpt-oss-20b`) — shows per-warrior model choice in action |
| `sentinel.md` | Patient turtle; claims territory by occupation, rarely fights |
| `opportunist.md` | Reactive and adaptive; picks its spots, varies its play |
| `wanderer.md` | Pure expansionist; claims empty ground, avoids conflict entirely |

```bash
bin/rwars --size 10x10 --announcer   # default roster, spoken play-by-play
```

## Installation

Add the gem to your application's Gemfile:

```bash
bundle add robot_wars
```

Or install it directly:

```bash
gem install robot_wars
```

## Usage

```ruby
require "robot_wars"
```

Drive the headless engine directly (see the Game Concept snippet above
and `examples/01_random_match.rb`), or run a full LLM-piloted match with
`bin/rwars`. The complete rules are in [RULES.md](RULES.md).

## Development

After checking out the repo, run `bundle install` to install
dependencies, then `bundle exec rake test` to run the tests.

During cross-gem development the `Gemfile.local` points at the sibling
`../robot_lab` checkout (selected via the project-root `.envrc` / asgard).
Quality gates are run with `asgard quality`.

## License

The gem is available as open source under the terms of the
[MIT License](https://opensource.org/licenses/MIT).
