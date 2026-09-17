require "test_helper"

class RobotWars::PositionTest < Minitest::Test
  def test_addition_combines_coordinates
    position = RobotWars::Position.new(x: 2, y: 3)
    delta = RobotWars::Position.new(x: -1, y: 1)

    assert_equal RobotWars::Position.new(x: 1, y: 4), position + delta
  end

  def test_neighbors_returns_all_8_surrounding_positions
    position = RobotWars::Position.new(x: 5, y: 5)

    assert_equal 8, position.neighbors.size
    assert_includes position.neighbors, RobotWars::Position.new(x: 5, y: 4)
    assert_includes position.neighbors, RobotWars::Position.new(x: 6, y: 6)
    refute_includes position.neighbors, position
  end

  def test_positions_with_equal_coordinates_are_equal
    assert_equal RobotWars::Position.new(x: 1, y: 2), RobotWars::Position.new(x: 1, y: 2)
  end

  def test_positions_are_usable_as_hash_keys
    hash = { RobotWars::Position.new(x: 1, y: 2) => :marked }

    assert_equal :marked, hash[RobotWars::Position.new(x: 1, y: 2)]
  end
end
