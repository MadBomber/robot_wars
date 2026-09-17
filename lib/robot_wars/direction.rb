module RobotWars
  # The 8 one-square move directions (RULES.md 9: a robot moves like a
  # chess king).
  module Direction
    OFFSETS = [
      Position.new(x: 0, y: -1),
      Position.new(x: 1, y: -1),
      Position.new(x: 1, y: 0),
      Position.new(x: 1, y: 1),
      Position.new(x: 0, y: 1),
      Position.new(x: -1, y: 1),
      Position.new(x: -1, y: 0),
      Position.new(x: -1, y: -1)
    ].freeze

    NORTH, NORTHEAST, EAST, SOUTHEAST, SOUTH, SOUTHWEST, WEST, NORTHWEST = OFFSETS
  end
end
