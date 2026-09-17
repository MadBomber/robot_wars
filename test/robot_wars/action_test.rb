require "test_helper"

class RobotWars::ActionTest < Minitest::Test
  def test_stay_has_no_direction_square_or_points
    action = RobotWars::Action.stay

    assert_predicate action, :stay?
    assert_nil action.direction
    assert_nil action.square
    assert_nil action.points
  end

  def test_move_carries_a_direction
    action = RobotWars::Action.move(RobotWars::Direction::NORTH)

    assert_predicate action, :move?
    assert_equal RobotWars::Direction::NORTH, action.direction
  end

  def test_attack_carries_a_square_and_points
    square = RobotWars::Position.new(x: 3, y: 3)
    action = RobotWars::Action.attack(square: square, points: 10)

    assert_predicate action, :attack?
    assert_equal square, action.square
    assert_equal 10, action.points
  end

  def test_attack_rejects_nonpositive_points
    square = RobotWars::Position.new(x: 3, y: 3)

    assert_raises(ArgumentError) { RobotWars::Action.attack(square: square, points: 0) }
  end

  def test_defend_carries_points
    action = RobotWars::Action.defend(points: 15)

    assert_predicate action, :defend?
    assert_equal 15, action.points
  end

  def test_defend_rejects_nonpositive_points
    assert_raises(ArgumentError) { RobotWars::Action.defend(points: -5) }
  end

  def test_predicates_are_mutually_exclusive
    action = RobotWars::Action.stay

    refute_predicate action, :move?
    refute_predicate action, :attack?
    refute_predicate action, :defend?
  end
end
