module RobotWars
  # The 8 one-square move directions (RULES.md 9: a robot moves like a
  # chess king), on a standard math plot (RULES.md 47): (0,0) is the
  # southwest corner, x grows east, y grows NORTH — so north is +1 y.
  # :reek:TooManyConstants -- 8 compass points plus their two lookup tables; the compass isn't getting bigger.
  module Direction
    OFFSETS = [
      Position.new(x: 0, y: 1),
      Position.new(x: 1, y: 1),
      Position.new(x: 1, y: 0),
      Position.new(x: 1, y: -1),
      Position.new(x: 0, y: -1),
      Position.new(x: -1, y: -1),
      Position.new(x: -1, y: 0),
      Position.new(x: -1, y: 1)
    ].freeze

    NORTH, NORTHEAST, EAST, SOUTHEAST, SOUTH, SOUTHWEST, WEST, NORTHWEST = OFFSETS

    NAMES = {
      NORTH => "north", NORTHEAST => "northeast",
      EAST => "east", SOUTHEAST => "southeast",
      SOUTH => "south", SOUTHWEST => "southwest",
      WEST => "west", NORTHWEST => "northwest"
    }.freeze

    # The compass name of a direction offset, for showing a move to a
    # human ("north"), or nil for a position that isn't a direction.
    def self.name_of(offset) = NAMES[offset]
  end
end
