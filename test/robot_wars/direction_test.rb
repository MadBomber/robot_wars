require "test_helper"

class RobotWars::DirectionTest < Minitest::Test
  def test_has_8_offsets
    assert_equal 8, RobotWars::Direction::OFFSETS.size
  end

  def test_offsets_are_unique
    assert_equal 8, RobotWars::Direction::OFFSETS.uniq.size
  end

  def test_every_offset_is_exactly_1_square_away
    origin = RobotWars::Position.new(x: 0, y: 0)

    RobotWars::Direction::OFFSETS.each do |offset|
      assert_includes(-1..1, offset.x)
      assert_includes(-1..1, offset.y)
      refute_equal origin, offset
    end
  end

  def test_north_moves_up
    assert_equal RobotWars::Position.new(x: 0, y: -1), RobotWars::Direction::NORTH
  end

  def test_name_of_names_every_offset
    names = RobotWars::Direction::OFFSETS.map { |offset| RobotWars::Direction.name_of(offset) }

    assert_equal %w[north northeast east southeast south southwest west northwest], names
  end

  def test_name_of_returns_nil_for_a_position_that_is_not_a_direction
    assert_nil RobotWars::Direction.name_of(RobotWars::Position.new(x: 2, y: 5))
  end
end
