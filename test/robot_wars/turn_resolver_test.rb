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
    assert_equal pos(1, 2), @occupancy.position_of(robot)
  end

  def test_staying_adds_1_life_and_does_not_move
    robot = place("r1", life: 100, at: [1, 1])

    resolve(robot => RobotWars::Action.stay)

    assert_equal 101, robot.life
    assert_equal pos(1, 1), @occupancy.position_of(robot)
  end

  def test_an_invalid_action_is_penalized_like_an_illegal_move
    robot = place("r1", life: 100, at: [1, 1])
    resolver = turn_resolver(illegal_move_resolver: illegal_move_resolver(rolls: [6]))

    resolver.resolve!(robot => RobotWars::Action.invalid)

    assert_equal 94, robot.life
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

  def test_an_invalid_action_is_reported_as_a_solo_conflict
    robot = place("r1", life: 100, at: [1, 1])
    resolver = turn_resolver(illegal_move_resolver: illegal_move_resolver(rolls: [6]))

    report = resolver.resolve!(robot => RobotWars::Action.invalid)

    assert_equal [RobotWars::TurnResolver::SoloConflict.new(robot: robot, roll: 6)], report.solo_conflicts
    assert_equal "solo conflict: r1 — roll 6, no movement", report.solo_conflicts.first.to_s
  end

  def test_an_illegal_move_is_reported_as_a_solo_conflict
    robot = place("r1", life: 100, at: [0, 0])
    resolver = turn_resolver(illegal_move_resolver: illegal_move_resolver(rolls: [7]))

    report = resolver.resolve!(robot => RobotWars::Action.move(RobotWars::Direction::WEST))

    assert_equal [RobotWars::TurnResolver::SoloConflict.new(robot: robot, roll: 7)], report.solo_conflicts
  end

  # Rule 43: committing more points than current life is a pilot error,
  # punished exactly like an unparsable reply.
  def test_an_attack_committing_more_than_current_life_is_an_invalid_action
    robot = place("r1", life: 10, at: [1, 1])
    resolver = turn_resolver(illegal_move_resolver: illegal_move_resolver(rolls: [6]))

    report = resolver.resolve!(robot => RobotWars::Action.attack(square: pos(0, 0), points: 11))

    assert_equal 4, robot.life
    assert_equal 1, report.solo_conflicts.size
    assert_empty report.ranged_effects
    assert_equal pos(1, 1), @occupancy.position_of(robot)
  end

  def test_a_defense_committing_more_than_current_life_is_an_invalid_action
    robot = place("r1", life: 10, at: [1, 1])
    resolver = turn_resolver(illegal_move_resolver: illegal_move_resolver(rolls: [6]))

    report = resolver.resolve!(robot => RobotWars::Action.defend(points: 11))

    assert_equal 4, robot.life
    assert_equal 1, report.solo_conflicts.size
    assert_empty report.ranged_effects
  end

  def test_committing_exactly_the_current_life_is_legal
    robot = place("r1", life: 10, at: [1, 1])

    report = resolve(robot => RobotWars::Action.attack(square: pos(0, 0), points: 10))

    assert_equal 10, robot.life
    assert_equal :miss, report.attack_outcome_for(robot)
    assert_empty report.solo_conflicts
  end

  # Rule 44 through the full turn: the attacker also gets :off_board
  # feedback, the one clue that the shot was aimed nowhere.
  def test_an_attack_on_an_off_board_square_costs_half_and_reports_off_board
    robot = place("r1", life: 100, at: [1, 1])

    report = resolve(robot => RobotWars::Action.attack(square: pos(5, 5), points: 4))

    assert_equal 98, robot.life
    assert_equal :off_board, report.attack_outcome_for(robot)
  end

  def test_staying_3_turns_reports_the_occupation_claim_on_the_third
    robot = place("r1", life: 100, at: [1, 1])
    resolver = turn_resolver

    2.times { assert_empty resolver.resolve!(robot => RobotWars::Action.stay).claimed_squares_for(robot) }
    report = resolver.resolve!(robot => RobotWars::Action.stay)

    assert_equal [pos(1, 1)], report.claimed_squares_for(robot)
    # The 4th turn is continued ownership, not a new claim.
    assert_empty resolver.resolve!(robot => RobotWars::Action.stay).claimed_squares_for(robot)
  end

  def test_a_legal_turn_reports_no_conflicts
    robot = place("r1", life: 100, at: [1, 1])

    report = resolve(robot => RobotWars::Action.stay)

    assert_empty report.conflicts
    assert_empty report.solo_conflicts
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
    report = resolver.resolve!(
      strong => RobotWars::Action.move(RobotWars::Direction::EAST),
      weak => RobotWars::Action.move(RobotWars::Direction::WEST)
    )

    conflict = report.conflicts.first
    assert_equal 1, report.conflicts.size
    assert_equal pos(1, 1), conflict.square
    assert_equal [strong, weak], conflict.robots
    assert_equal 5, conflict.roll
    assert_equal strong, conflict.winner
    assert_equal [weak], conflict.losers
    assert_equal "conflict at (1,1): strong vs weak — roll 5, strong takes the square", conflict.to_s

    # Conquest is a new ownership, reported as a claim.
    assert_equal [pos(1, 1)], report.claimed_squares_for(strong)
    assert_empty report.claimed_squares_for(weak)

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
    report = resolver.resolve!(
      first => RobotWars::Action.move(RobotWars::Direction::EAST),
      second => RobotWars::Action.move(RobotWars::Direction::WEST)
    )

    conflict = report.conflicts.first
    assert_nil conflict.winner
    assert_equal [first, second], conflict.losers
    assert_equal "conflict at (1,1): a vs b — roll 3, tie, everyone loses", conflict.to_s

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
      b => RobotWars::Action.move(RobotWars::Direction::SOUTH),
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
    # Both battles are reported: the (1,0) contest and A's losing
    # return-home fight against B at (0,0).
    assert_equal [pos(1, 0), pos(0, 0)], report.conflicts.map(&:square)
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
      b => RobotWars::Action.move(RobotWars::Direction::SOUTHWEST),
      c => RobotWars::Action.move(RobotWars::Direction::WEST),
      d => RobotWars::Action.move(RobotWars::Direction::WEST),
      z => RobotWars::Action.stay
    )

    assert_predicate a, :dead?
    assert_nil @occupancy.position_of(a)
    assert_includes report.deaths, a
  end

  # --- Rule 46: dead robots take no further part in the turn ---------

  def test_a_loser_killed_by_the_conflict_roll_never_returns_home
    strong = place("strong", life: 100, at: [0, 1])
    weak = place("weak", life: 5, at: [2, 1])

    resolver = turn_resolver(conflict_resolver: conflict_resolver(rolls: [6]))
    report = resolver.resolve!(
      strong => RobotWars::Action.move(RobotWars::Direction::EAST),
      weak => RobotWars::Action.move(RobotWars::Direction::WEST)
    )

    assert_predicate weak, :dead?
    assert_nil @occupancy.position_of(weak)
    assert_includes report.deaths, weak
    assert_equal 1, report.conflicts.size
    assert @territory.owned_by?(pos(1, 1), strong)
  end

  def test_a_winner_killed_by_the_conflict_roll_wins_nothing
    a = place("a", life: 6, at: [0, 1])
    b = place("b", life: 5, at: [2, 1])

    resolver = turn_resolver(conflict_resolver: conflict_resolver(rolls: [6]))
    report = resolver.resolve!(
      a => RobotWars::Action.move(RobotWars::Direction::EAST),
      b => RobotWars::Action.move(RobotWars::Direction::WEST)
    )

    conflict = report.conflicts.first
    assert_equal a, conflict.winner
    assert conflict.winner_died
    assert_equal "conflict at (1,1): a vs b — roll 6, a wins but dies", conflict.to_s

    assert_equal [a, b].sort_by(&:id), report.deaths.sort_by(&:id)
    refute @occupancy.occupied?(pos(1, 1))
    refute @territory.owned?(pos(1, 1))
  end

  def test_a_robot_killed_in_the_movement_phase_leaves_the_board_before_conflicts
    doomed = place("doomed", life: 5, at: [1, 1])
    walker = place("walker", life: 100, at: [0, 1])

    resolver = turn_resolver(illegal_move_resolver: illegal_move_resolver(rolls: [10]))
    report = resolver.resolve!(
      doomed => RobotWars::Action.invalid,
      walker => RobotWars::Action.move(RobotWars::Direction::EAST)
    )

    assert_predicate doomed, :dead?
    assert_includes report.deaths, doomed
    # The corpse is gone, so walker finds (1,1) empty — no conflict.
    assert_empty report.conflicts
    assert_equal pos(1, 1), @occupancy.position_of(walker)
  end

  def test_a_dead_robots_declared_attack_does_not_fire
    gunner = place("gunner", life: 3, at: [1, 1])
    brawler = place("brawler", life: 100, at: [0, 1])
    bystander = place("bystander", life: 100, at: [0, 0])

    resolver = turn_resolver(conflict_resolver: conflict_resolver(rolls: [5]))
    report = resolver.resolve!(
      gunner => RobotWars::Action.attack(square: pos(0, 0), points: 3),
      brawler => RobotWars::Action.move(RobotWars::Direction::EAST),
      bystander => RobotWars::Action.stay
    )

    assert_predicate gunner, :dead?
    assert_equal 101, bystander.life
    assert_empty report.ranged_effects
  end

  def test_a_dead_defender_neither_counter_fires_nor_pays_the_premium
    turtle = place("turtle", life: 5, at: [1, 1])
    brawler = place("brawler", life: 100, at: [0, 1])

    resolver = turn_resolver(conflict_resolver: conflict_resolver(rolls: [6]))
    report = resolver.resolve!(
      turtle => RobotWars::Action.defend(points: 5),
      brawler => RobotWars::Action.move(RobotWars::Direction::EAST)
    )

    assert_predicate turtle, :dead?
    assert_equal(-1, turtle.life)
    assert_empty report.ranged_effects
  end

  # --- Rules 18/24 (ruled 2026-09-17): a home square a rival now owns
  # --- cannot be re-entered — retreat to a free neighbor or die.

  def test_a_returner_whose_home_is_rival_owned_retreats_to_a_free_neighbor
    landlord = RobotWars::Robot.new(id: "landlord")
    @territory.claim!(pos(0, 0), landlord)
    @territory.claim!(pos(0, 1), landlord)
    a = place("a", life: 100, at: [0, 0])
    c = place("c", life: 110, at: [2, 0])

    resolver = turn_resolver(conflict_resolver: conflict_resolver(rolls: [5]))
    report = resolver.resolve!(
      a => RobotWars::Action.move(RobotWars::Direction::EAST),
      c => RobotWars::Action.move(RobotWars::Direction::WEST)
    )

    # Home (0,0) is landlord's; of its neighbors (1,0) is taken by c and
    # (0,1) is landlord's too — (1,1) is the only place left to stand.
    assert_predicate a, :alive?
    assert_equal pos(1, 1), @occupancy.position_of(a)
    assert_equal 1, report.conflicts.size
  end

  def test_a_returner_whose_home_is_rival_owned_dies_with_no_free_neighbor
    landlord = RobotWars::Robot.new(id: "landlord")
    @territory.claim!(pos(0, 0), landlord)
    @territory.claim!(pos(0, 1), landlord)
    @territory.claim!(pos(1, 1), landlord)
    a = place("a", life: 100, at: [0, 0])
    c = place("c", life: 110, at: [2, 0])

    resolver = turn_resolver(conflict_resolver: conflict_resolver(rolls: [5]))
    report = resolver.resolve!(
      a => RobotWars::Action.move(RobotWars::Direction::EAST),
      c => RobotWars::Action.move(RobotWars::Direction::WEST)
    )

    assert_predicate a, :dead?
    assert_nil @occupancy.position_of(a)
    assert_includes report.deaths, a
  end

  def test_ranged_combat_resolves_against_post_move_positions
    attacker = place("attacker", life: 100, at: [0, 0])
    target = place("target", life: 100, at: [2, 2])

    report = resolve(
      attacker => RobotWars::Action.attack(square: pos(2, 2), points: 5),
      target => RobotWars::Action.defend(points: 10)
    )

    assert_equal 95, target.life
    assert_equal 90, attacker.life

    # Battleship feedback: the attacker learns HIT; the defender's
    # counter-fire is not a shot of its own, so it learns nothing.
    assert_equal :hit, report.attack_outcome_for(attacker)
    assert_nil report.attack_outcome_for(target)
  end

  def test_an_attack_on_an_empty_square_is_a_miss
    attacker = place("attacker", life: 100, at: [0, 0])
    bystander = place("bystander", life: 100, at: [1, 1])

    report = resolve(
      attacker => RobotWars::Action.attack(square: pos(2, 2), points: 5),
      bystander => RobotWars::Action.stay
    )

    assert_equal 100, attacker.life
    assert_equal :miss, report.attack_outcome_for(attacker)
    assert_nil report.attack_outcome_for(bystander)
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

  # --- The ordered event stream (Report#events) ----------------------

  def test_events_open_with_every_robots_declared_action
    mover = place("mover", life: 100, at: [1, 1])
    sitter = place("sitter", life: 100, at: [0, 0])

    report = resolve(
      mover => RobotWars::Action.move(RobotWars::Direction::NORTH),
      sitter => RobotWars::Action.stay
    )

    declared = report.events.grep(RobotWars::TurnResolver::Declared)
    assert_equal(%w[mover sitter], declared.map { |event| event.robot.id })
    assert_equal "mover: MOVE north to (1,2)", declared.first.to_s
    assert_equal({ type: :action, robot: "mover", action: "MOVE north", origin: { x: 1, y: 1 } },
                 declared.first.to_h)
  end

  def test_events_record_the_declared_action_not_the_rule_43_downgrade
    robot = place("r1", life: 10, at: [1, 1])
    resolver = turn_resolver(illegal_move_resolver: illegal_move_resolver(rolls: [6]))

    report = resolver.resolve!(robot => RobotWars::Action.attack(square: pos(0, 0), points: 11))

    declared = report.events.grep(RobotWars::TurnResolver::Declared).first
    assert_equal "ATTACK 0,0 11", declared.action.to_s
    assert_includes report.events, report.solo_conflicts.first
  end

  def test_events_carry_the_conflict_and_its_conquest_claim_in_order
    strong = place("strong", life: 100, at: [0, 1])
    weak = place("weak", life: 90, at: [2, 1])
    resolver = turn_resolver(conflict_resolver: conflict_resolver(rolls: [5]))

    report = resolver.resolve!(
      strong => RobotWars::Action.move(RobotWars::Direction::EAST),
      weak => RobotWars::Action.move(RobotWars::Direction::WEST)
    )

    conflict = report.conflicts.first
    claim = report.claims.first
    assert_operator report.events.index(conflict), :<, report.events.index(claim)
    assert_equal({ type: :conflict, square: { x: 1, y: 1 }, robots: %w[strong weak], roll: 5,
                   winner: "strong", losers: ["weak"], winner_died: false }, conflict.to_h)
    assert_equal({ type: :claim, robot: "strong", square: { x: 1, y: 1 } }, claim.to_h)
    assert_equal "strong now owns (1,1)", claim.to_s
  end

  def test_a_solo_conflict_serializes_into_the_stream
    robot = place("r1", life: 100, at: [1, 1])
    resolver = turn_resolver(illegal_move_resolver: illegal_move_resolver(rolls: [6]))

    report = resolver.resolve!(robot => RobotWars::Action.invalid)

    assert_equal({ type: :solo_conflict, robot: "r1", roll: 6 }, report.solo_conflicts.first.to_h)
  end

  def test_a_displacement_is_an_event_a_spectator_can_see
    # The defender loses at the square it never left (its origin IS the
    # battlefield), so it goes straight to displacement (rules 19-20).
    defender = place("defender", life: 90, at: [1, 1])
    invader = place("invader", life: 100, at: [2, 1])
    resolver = turn_resolver(conflict_resolver: conflict_resolver(rolls: [5]))

    report = resolver.resolve!(
      defender => RobotWars::Action.stay,
      invader => RobotWars::Action.move(RobotWars::Direction::WEST)
    )

    displaced = report.events.grep(RobotWars::TurnResolver::Displaced).first
    assert_equal defender, displaced.robot
    assert_equal pos(1, 1), displaced.from
    assert_equal @occupancy.position_of(defender), displaced.to
    assert_equal "defender is displaced to (#{displaced.to.x},#{displaced.to.y})", displaced.to_s
    assert_equal({ type: :displaced, robot: "defender", from: { x: 1, y: 1 }, to: displaced.to.to_h },
                 displaced.to_h)
  end

  def test_a_death_is_an_event_at_the_end_of_the_stream
    attacker = place("attacker", life: 100, at: [0, 0])
    victim = place("victim", life: 5, at: [2, 2])

    report = resolve(
      attacker => RobotWars::Action.attack(square: pos(2, 2), points: 10),
      victim => RobotWars::Action.stay
    )

    death = report.events.grep(RobotWars::TurnResolver::Death).first
    assert_equal victim, death.robot
    assert_equal "victim is destroyed", death.to_s
    assert_equal({ type: :death, robot: "victim" }, death.to_h)
    assert_includes report.events, report.ranged_effects.first
  end

  def test_a_tied_conflict_serializes_with_no_winner
    first = place("first", life: 100, at: [0, 1])
    second = place("second", life: 100, at: [2, 1])
    resolver = turn_resolver(conflict_resolver: conflict_resolver(rolls: [5]))

    report = resolver.resolve!(
      first => RobotWars::Action.move(RobotWars::Direction::EAST),
      second => RobotWars::Action.move(RobotWars::Direction::WEST)
    )

    assert_nil report.conflicts.first.to_h.fetch(:winner)
  end

  def test_every_event_serializes_with_a_type
    strong = place("strong", life: 100, at: [0, 1])
    weak = place("weak", life: 5, at: [2, 1])
    resolver = turn_resolver(conflict_resolver: conflict_resolver(rolls: [5]))

    report = resolver.resolve!(
      strong => RobotWars::Action.move(RobotWars::Direction::EAST),
      weak => RobotWars::Action.move(RobotWars::Direction::WEST)
    )

    report.events.each do |event|
      assert_kind_of Symbol, event.to_h.fetch(:type)
      assert_kind_of String, event.to_s
    end
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
