module RobotWars
  # The canonical rules-of-the-game recap, shipped with the gem
  # (lib/robot_wars/game_rules.md) so every warrior everywhere plays by
  # the same rules. bin/rwars hands it to each RobotLab robot as its
  # system_prompt — warrior templates carry only their model choice and
  # personality, never a rules retelling.
  module GameRules
    FILE = File.expand_path("game_rules.md", __dir__)

    def self.text = File.read(FILE)
  end
end
