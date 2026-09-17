module RobotWars
  # Resolves an illegal move attempt (RULES.md 21): a solo conflict
  # against the board edge or a rival's owned square — a random hit,
  # no movement.
  class IllegalMoveResolver
    Result = Data.define(:robot, :roll)

    def initialize(roll_generator: RollGenerator.new)
      @roll_generator = roll_generator
    end

    def resolve(robot)
      roll = @roll_generator.roll
      robot.apply_damage(roll)
      Result.new(robot: robot, roll: roll)
    end
  end
end
