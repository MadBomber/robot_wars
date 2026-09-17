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
    refute_predicate action, :invalid?
  end

  def test_invalid_has_no_direction_square_or_points
    action = RobotWars::Action.invalid

    assert_predicate action, :invalid?
    assert_nil action.direction
    assert_nil action.square
    assert_nil action.points
  end

  def test_to_s_renders_each_action_in_the_pilots_command_grammar
    assert_equal "STAY", RobotWars::Action.stay.to_s
    assert_equal "MOVE southwest", RobotWars::Action.move(RobotWars::Direction::SOUTHWEST).to_s
    assert_equal "ATTACK 3,7 12",
                 RobotWars::Action.attack(square: RobotWars::Position.new(x: 3, y: 7), points: 12).to_s
    assert_equal "DEFEND 4", RobotWars::Action.defend(points: 4).to_s
    assert_equal "INVALID", RobotWars::Action.invalid.to_s
  end

  def test_describe_anchors_stay_to_the_robots_square
    assert_equal "STAY at (3,4)", RobotWars::Action.stay.describe(RobotWars::Position.new(x: 3, y: 4))
  end

  def test_describe_anchors_move_to_its_intended_destination
    action = RobotWars::Action.move(RobotWars::Direction::SOUTHEAST)

    assert_equal "MOVE southeast to (7,8)", action.describe(RobotWars::Position.new(x: 6, y: 7))
  end

  def test_describe_leaves_the_other_actions_as_their_grammar_line
    origin = RobotWars::Position.new(x: 1, y: 1)
    square = RobotWars::Position.new(x: 3, y: 7)

    assert_equal "ATTACK 3,7 12", RobotWars::Action.attack(square: square, points: 12).describe(origin)
    assert_equal "DEFEND 4", RobotWars::Action.defend(points: 4).describe(origin)
    assert_equal "INVALID", RobotWars::Action.invalid.describe(origin)
  end

  def test_to_s_round_trips_through_the_parser
    parser = RobotWars::ActionParser.new
    actions = [
      RobotWars::Action.stay,
      RobotWars::Action.move(RobotWars::Direction::NORTHEAST),
      RobotWars::Action.attack(square: RobotWars::Position.new(x: 0, y: 9), points: 5),
      RobotWars::Action.defend(points: 8)
    ]

    actions.each { |action| assert_equal action, parser.parse(action.to_s) }
  end
end
