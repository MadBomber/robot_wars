require "test_helper"

class RobotWars::BoardTest < Minitest::Test
  def setup
    @board = RobotWars::Board.new(width: 5, height: 4)
  end

  def test_rejects_nonpositive_dimensions
    assert_raises(ArgumentError) { RobotWars::Board.new(width: 0, height: 4) }
    assert_raises(ArgumentError) { RobotWars::Board.new(width: 5, height: -1) }
  end

  def test_on_board_accepts_positions_within_bounds
    assert @board.on_board?(RobotWars::Position.new(x: 0, y: 0))
    assert @board.on_board?(RobotWars::Position.new(x: 4, y: 3))
  end

  def test_on_board_rejects_positions_outside_bounds
    refute @board.on_board?(RobotWars::Position.new(x: -1, y: 0))
    refute @board.on_board?(RobotWars::Position.new(x: 5, y: 0))
    refute @board.on_board?(RobotWars::Position.new(x: 0, y: 4))
  end

  def test_neighbors_of_a_corner_excludes_off_board_squares
    corner = RobotWars::Position.new(x: 0, y: 0)

    assert_equal 3, @board.neighbors_of(corner).size
  end

  def test_neighbors_of_an_interior_square_returns_all_8
    center = RobotWars::Position.new(x: 2, y: 2)

    assert_equal 8, @board.neighbors_of(center).size
  end

  def test_each_position_yields_every_square_exactly_once
    positions = @board.each_position.to_a

    assert_equal 20, positions.size
    assert_equal positions.size, positions.uniq.size
  end

  def test_random_position_is_always_on_board
    random = Random.new(42)

    50.times { assert @board.on_board?(@board.random_position(random: random)) }
  end

  def test_sample_positions_returns_the_requested_count_with_no_duplicates
    positions = @board.sample_positions(5, random: Random.new(1))

    assert_equal 5, positions.size
    assert_equal 5, positions.uniq.size
  end

  def test_sample_positions_rejects_more_robots_than_squares
    assert_raises(ArgumentError) { @board.sample_positions(21) }
  end
end
