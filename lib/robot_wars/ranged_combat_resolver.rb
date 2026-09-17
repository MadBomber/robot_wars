module RobotWars
  # Resolves ranged combat for one turn (RULES.md 26-32): attacks land
  # on whoever occupies the target square, defense is counter-fire
  # rather than a shield, and a defender nobody shot at still pays a
  # 1-point premium.
  class RangedCombatResolver
    AttackOrder = Data.define(:attacker, :square, :points)
    DefendOrder = Data.define(:defender, :points)
    Effect = Data.define(:kind, :robot, :amount, :source)

    def initialize(occupancy_map:, board:)
      @occupancy_map = occupancy_map
      @board = board
    end

    def resolve(attacks:, defenses:)
      defense_by_defender = defenses.to_h { |defense| [defense.defender, defense] }
      attacked_defenders = []

      effects = attacks.flat_map { |attack| resolve_attack(attack, defense_by_defender, attacked_defenders) }
      effects + unchallenged_effects(defenses, attacked_defenders)
    end

    private

    # :reek:FeatureEnvy -- an AttackOrder is pure data; resolving it needs this resolver's occupancy map and defense table.
    # :reek:TooManyStatements -- the rule 44/27/30 outcome ladder (off-board, miss, hit, counter-fire) is one linear pass.
    def resolve_attack(attack, defense_by_defender, attacked_defenders)
      return [off_board(attack)] unless @board.on_board?(attack.square)

      target = @occupancy_map.robot_at(attack.square)
      return [miss(attack)] unless target

      target.apply_damage(attack.points)
      effects = [Effect.new(kind: :hit, robot: target, amount: attack.points, source: attack.attacker)]

      defense = defense_by_defender[target]
      return effects unless defense

      attacked_defenders << defense.defender
      effects << counter_fire(attack.attacker, defense)
    end

    def miss(attack)
      Effect.new(kind: :miss, robot: nil, amount: attack.points, source: attack.attacker)
    end

    # Rule 44: shelling a square that is not on the board hits nothing
    # and costs the attacker half the committed points, rounded up so
    # no shot is free.
    def off_board(attack)
      attacker = attack.attacker
      penalty = (attack.points + 1) / 2
      attacker.apply_damage(penalty)
      Effect.new(kind: :off_board, robot: attacker, amount: penalty, source: attacker)
    end

    def counter_fire(attacker, defense)
      attacker.apply_damage(defense.points)
      Effect.new(kind: :counter_fire, robot: attacker, amount: defense.points, source: defense.defender)
    end

    def unchallenged_effects(defenses, attacked_defenders)
      defenses.reject { |defense| attacked_defenders.include?(defense.defender) }
              .map { |defense| unchallenged(defense) }
    end

    def unchallenged(defense)
      defense.defender.apply_damage(1)
      Effect.new(kind: :unchallenged, robot: defense.defender, amount: 1, source: nil)
    end
  end
end
