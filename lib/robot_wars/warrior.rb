module RobotWars
  # Pairs a game-state Robot with whatever decides its actions each turn.
  # Game only ever needs the Action that comes out the other end, so the
  # pilot can be an LLMPilot, a scripted proc, or eventually a human —
  # anything answering #decide(report).
  class Warrior
    attr_reader :robot, :pilot

    def initialize(robot:, pilot:)
      @robot = robot
      @pilot = pilot
    end

    def id
      robot.id
    end

    def decide(report)
      pilot.decide(report)
    end
  end
end
