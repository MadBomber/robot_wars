require "test_helper"

class RobotWars::ActionParserTest < Minitest::Test
  def setup
    @parser = RobotWars::ActionParser.new
  end

  def test_parses_stay
    assert_predicate @parser.parse("STAY"), :stay?
  end

  def test_stay_is_case_insensitive_and_tolerates_surrounding_text
    action = @parser.parse("I think I'll just stay put this turn.")

    assert_predicate action, :stay?
  end

  def test_parses_move_with_a_direction_word
    action = @parser.parse("MOVE north")

    assert_predicate action, :move?
    assert_equal RobotWars::Direction::NORTH, action.direction
  end

  def test_move_is_case_insensitive
    action = @parser.parse("move Southeast")

    assert_predicate action, :move?
    assert_equal RobotWars::Direction::SOUTHEAST, action.direction
  end

  def test_move_with_an_unknown_direction_is_invalid
    assert_predicate @parser.parse("MOVE sideways"), :invalid?
  end

  def test_parses_attack_with_a_square_and_points
    action = @parser.parse("ATTACK 3,4 10")

    assert_predicate action, :attack?
    assert_equal RobotWars::Position.new(x: 3, y: 4), action.square
    assert_equal 10, action.points
  end

  def test_attack_tolerates_spaces_and_parentheses
    action = @parser.parse("ATTACK (3, 4) 10")

    assert_predicate action, :attack?
    assert_equal RobotWars::Position.new(x: 3, y: 4), action.square
  end

  def test_attack_with_0_points_is_invalid
    assert_predicate @parser.parse("ATTACK 3,4 0"), :invalid?
  end

  def test_parses_defend_with_points
    action = @parser.parse("DEFEND 25")

    assert_predicate action, :defend?
    assert_equal 25, action.points
  end

  def test_defend_with_0_points_is_invalid
    assert_predicate @parser.parse("DEFEND 0"), :invalid?
  end

  def test_gibberish_is_invalid
    assert_predicate @parser.parse("I panic and scream into the void."), :invalid?
  end

  def test_nil_is_invalid
    assert_predicate @parser.parse(nil), :invalid?
  end
end
