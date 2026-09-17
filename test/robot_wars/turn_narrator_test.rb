require "test_helper"

class RobotWars::TurnNarratorTest < Minitest::Test
  def setup
    @alpha = RobotWars::Robot.new(id: "alpha")
    @bravo = RobotWars::Robot.new(id: "bravo", life: 40)
  end

  def test_narrates_a_full_turn_in_rule_40_phase_order
    declared_a = declared(@alpha, RobotWars::Action.move(RobotWars::Direction::EAST), pos(0, 1))
    declared_b = declared(@bravo, RobotWars::Action.stay, pos(1, 1))
    solo = RobotWars::TurnResolver::SoloConflict.new(robot: @alpha, roll: 6)
    conflict = RobotWars::TurnResolver::Conflict.new(square: pos(1, 1), robots: [@alpha, @bravo],
                                                     roll: 5, winner: @alpha, losers: [@bravo])
    displaced = RobotWars::TurnResolver::Displaced.new(robot: @bravo, from: pos(1, 1), to: pos(2, 2))
    effect = RobotWars::RangedCombatResolver::Effect.new(kind: :hit, robot: @bravo, amount: 7,
                                                         source: @alpha, square: pos(1, 1))
    death = RobotWars::TurnResolver::Death.new(robot: @bravo)
    claim = RobotWars::TurnResolver::Claim.new(robot: @alpha, square: pos(1, 1))

    narrator = RobotWars::TurnNarrator.new(report: report(
      events: [declared_a, declared_b, solo, conflict, claim, displaced, effect, death],
      deaths: [@bravo], ranged_effects: [effect],
      conflicts: [conflict], solo_conflicts: [solo], claims: [claim]
    ))

    assert_equal [
      "alpha: MOVE east to (1,1) — now owns (1,1)",
      "bravo: STAY at (1,1)",
      "solo conflict: alpha — roll 6, no movement",
      "conflict at (1,1): alpha vs bravo — roll 5, alpha takes the square",
      "bravo is displaced to (2,2)",
      "alpha's attack on (1,1) was a HIT — bravo loses 7",
      "bravo is destroyed"
    ], narrator.lines
  end

  def test_a_quiet_turn_narrates_only_the_declarations
    narrator = RobotWars::TurnNarrator.new(report: report(
      events: [declared(@alpha, RobotWars::Action.stay, pos(0, 0))]
    ))

    assert_equal ["alpha: STAY at (0,0)"], narrator.lines
  end

  private

  def pos(x, y) = RobotWars::Position.new(x: x, y: y)

  def declared(robot, action, origin)
    RobotWars::TurnResolver::Declared.new(robot: robot, action: action, origin: origin)
  end

  def report(events:, deaths: [], ranged_effects: [], conflicts: [], solo_conflicts: [], claims: [])
    RobotWars::TurnResolver::Report.new(events: events, deaths: deaths, ranged_effects: ranged_effects,
                                        conflicts: conflicts, solo_conflicts: solo_conflicts, claims: claims)
  end
end
