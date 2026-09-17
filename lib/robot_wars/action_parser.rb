module RobotWars
  # Parses a pilot's free-text reply into an Action, per the grammar a
  # warrior's brain is instructed to answer in:
  #
  #   STAY
  #   MOVE <north|northeast|east|southeast|south|southwest|west|northwest>
  #   ATTACK <x>,<y> <points>
  #   DEFEND <points>
  #
  # Anything that doesn't match becomes Action.invalid (RULES.md 21's
  # solo-conflict penalty, via TurnResolver) rather than raising — a
  # pilot's bad reply is a turn's mistake, not a crash.
  # :reek:RepeatedConditional -- each parse_* method guards its own independent regex match; they only share a name.
  class ActionParser
    DIRECTIONS = {
      "north" => Direction::NORTH, "northeast" => Direction::NORTHEAST,
      "east" => Direction::EAST, "southeast" => Direction::SOUTHEAST,
      "south" => Direction::SOUTH, "southwest" => Direction::SOUTHWEST,
      "west" => Direction::WEST, "northwest" => Direction::NORTHWEST
    }.freeze

    MOVE_PATTERN   = /\bMOVE\s+(\w+)/i
    ATTACK_PATTERN = /\bATTACK\s*\(?\s*(-?\d+)\s*,\s*(-?\d+)\s*\)?\s+(\d+)/i
    DEFEND_PATTERN = /\bDEFEND\s+(\d+)/i
    STAY_PATTERN   = /\bSTAY\b/i

    def parse(text)
      return Action.invalid if text.nil?

      parse_move(text) || parse_attack(text) || parse_defend(text) || parse_stay(text) || Action.invalid
    end

    private

    def parse_move(text)
      match = MOVE_PATTERN.match(text)
      return unless match

      direction = DIRECTIONS[match[1].downcase]
      direction && Action.move(direction)
    end

    def parse_attack(text)
      match = ATTACK_PATTERN.match(text)
      return unless match

      points = match[3].to_i
      return unless points.positive?

      square = Position.new(x: match[1].to_i, y: match[2].to_i)
      Action.attack(square: square, points: points)
    end

    def parse_defend(text)
      match = DEFEND_PATTERN.match(text)
      return unless match

      points = match[1].to_i
      points.positive? ? Action.defend(points: points) : nil
    end

    def parse_stay(text)
      Action.stay if STAY_PATTERN.match?(text)
    end
  end
end
