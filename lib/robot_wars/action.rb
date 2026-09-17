module RobotWars
  # A robot's single declared action for a turn (RULES.md 8: stay, move,
  # attack, or defend — exactly one).
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

    def stay? = type == :stay
    def move? = type == :move
    def attack? = type == :attack
    def defend? = type == :defend
  end
end
