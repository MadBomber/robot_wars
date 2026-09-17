require "test_helper"

class RobotWars::RobotTest < Minitest::Test
  def test_starts_with_100_life_by_default
    assert_equal 100, RobotWars::Robot.new(id: "r1").life
  end

  def test_apply_damage_reduces_life
    robot = RobotWars::Robot.new(id: "r1")
    robot.apply_damage(30)

    assert_equal 70, robot.life
  end

  def test_apply_damage_rejects_negative_amounts
    robot = RobotWars::Robot.new(id: "r1")

    assert_raises(ArgumentError) { robot.apply_damage(-1) }
  end

  def test_heal_increases_life_with_no_upper_limit
    robot = RobotWars::Robot.new(id: "r1")
    robot.heal(50)

    assert_equal 150, robot.life
  end

  def test_heal_rejects_negative_amounts
    robot = RobotWars::Robot.new(id: "r1")

    assert_raises(ArgumentError) { robot.heal(-1) }
  end

  def test_alive_and_dead_reflect_life_at_the_zero_boundary
    robot = RobotWars::Robot.new(id: "r1", life: 1)

    assert_predicate robot, :alive?
    refute_predicate robot, :dead?

    robot.apply_damage(1)

    refute_predicate robot, :alive?
    assert_predicate robot, :dead?
  end

  def test_negative_life_is_also_dead
    robot = RobotWars::Robot.new(id: "r1", life: 5)
    robot.apply_damage(20)

    assert_predicate robot, :dead?
  end

  def test_eliminate_kills_the_robot_regardless_of_life_total
    robot = RobotWars::Robot.new(id: "r1", life: 47)
    robot.eliminate!

    assert_predicate robot, :dead?
    assert_equal 47, robot.life
  end
end
