require "test_helper"

class RobotWars::OccupancyMapTest < Minitest::Test
  def setup
    @map = RobotWars::OccupancyMap.new
    @robot = RobotWars::Robot.new(id: "r1")
    @origin = RobotWars::Position.new(x: 0, y: 0)
  end

  def test_place_and_robot_at
    @map.place(@robot, @origin)

    assert_equal @robot, @map.robot_at(@origin)
    assert @map.occupied?(@origin)
  end

  def test_place_rejects_an_already_occupied_square
    @map.place(@robot, @origin)
    other = RobotWars::Robot.new(id: "r2")

    assert_raises(ArgumentError) { @map.place(other, @origin) }
  end

  def test_vacate_frees_the_square
    @map.place(@robot, @origin)
    @map.vacate(@origin)

    refute @map.occupied?(@origin)
    assert_nil @map.robot_at(@origin)
  end

  def test_move_relocates_the_robot
    destination = RobotWars::Position.new(x: 1, y: 0)
    @map.place(@robot, @origin)
    @map.move(@robot, from: @origin, to: destination)

    assert_nil @map.robot_at(@origin)
    assert_equal @robot, @map.robot_at(destination)
  end

  def test_move_rejects_a_robot_not_at_the_stated_origin
    destination = RobotWars::Position.new(x: 1, y: 0)

    assert_raises(ArgumentError) { @map.move(@robot, from: @origin, to: destination) }
  end

  def test_position_of_finds_a_placed_robot
    @map.place(@robot, @origin)

    assert_equal @origin, @map.position_of(@robot)
  end

  def test_position_of_returns_nil_for_an_absent_robot
    assert_nil @map.position_of(@robot)
  end

  def test_each_occupied_yields_every_position_and_robot
    other_position = RobotWars::Position.new(x: 1, y: 1)
    other_robot = RobotWars::Robot.new(id: "r2")
    @map.place(@robot, @origin)
    @map.place(other_robot, other_position)

    pairs = @map.each_occupied.to_a

    assert_includes pairs, [@origin, @robot]
    assert_includes pairs, [other_position, other_robot]
  end
end
