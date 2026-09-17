require "test_helper"

class RobotWars::IllegalMoveResolverTest < Minitest::Test
  def test_applies_the_roll_to_the_robot_and_returns_it
    resolver = RobotWars::IllegalMoveResolver.new(
      roll_generator: RobotWars::FixedRollGenerator.new([7])
    )
    robot = RobotWars::Robot.new(id: "r1")

    result = resolver.resolve(robot)

    assert_equal 93, robot.life
    assert_equal robot, result.robot
    assert_equal 7, result.roll
  end
end
