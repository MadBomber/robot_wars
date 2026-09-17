#!/usr/bin/env ruby
# A full RobotWars match with random actions, printed turn by turn.
#
# There is no GUI yet (phase 2) — this exercises the headless engine
# end to end and gives something to watch while developing it.
#
#   ruby examples/01_random_match.rb [seed]
#   ./examples/01_random_match.rb [seed]
#
# Works from any current directory: BUNDLE_GEMFILE (relative, e.g. from
# the project's .envrc) is resolved against this repo's root, not cwd.
repo_root = File.expand_path("..", __dir__)
ENV["BUNDLE_GEMFILE"] = File.expand_path(ENV["BUNDLE_GEMFILE"] || "Gemfile.local", repo_root)

require "bundler/setup"
require "robot_wars"

# Turn lines should land as they're printed, even into a pipe or file.
$stdout.sync = true

BOARD      = RobotWars::Board.new(width: 8, height: 8)
ROBOT_IDS  = %w[alpha bravo charlie delta].freeze

def random_action(robot, board, random)
  case random.rand(4)
  when 0 then RobotWars::Action.stay
  when 1 then RobotWars::Action.move(RobotWars::Direction::OFFSETS.sample(random: random))
  when 2 then RobotWars::Action.attack(square: board.random_position(random: random), points: [1, robot.life].max)
  else RobotWars::Action.defend(points: [1, robot.life].max)
  end
end

seed   = (ARGV.first || Random.new_seed).to_i
random = Random.new(seed)
game   = RobotWars::Game.start(board: BOARD, robot_ids: ROBOT_IDS, random: random)

puts <<~HEADER
  RobotWars — #{ROBOT_IDS.size} robots on a #{BOARD.width}x#{BOARD.height} board
  seed: #{seed}
HEADER

until game.over?
  actions = game.alive_robots.to_h { |robot| [robot, random_action(robot, BOARD, random)] }
  report = game.play_turn(actions)

  status = game.alive_robots.map { |robot| "#{robot.id}=#{robot.life}" }.join(", ")
  puts "turn #{game.turn_number}: #{status}"
  report.deaths.each { |robot| puts "  #{robot.id} died" }
end

puts "---"
if game.tie?
  puts "Tie — the last robots fell in the same turn."
else
  puts "Winner: #{game.winner.id} (#{game.winner.life} life) after #{game.turn_number} turns."
end
