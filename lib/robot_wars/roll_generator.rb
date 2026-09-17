module RobotWars
  # The shared conflict roll (RULES.md 14 and 21): one random number,
  # 1 to 10.
  class RollGenerator
    RANGE = (1..10)

    def initialize(random: Random.new)
      @random = random
    end

    def roll
      @random.rand(RANGE)
    end
  end
end
