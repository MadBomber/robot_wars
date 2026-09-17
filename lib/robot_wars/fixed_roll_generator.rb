module RobotWars
  # A queued, deterministic roll source for tests and seeded replays.
  class FixedRollGenerator
    Exhausted = Class.new(StandardError)

    def initialize(rolls)
      @rolls = rolls.dup
    end

    def roll
      raise Exhausted, "no more fixed rolls queued" if @rolls.empty?

      @rolls.shift
    end
  end
end
