module RobotWars
  # Resolves a square conflict (RULES.md 13-16): one shared roll damages
  # every robot present, and the highest remaining life wins the square.
  # A tie counts as a loss for everyone.
  class ConflictResolver
    Result = Data.define(:winner, :losers, :roll)

    def initialize(roll_generator: RollGenerator.new)
      @roll_generator = roll_generator
    end

    def resolve(robots)
      raise ArgumentError, "a conflict needs at least 2 robots" if robots.size < 2

      roll = @roll_generator.roll
      robots.each { |robot| robot.apply_damage(roll) }

      winner = winner_of(robots)
      losers = robots - Array(winner)

      Result.new(winner: winner, losers: losers, roll: roll)
    end

    private

    def winner_of(robots)
      highest_life = robots.map(&:life).max
      contenders = robots.select { |robot| robot.life == highest_life }
      contenders.one? ? contenders.first : nil
    end
  end
end
