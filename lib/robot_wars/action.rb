module RobotWars
  # A robot's single declared action for a turn (RULES.md 8: stay, move,
  # attack, or defend — exactly one). `invalid` is not a rule 8 choice —
  # it's what a pilot (e.g. an LLM reply that fails to parse) hands the
  # engine when it produced nothing usable; TurnResolver treats it the
  # same as an illegal move (rule 21's solo-conflict penalty).
  Action = Data.define(:type, :direction, :square, :points) do
    def self.stay
      new(type: :stay, direction: nil, square: nil, points: nil)
    end

    def self.move(direction)
      new(type: :move, direction: direction, square: nil, points: nil)
    end

    def self.attack(square:, points:)
      raise ArgumentError, "points must be positive" unless points.positive?

      new(type: :attack, direction: nil, square: square, points: points)
    end

    def self.defend(points:)
      raise ArgumentError, "points must be positive" unless points.positive?

      new(type: :defend, direction: nil, square: nil, points: points)
    end

    def self.invalid
      new(type: :invalid, direction: nil, square: nil, points: nil)
    end

    def stay? = type == :stay
    def move? = type == :move
    def attack? = type == :attack
    def defend? = type == :defend
    def invalid? = type == :invalid

    # Render the action in the same one-line grammar pilots reply in
    # (see ActionParser), so a match transcript reads like the commands
    # the warriors gave.
    def to_s
      case type
      when :stay   then "STAY"
      when :move   then "MOVE #{Direction.name_of(direction)}"
      when :attack then "ATTACK #{square.x},#{square.y} #{points}"
      when :defend then "DEFEND #{points}"
      else              "INVALID"
      end
    end

    # Like to_s, but anchored to the board: where the robot stood for
    # STAY, where it was headed for MOVE. `origin` is the robot's square
    # when it declared the action — the intended MOVE destination is
    # origin + direction, which resolution may still deny (conflict
    # loss, board edge, owned square).
    def describe(origin)
      case type
      when :stay then "STAY at (#{origin.x},#{origin.y})"
      when :move
        destination = origin + direction
        "MOVE #{Direction.name_of(direction)} to (#{destination.x},#{destination.y})"
      else to_s
      end
    end
  end
end
