require "test_helper"

class RobotWars::RangedCombatResolverTest < Minitest::Test
  def setup
    @map = RobotWars::OccupancyMap.new
    @board = RobotWars::Board.new(width: 8, height: 8)
    @attacker = RobotWars::Robot.new(id: "attacker")
    @target = RobotWars::Robot.new(id: "target")
    @square = RobotWars::Position.new(x: 4, y: 4)
    @map.place(@target, @square)
    @resolver = RobotWars::RangedCombatResolver.new(occupancy_map: @map, board: @board)
  end

  def test_an_undefended_hit_costs_the_target_the_full_amount_and_the_attacker_nothing
    attack = attack_order(points: 20)

    @resolver.resolve(attacks: [attack], defenses: [])

    assert_equal 80, @target.life
    assert_equal 100, @attacker.life
  end

  def test_an_attack_on_an_empty_square_misses
    empty_square = RobotWars::Position.new(x: 0, y: 0)
    attack = attack_order(square: empty_square, points: 20)

    @resolver.resolve(attacks: [attack], defenses: [])

    assert_equal 100, @attacker.life
    assert_equal 100, @target.life
  end

  def test_an_off_board_attack_costs_the_attacker_half_the_points_rounded_up
    attack = attack_order(square: RobotWars::Position.new(x: -1, y: 3), points: 5)

    effects = @resolver.resolve(attacks: [attack], defenses: [])

    assert_equal 97, @attacker.life
    assert_equal 100, @target.life
    assert_equal [:off_board], effects.map(&:kind)
    assert_equal 3, effects.first.amount
  end

  def test_an_off_board_attack_with_even_points_costs_exactly_half
    attack = attack_order(square: RobotWars::Position.new(x: 8, y: 8), points: 10)

    @resolver.resolve(attacks: [attack], defenses: [])

    assert_equal 95, @attacker.life
  end

  def test_a_defended_target_still_takes_the_full_hit
    attack = attack_order(points: 5)
    defense = defend_order(points: 10)

    @resolver.resolve(attacks: [attack], defenses: [defense])

    assert_equal 95, @target.life
  end

  def test_the_attacker_is_counter_hit_for_the_defenders_full_committed_amount
    attack = attack_order(points: 5)
    defense = defend_order(points: 10)

    @resolver.resolve(attacks: [attack], defenses: [defense])

    assert_equal 90, @attacker.life
  end

  def test_every_attacker_eats_the_full_counter_fire
    second_attacker = RobotWars::Robot.new(id: "second_attacker")
    first_attack = attack_order(points: 1)
    second_attack = attack_order(attacker: second_attacker, points: 1)
    defense = defend_order(points: 10)

    @resolver.resolve(attacks: [first_attack, second_attack], defenses: [defense])

    assert_equal 90, @attacker.life
    assert_equal 90, second_attacker.life
  end

  def test_a_defender_not_attacked_loses_only_the_1_point_premium
    defense = defend_order(points: 40)

    @resolver.resolve(attacks: [], defenses: [defense])

    assert_equal 99, @target.life
  end

  # --- Effects as narrated turn events --------------------------------

  def test_a_hit_narrates_the_square_the_victim_and_the_damage
    effects = @resolver.resolve(attacks: [attack_order(points: 12)], defenses: [])

    effect = effects.first
    assert_equal @square, effect.square
    assert_equal "attacker's attack on (4,4) was a HIT — target loses 12", effect.to_s
    assert_equal({ type: :ranged, kind: :hit, robot: "target", amount: 12, source: "attacker",
                   square: { x: 4, y: 4 } }, effect.to_h)
  end

  def test_a_miss_narrates_the_empty_square
    empty_square = RobotWars::Position.new(x: 0, y: 0)

    effects = @resolver.resolve(attacks: [attack_order(square: empty_square, points: 5)], defenses: [])

    effect = effects.first
    assert_equal "attacker's attack on (0,0) was a MISS", effect.to_s
    assert_nil effect.to_h.fetch(:robot)
  end

  def test_an_off_board_shot_narrates_the_self_inflicted_cost
    effects = @resolver.resolve(attacks: [attack_order(square: RobotWars::Position.new(x: -1, y: 3), points: 5)],
                                defenses: [])

    assert_equal "attacker's attack was OFF THE BOARD — loses 3", effects.first.to_s
  end

  def test_counter_fire_narrates_who_burned_whom
    effects = @resolver.resolve(attacks: [attack_order(points: 5)], defenses: [defend_order(points: 10)])

    counter = effects.find { |effect| effect.kind == :counter_fire }
    assert_equal "target's counter-fire hits attacker for 10", counter.to_s
    assert_equal({ type: :ranged, kind: :counter_fire, robot: "attacker", amount: 10, source: "target",
                   square: nil }, counter.to_h)
  end

  def test_an_unknown_effect_kind_refuses_to_narrate
    effect = RobotWars::RangedCombatResolver::Effect.new(kind: :bogus, robot: nil, amount: 0, source: nil)

    assert_raises(NoMatchingPatternError) { effect.to_s }
  end

  def test_an_unchallenged_defense_narrates_the_bracing_premium
    effects = @resolver.resolve(attacks: [], defenses: [defend_order(points: 10)])

    assert_equal "target defended against nothing — loses 1", effects.first.to_s
    assert_nil effects.first.to_h.fetch(:source)
  end

  private

  def attack_order(points:, attacker: @attacker, square: @square)
    RobotWars::RangedCombatResolver::AttackOrder.new(attacker: attacker, square: square, points: points)
  end

  def defend_order(points:, defender: @target)
    RobotWars::RangedCombatResolver::DefendOrder.new(defender: defender, points: points)
  end
end
