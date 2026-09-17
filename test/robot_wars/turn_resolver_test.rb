require "test_helper"

class RobotWars::TurnResolverTest < Minitest::Test
  def setup
    @board = RobotWars::Board.new(width: 3, height: 3)
    @occupancy = RobotWars::OccupancyMap.new
    @territory = RobotWars::Territory.new
  end

  def test_a_successful_move_costs_1_life_and_relocates_the_robot
    robot = place("r1", life: 100, at: [1, 1])

    resolve(robot => RobotWars::Action.move(RobotWars::Direction::NORTH))

    assert_equal 99, robot.life
    assert_equal pos(1, 0), @occupancy.position_of(robot)
  end

  def test_staying_adds_1_life_and_does_not_move
    robot = place("r1", life: 100, at: [1, 1])

    resolve(robot => RobotWars::Action.stay)

    assert_equal 101, robot.life
    assert_equal pos(1, 1), @occupancy.position_of(robot)
  end

  def test_a_move_off_the_board_is_illegal_and_costs_the_solo_conflict_roll
    robot = place("r1", life: 100, at: [0, 0])
    resolver = turn_resolver(illegal_move_resolver: illegal_move_resolver(rolls: [7]))

    resolver.resolve!(robot => RobotWars::Action.move(RobotWars::Direction::WEST))

    assert_equal 93, robot.life
    assert_equal pos(0, 0), @occupancy.position_of(robot)
  end

  def test_a_move_into_a_rivals_owned_square_is_illegal
    robot = place("r1", life: 100, at: [0, 0])
    rival = RobotWars::Robot.new(id: "rival")
    @territory.claim!(pos(1, 0), rival)
    resolver = turn_resolver(illegal_move_resolver: illegal_move_resolver(rolls: [4]))

    resolver.resolve!(robot => RobotWars::Action.move(RobotWars::Direction::EAST))

    assert_equal 96, robot.life
    assert_equal pos(0, 0), @occupancy.position_of(robot)
  end

  def test_swapping_squares_is_not_a_conflict
    first = place("r1", life: 100, at: [0, 1])
    second = place("r2", life: 100, at: [1, 1])

    resolve(
      first => RobotWars::Action.move(RobotWars::Direction::EAST),
      second => RobotWars::Action.move(RobotWars::Direction::WEST)
    )

    assert_equal pos(1, 1), @occupancy.position_of(first)
    assert_equal pos(0, 1), @occupancy.position_of(second)
    assert_equal 99, first.life
    assert_equal 99, second.life
  end

  def test_the_winner_of_a_square_conflict_claims_it_and_the_loser_returns_home
    strong = place("strong", life: 100, at: [0, 1])
    weak = place("weak", life: 90, at: [2, 1])

    resolver = turn_resolver(conflict_resolver: conflict_resolver(rolls: [5]))
    resolver.resolve!(
      strong => RobotWars::Action.move(RobotWars::Direction::EAST),
      weak => RobotWars::Action.move(RobotWars::Direction::WEST)
    )

    assert_equal pos(1, 1), @occupancy.position_of(strong)
    assert_equal 94, strong.life
    assert @territory.owned_by?(pos(1, 1), strong)

    assert_equal pos(2, 1), @occupancy.position_of(weak)
    assert_equal 84, weak.life
    refute @territory.owned?(pos(2, 1))
  end

  def test_a_tied_conflict_leaves_the_square_unowned_and_sends_everyone_home
    first = place("a", life: 100, at: [0, 1])
    second = place("b", life: 100, at: [2, 1])

    resolver = turn_resolver(conflict_resolver: conflict_resolver(rolls: [3]))
    resolver.resolve!(
      first => RobotWars::Action.move(RobotWars::Direction::EAST),
      second => RobotWars::Action.move(RobotWars::Direction::WEST)
    )

    assert_equal pos(0, 1), @occupancy.position_of(first)
    assert_equal pos(2, 1), @occupancy.position_of(second)
    assert_equal 96, first.life
    assert_equal 96, second.life
    refute @territory.owned?(pos(1, 1))
  end

  # A: (0,0) -> east -> (1,0), fights C there and loses twice on the
  # cascade back home, but finds one open neighbor and survives there.
  def test_a_cascading_return_conflict_can_end_in_a_successful_displacement
    a = place("a", life: 100, at: [0, 0])
    b = place("b", life: 100, at: [0, 1])
    c = place("c", life: 110, at: [2, 0])
    d = place("d", life: 100, at: [1, 1])

    resolver = turn_resolver(conflict_resolver: conflict_resolver(rolls: [5, 3]))
    report = resolver.resolve!(
      a => RobotWars::Action.move(RobotWars::Direction::EAST),
      b => RobotWars::Action.move(RobotWars::Direction::NORTH),
      c => RobotWars::Action.move(RobotWars::Direction::WEST),
      d => RobotWars::Action.stay
    )

    assert_equal pos(1, 0), @occupancy.position_of(c)
    assert_equal 104, c.life
    assert @territory.owned_by?(pos(1, 0), c)

    assert_equal pos(0, 0), @occupancy.position_of(b)
    assert_equal 96, b.life
    assert @territory.owned_by?(pos(0, 0), b)

    assert_equal pos(1, 1), @occupancy.position_of(d)
    assert_equal 101, d.life

    assert_equal pos(0, 1), @occupancy.position_of(a)
    assert_equal 91, a.life
    assert_predicate a, :alive?
    assert_empty report.deaths
  end

  # Same shape, but every neighbor of the final battle square is taken —
  # A dies with nowhere to stand (rule 20).
  def test_a_twice_defeated_robot_dies_when_no_adjacent_square_is_free
    a = place("a", life: 100, at: [0, 0])
    b = place("b", life: 100, at: [1, 1])
    c = place("c", life: 110, at: [2, 0])
    d = place("d", life: 100, at: [2, 1])
    z = place("z", life: 100, at: [0, 1])

    resolver = turn_resolver(conflict_resolver: conflict_resolver(rolls: [5, 3]))
    report = resolver.resolve!(
      a => RobotWars::Action.move(RobotWars::Direction::EAST),
      b => RobotWars::Action.move(RobotWars::Direction::NORTHWEST),
      c => RobotWars::Action.move(RobotWars::Direction::WEST),
      d => RobotWars::Action.move(RobotWars::Direction::WEST),
      z => RobotWars::Action.stay
    )

    assert_predicate a, :dead?
    assert_nil @occupancy.position_of(a)
    assert_includes report.deaths, a
  end

  def test_ranged_combat_resolves_against_post_move_positions
    attacker = place("attacker", life: 100, at: [0, 0])
    target = place("target", life: 100, at: [2, 2])

    resolve(
      attacker => RobotWars::Action.attack(square: pos(2, 2), points: 5),
      target => RobotWars::Action.defend(points: 10)
    )

    assert_equal 95, target.life
    assert_equal 90, attacker.life
  end

  def test_a_robot_killed_by_ranged_combat_is_removed_and_its_territory_released
    attacker = place("attacker", life: 100, at: [0, 0])
    victim = place("victim", life: 5, at: [2, 2])
    @territory.claim!(pos(2, 2), victim)

    report = resolve(
      attacker => RobotWars::Action.attack(square: pos(2, 2), points: 10),
      victim => RobotWars::Action.stay
    )

    assert_predicate victim, :dead?
    assert_nil @occupancy.position_of(victim)
    refute @territory.owned?(pos(2, 2))
    assert_includes report.deaths, victim
  end

  private

  def pos(x, y) = RobotWars::Position.new(x: x, y: y)

  def place(id, life:, at:)
    robot = RobotWars::Robot.new(id: id, life: life)
    @occupancy.place(robot, pos(*at))
    robot
  end

  def conflict_resolver(rolls:)
    RobotWars::ConflictResolver.new(roll_generator: RobotWars::FixedRollGenerator.new(rolls))
  end

  def illegal_move_resolver(rolls:)
    RobotWars::IllegalMoveResolver.new(roll_generator: RobotWars::FixedRollGenerator.new(rolls))
  end

  def turn_resolver(**overrides)
    RobotWars::TurnResolver.new(board: @board, occupancy: @occupancy, territory: @territory, **overrides)
  end

  def resolve(actions)
    turn_resolver.resolve!(actions)
  end
end
