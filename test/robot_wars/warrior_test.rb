require "test_helper"

class RobotWars::WarriorTest < Minitest::Test
  FakePilot = Struct.new(:action) do
    def decide(_report) = action
  end

  def test_id_delegates_to_the_robot
    robot = RobotWars::Robot.new(id: "alpha")
    warrior = RobotWars::Warrior.new(robot: robot, pilot: FakePilot.new(RobotWars::Action.stay))

    assert_equal "alpha", warrior.id
  end

  def test_decide_delegates_to_the_pilot
    action = RobotWars::Action.move(RobotWars::Direction::NORTH)
    warrior = RobotWars::Warrior.new(robot: RobotWars::Robot.new(id: "alpha"), pilot: FakePilot.new(action))

    assert_equal action, warrior.decide("some sensing report")
  end
end
