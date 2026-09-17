require "test_helper"

class RobotWars::RangedCombatResolverTest < Minitest::Test
  def setup
    @map = RobotWars::OccupancyMap.new
    @attacker = RobotWars::Robot.new(id: "attacker")
    @target = RobotWars::Robot.new(id: "target")
    @square = RobotWars::Position.new(x: 4, y: 4)
    @map.place(@target, @square)
    @resolver = RobotWars::RangedCombatResolver.new(occupancy_map: @map)
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

  private

  def attack_order(points:, attacker: @attacker, square: @square)
    RobotWars::RangedCombatResolver::AttackOrder.new(attacker: attacker, square: square, points: points)
  end

  def defend_order(points:, defender: @target)
    RobotWars::RangedCombatResolver::DefendOrder.new(defender: defender, points: points)
  end
end
