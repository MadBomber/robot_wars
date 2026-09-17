require "test_helper"

class RobotWars::GameTest < Minitest::Test
  def test_start_places_every_robot_on_a_distinct_square
    game = RobotWars::Game.start(board: RobotWars::Board.new(width: 4, height: 4), robot_ids: %w[r1 r2 r3])

    positions = game.robots.map { |robot| game.occupancy.position_of(robot) }

    assert_equal 3, positions.uniq.size
    assert_equal %w[r1 r2 r3], game.robots.map(&:id)
  end

  def test_start_gives_every_robot_the_standard_100_life_by_default
    game = RobotWars::Game.start(board: RobotWars::Board.new(width: 3, height: 3), robot_ids: %w[r1 r2])

    assert_equal [100, 100], game.robots.map(&:life)
  end

  def test_start_accepts_a_custom_starting_life_for_every_robot
    game = RobotWars::Game.start(board: RobotWars::Board.new(width: 3, height: 3), robot_ids: %w[r1 r2], life: 25)

    assert_equal [25, 25], game.robots.map(&:life)
  end

  def test_robot_looks_up_a_roster_member_by_id
    game = RobotWars::Game.start(board: RobotWars::Board.new(width: 3, height: 3), robot_ids: %w[r1 r2])

    assert_equal "r1", game.robot("r1").id
    assert_nil game.robot("missing")
  end

  def test_play_turn_requires_exactly_one_action_per_living_robot
    game = start_game(%w[r1 r2])
    r1 = game.robot("r1")

    assert_raises(ArgumentError) { game.play_turn(r1 => RobotWars::Action.stay) }
  end

  def test_play_turn_advances_the_turn_number_and_runs_the_resolver
    game = start_game(%w[r1 r2])
    r1 = game.robot("r1")
    r2 = game.robot("r2")

    game.play_turn(r1 => RobotWars::Action.stay, r2 => RobotWars::Action.stay)

    assert_equal 1, game.turn_number
    assert_equal 101, r1.life
    assert_equal 101, r2.life
  end

  def test_a_2_robot_game_ends_when_one_robot_dies
    game = RobotWars::Game.new(board: RobotWars::Board.new(width: 6, height: 6))
    survivor = RobotWars::Robot.new(id: "survivor")
    victim = RobotWars::Robot.new(id: "victim", life: 5)
    game.add_robot(survivor, pos(0, 0))
    game.add_robot(victim, pos(3, 3))

    game.play_turn(
      survivor => RobotWars::Action.attack(square: pos(3, 3), points: 10),
      victim => RobotWars::Action.stay
    )

    assert_predicate game, :over?
    assert_equal survivor, game.winner
    refute_predicate game, :tie?
  end

  def test_a_seeded_game_reproduces_its_conflict_rolls
    lives = Array.new(2) { colliding_turn(random: Random.new(7)) }

    assert_equal lives.first, lives.last
  end

  def test_an_explicit_roll_generator_drives_the_conflict_rolls
    lives = colliding_turn(roll_generator: RobotWars::FixedRollGenerator.new([4]))

    # a: 100 - 1 move - 4 roll = 95 and wins; b: 90 - 1 - 4 = 85, sent home.
    assert_equal [95, 85], lives
  end

  def test_remove_robot_kills_and_cleans_up_a_brain_dead_robot
    game = start_game(%w[r1 r2])
    r2 = game.robot("r2")
    square = game.occupancy.position_of(r2)
    game.territory.claim!(square, r2)

    game.remove_robot(r2)

    assert_predicate r2, :dead?
    assert_nil game.occupancy.position_of(r2)
    refute game.territory.owned?(square)
    refute_includes game.robots, r2
    assert_predicate game, :over?
    assert_equal "r1", game.winner.id
  end

  def test_remove_robot_tolerates_a_robot_already_off_the_board
    game = start_game(%w[r1 r2 r3])
    r3 = game.robot("r3")

    game.remove_robot(r3)
    game.remove_robot(r3)

    refute_includes game.robots, r3
    refute_predicate game, :over?
  end

  def test_over_is_false_while_2_or_more_robots_are_alive
    game = start_game(%w[r1 r2])

    refute_predicate game, :over?
    assert_nil game.winner
  end

  def test_playing_a_turn_after_the_game_is_over_raises
    game = start_game(%w[survivor victim])
    victim = game.robot("victim")
    victim.eliminate!

    assert_raises(ArgumentError) { game.play_turn({}) }
  end

  def test_occupation_ownership_vests_after_3_consecutive_stationary_turns
    game = start_game(%w[camper wanderer])
    camper = game.robot("camper")
    wanderer = game.robot("wanderer")
    square = game.occupancy.position_of(camper)

    3.times { game.play_turn(camper => RobotWars::Action.stay, wanderer => RobotWars::Action.stay) }

    assert game.territory.owned_by?(square, camper)
  end

  private

  def start_game(ids)
    RobotWars::Game.start(board: RobotWars::Board.new(width: 6, height: 6), robot_ids: ids, random: Random.new(1))
  end

  def pos(x, y) = RobotWars::Position.new(x: x, y: y)

  # One head-on collision at (1,1) on a 3x3 board; returns both lives
  # after the turn, so two identically seeded runs can be compared.
  def colliding_turn(**game_options)
    game = RobotWars::Game.new(board: RobotWars::Board.new(width: 3, height: 3), **game_options)
    a = RobotWars::Robot.new(id: "a")
    b = RobotWars::Robot.new(id: "b", life: 90)
    game.add_robot(a, pos(0, 1))
    game.add_robot(b, pos(2, 1))

    game.play_turn(
      a => RobotWars::Action.move(RobotWars::Direction::EAST),
      b => RobotWars::Action.move(RobotWars::Direction::WEST)
    )

    [a.life, b.life]
  end
end
