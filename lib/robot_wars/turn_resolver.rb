module RobotWars
  # Runs one full turn end to end (RULES.md rule 40): the movement
  # economy, square conflicts — including cascading return conflicts and
  # displacement-or-death — ranged combat, death processing, and
  # occupation-streak ticking.
  #
  # A returning loser (rule 17) is sent to the square it started the
  # turn on. Two cases the rules leave implicit are resolved here and
  # flagged for confirmation (see notes.md): a robot that never left its
  # square (its "origin" IS the square it just lost) has nowhere
  # meaningful to return to, so it goes straight to displacement rather
  # than re-fighting the robot that just beat it; and each robot's own
  # defeat count (not a per-event count) is what caps a chain at two
  # losses, so displacing a robot only starts THAT robot's own count.
  class TurnResolver
    Report = Data.define(:deaths, :ranged_effects)

    def initialize(board:, occupancy:, territory:, roll_generator: RollGenerator.new, random: Random.new,
                   move_resolver: nil, conflict_resolver: nil, illegal_move_resolver: nil)
      @board = board
      @occupancy = occupancy
      @territory = territory
      @random = random
      @move_resolver = move_resolver || MoveResolver.new(board: board, territory: territory)
      @conflict_resolver = conflict_resolver || ConflictResolver.new(roll_generator: roll_generator)
      @illegal_move_resolver = illegal_move_resolver || IllegalMoveResolver.new(roll_generator: roll_generator)
    end

    # actions: Hash{Robot => Action}, exactly one entry per living robot
    # on the board (rule 8).
    def resolve!(actions)
      origins = actions.keys.to_h { |robot| [robot, @occupancy.position_of(robot)] }

      destinations = apply_movement_economy(actions)
      settled, eliminated = resolve_square_conflicts(destinations, origins)
      commit_occupancy(settled)

      ranged_effects = resolve_ranged_combat(actions)
      deaths = process_deaths(eliminated)

      @territory.tick!(@occupancy)

      Report.new(deaths: deaths, ranged_effects: ranged_effects)
    end

    private

    # --- Movement and the life-point economy (rules 9-11, 21) ---------

    def apply_movement_economy(actions)
      actions.to_h { |robot, action| [robot, intended_square(robot, action)] }
    end

    def intended_square(robot, action)
      origin = @occupancy.position_of(robot)
      return resolve_move(robot, origin, action.direction) if action.move?

      robot.heal(1) if action.stay?
      origin
    end

    def resolve_move(robot, origin, direction)
      result = @move_resolver.resolve(robot, origin, direction)
      unless result.legal
        @illegal_move_resolver.resolve(robot)
        return origin
      end

      robot.apply_damage(1)
      result.destination
    end

    # --- Square conflicts, cascading returns, displacement (13-20) ----

    def resolve_square_conflicts(destinations, origins)
      settled = {}
      eliminated = []
      defeats = Hash.new(0)
      queue = []

      groups_by_square(destinations).each { |square, contenders| settle(square, contenders, settled, defeats, queue) }

      until queue.empty?
        robot, lost_at = queue.shift.values_at(:robot, :lost_at)
        return_home(robot, lost_at, origins, settled, defeats, eliminated, queue)
      end

      [settled, eliminated]
    end

    def groups_by_square(destinations)
      groups = Hash.new { |hash, square| hash[square] = [] }
      destinations.each { |robot, square| groups[square] << robot }
      groups
    end

    # Resolves one square's contenders: the sole robot, or the winner of
    # a conflict, settles there and (on conquest) claims it; every loser
    # is queued to attempt its own return.
    def settle(square, contenders, settled, defeats, queue)
      if contenders.one?
        settled[square] = contenders.first
        return
      end

      result = @conflict_resolver.resolve(contenders)

      if result.winner
        settled[square] = result.winner
        @territory.claim!(square, result.winner)
      else
        settled.delete(square)
      end

      result.losers.each do |loser|
        defeats[loser] += 1
        queue << { robot: loser, lost_at: square }
      end
    end

    def return_home(robot, lost_at, origins, settled, defeats, eliminated, queue)
      home = origins[robot]

      if home == lost_at || defeats[robot] >= 2
        displace_or_eliminate(robot, lost_at, settled, eliminated)
        return
      end

      occupant = settled[home]
      if occupant.nil?
        settled[home] = robot
        return
      end

      settle(home, [robot, occupant], settled, defeats, queue)
    end

    def displace_or_eliminate(robot, near, settled, eliminated)
      candidates = @board.neighbors_of(near).reject do |square|
        settled.key?(square) || @territory.owned_by_other?(square, robot)
      end

      if candidates.empty?
        robot.eliminate!
        eliminated << robot
      else
        settled[candidates.sample(random: @random)] = robot
      end
    end

    def commit_occupancy(settled)
      @occupancy.each_occupied.to_a.each { |square, _robot| @occupancy.vacate(square) }
      settled.each { |square, robot| @occupancy.place(robot, square) }
    end

    # --- Ranged combat (26-32) -----------------------------------------

    def resolve_ranged_combat(actions)
      attacks = actions.filter_map { |robot, action| build_attack(robot, action) if action.attack? }
      defenses = actions.filter_map { |robot, action| build_defense(robot, action) if action.defend? }

      RangedCombatResolver.new(occupancy_map: @occupancy).resolve(attacks: attacks, defenses: defenses)
    end

    def build_attack(robot, action)
      RangedCombatResolver::AttackOrder.new(attacker: robot, square: action.square, points: action.points)
    end

    def build_defense(robot, action)
      RangedCombatResolver::DefendOrder.new(defender: robot, points: action.points)
    end

    # --- Death processing (25, 36-38) -----------------------------------

    def process_deaths(already_eliminated)
      newly_dead = @occupancy.each_occupied.to_a.filter_map { |_square, robot| robot if robot.dead? }
      deaths = (already_eliminated + newly_dead).uniq

      deaths.each do |robot|
        position = @occupancy.position_of(robot)
        @occupancy.vacate(position) if position
        @territory.release!(robot)
      end

      deaths
    end
  end
end
