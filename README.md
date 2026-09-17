# RobotWars

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
> graphics. Still missing: the turn-event stream for phase 2 to consume,
> and a CLI/example runner.

```ruby
board = RobotWars::Board.new(width: 10, height: 10)
game = RobotWars::Game.start(board: board, robot_ids: %w[alpha bravo charlie delta])

until game.over?
  actions = game.alive_robots.to_h { |robot| [robot, your_strategy.decide(robot, game)] }
  game.play_turn(actions)
end

game.winner # => the last robot standing, or nil for a tie
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

More to come as the game engine takes shape.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then run
`bundle exec rake test` to run the tests. You can also run `bin/console` for an
interactive prompt that will allow you to experiment.

During cross-gem development the `Gemfile.local` points at the sibling
`../robot_lab` checkout (selected via the project-root `.envrc` / asgard).
Quality gates are run with `asgard quality`.

## License

The gem is available as open source under the terms of the
[MIT License](https://opensource.org/licenses/MIT).
