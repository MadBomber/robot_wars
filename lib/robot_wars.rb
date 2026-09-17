require "robot_lab"

require_relative "robot_wars/version"
require_relative "robot_wars/position"
require_relative "robot_wars/direction"
require_relative "robot_wars/board"
require_relative "robot_wars/roll_generator"
require_relative "robot_wars/fixed_roll_generator"
require_relative "robot_wars/robot"
require_relative "robot_wars/action"
require_relative "robot_wars/occupancy_map"
require_relative "robot_wars/territory"
require_relative "robot_wars/move_resolver"
require_relative "robot_wars/conflict_resolver"
require_relative "robot_wars/illegal_move_resolver"
require_relative "robot_wars/ranged_combat_resolver"
require_relative "robot_wars/turn_resolver"
require_relative "robot_wars/game"
require_relative "robot_wars/action_parser"
require_relative "robot_wars/model_spec"
require_relative "robot_wars/prompt_template"
require_relative "robot_wars/game_rules"
require_relative "robot_wars/sensing_report"
require_relative "robot_wars/warrior"
require_relative "robot_wars/llm_pilot"
require_relative "robot_wars/say_speaker"
require_relative "robot_wars/announcer"

module RobotWars
  # Raised for RobotWars-specific misuse.
  class Error < StandardError; end
end
