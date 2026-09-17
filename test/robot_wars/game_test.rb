require "test_helper"

class RobotWars::GameTest < Minitest::Test
  def test_start_places_every_robot_on_a_distinct_square
    game = RobotWars::Game.start(board: RobotWars::Board.new(width: 4, height: 4), robot_ids: %w[r1 r2 r3])

    positions = game.robots.map { |robot| game.occupancy.position_of(robot) }

    assert_equal 3, positions.uniq.size
    assert_equal %w[r1 r2 r3], game.robots.map(&:id)
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
    game = start_game(%w[survivor victim])
    survivor = game.robot("survivor")
    victim = game.robot("victim")
    victim_square = game.occupancy.position_of(victim)
    lethal_points = victim.life + 1 # victim's `stay` heals 1 before the shell lands

    game.play_turn(
      survivor => RobotWars::Action.attack(square: victim_square, points: lethal_points),
      victim => RobotWars::Action.stay
    )

    assert_predicate game, :over?
    assert_equal survivor, game.winner
    refute_predicate game, :tie?
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
end
