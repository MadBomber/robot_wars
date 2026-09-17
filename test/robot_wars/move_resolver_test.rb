require "test_helper"

class RobotWars::MoveResolverTest < Minitest::Test
  def setup
    @board = RobotWars::Board.new(width: 3, height: 3)
    @territory = RobotWars::Territory.new
    @resolver = RobotWars::MoveResolver.new(board: @board, territory: @territory)
    @robot = RobotWars::Robot.new(id: "r1")
  end

  def test_a_move_within_the_board_is_legal
    origin = RobotWars::Position.new(x: 1, y: 1)
    result = @resolver.resolve(@robot, origin, RobotWars::Direction::EAST)

    assert result.legal
    assert_equal RobotWars::Position.new(x: 2, y: 1), result.destination
  end

  def test_a_move_off_the_board_is_illegal_and_stays_put
    origin = RobotWars::Position.new(x: 0, y: 0)
    result = @resolver.resolve(@robot, origin, RobotWars::Direction::WEST)

    refute result.legal
    assert_equal origin, result.destination
  end

  def test_a_move_into_a_square_owned_by_another_robot_is_illegal
    origin = RobotWars::Position.new(x: 1, y: 1)
    destination = RobotWars::Position.new(x: 2, y: 1)
    rival = RobotWars::Robot.new(id: "r2")
    @territory.claim!(destination, rival)

    result = @resolver.resolve(@robot, origin, RobotWars::Direction::EAST)

    refute result.legal
    assert_equal origin, result.destination
  end

  def test_a_move_into_a_square_owned_by_the_mover_is_legal
    origin = RobotWars::Position.new(x: 1, y: 1)
    destination = RobotWars::Position.new(x: 2, y: 1)
    @territory.claim!(destination, @robot)

    result = @resolver.resolve(@robot, origin, RobotWars::Direction::EAST)

    assert result.legal
  end
end
