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
  # :reek:TooManyMethods -- one small private method per rule 40 step and sub-case; consolidation would bury the sequence.
  class TurnResolver
    Report = Data.define(:deaths, :ranged_effects, :conflicts, :solo_conflicts, :claims) do
      # Battleship-style feedback for an attacker: :hit when this
      # robot's attack this turn found a robot on the target square,
      # :miss when it found the square empty, nil when it didn't attack.
      # Counter-fire and unchallenged-defense effects don't count — they
      # aren't the robot's own shot.
      # :reek:ControlParameter -- `robot` is the query subject being looked up, not a behavior switch.
      # :reek:FeatureEnvy -- `effect` is the block's own search variable; there is no better home for a Report query.
      def attack_outcome_for(robot)
        ranged_effects.find { |effect| effect.source == robot && %i[hit miss off_board].include?(effect.kind) }&.kind
      end

      # The squares this robot NEWLY came to own this turn — by conquest
      # or by completing a 3-turn occupation streak. Squares it already
      # owned are never repeated.
      def claimed_squares_for(robot)
        claims.select { |claim| claim.robot == robot }.map(&:square)
      end
    end

    # One square becoming newly owned during the turn (rules 22-23).
    Claim = Data.define(:robot, :square)

    # One resolved square conflict (rules 13-16), kept on the Report so a
    # match transcript can say what happened, not just the resulting life
    # totals. `winner` is nil on a tie; `winner_died` marks a winner the
    # roll itself killed (rule 46: it wins nothing).
    Conflict = Data.define(:square, :robots, :roll, :winner, :losers, :winner_died) do
      # :reek:BooleanParameter -- winner_died is a recorded fact on an event value, not a behavior switch.
      def initialize(square:, robots:, roll:, winner:, losers:, winner_died: false)
        super
      end

      def to_s
        "conflict at (#{square.x},#{square.y}): #{robots.map(&:id).join(' vs ')} — roll #{roll}, #{outcome}"
      end

      def outcome
        if winner_died then "#{winner.id} wins but dies"
        elsif winner   then "#{winner.id} takes the square"
        else                "tie, everyone loses"
        end
      end
    end

    # One rule 21 solo conflict — an invalid action or illegal move
    # punished with a random hit and no movement.
    SoloConflict = Data.define(:robot, :roll) do
      def to_s = "solo conflict: #{robot.id} — roll #{roll}, no movement"
    end

    # :reek:ControlParameter -- `x || Default.new` is an injectable-collaborator fallback, not behavior selection.
    def initialize(board:, occupancy:, territory:, roll_generator: RollGenerator.new, random: Random.new,
                   move_resolver: nil, conflict_resolver: nil, illegal_move_resolver: nil)
      @board = board
      @occupancy = occupancy
      @territory = territory
      @random = random
      @move_resolver = move_resolver || MoveResolver.new(board: board, territory: territory)
      @conflict_resolver = conflict_resolver || ConflictResolver.new(roll_generator: roll_generator)
      @illegal_move_resolver = illegal_move_resolver || IllegalMoveResolver.new(roll_generator: roll_generator)
      @conflicts = []
      @solo_conflicts = []
      @claims = []
    end

    # actions: Hash{Robot => Action}, exactly one entry per living robot
    # on the board (rule 8).
    # :reek:TooManyStatements -- the rule 40 turn sequence, one linear step per phase; splitting it would hide the order.
    def resolve!(actions)
      reset_turn_log
      actions = actions.to_h { |robot, action| [robot, effective_action(robot, action)] }
      origins = actions.keys.to_h { |robot| [robot, @occupancy.position_of(robot)] }

      destinations = apply_movement_economy(actions)
      eliminated = drop_movement_deaths(destinations)
      settled = resolve_square_conflicts(destinations, origins, eliminated)
      commit_occupancy(settled)

      ranged_effects = resolve_ranged_combat(actions)
      deaths = process_deaths(eliminated)

      @territory.tick!(@occupancy).each { |square, robot| @claims << Claim.new(robot: robot, square: square) }

      Report.new(deaths: deaths, ranged_effects: ranged_effects,
                 conflicts: @conflicts, solo_conflicts: @solo_conflicts, claims: @claims)
    end

    private

    # The per-turn event log the Report is built from, emptied at the
    # top of every resolve!.
    def reset_turn_log
      @conflicts = []
      @solo_conflicts = []
      @claims = []
    end

    # Rule 43: committing more points than the robot's current life —
    # measured at declaration time, before any of the turn's effects —
    # as an attack or a defense is a pilot error, treated exactly like
    # an unparsable reply (rule 41).
    # :reek:FeatureEnvy -- judging the action's commitment is this method's whole job; the Action is pure data.
    def effective_action(robot, action)
      return Action.invalid if (action.attack? || action.defend?) && action.points > robot.life

      action
    end

    # --- Movement and the life-point economy (rules 9-11, 21) ---------

    def apply_movement_economy(actions)
      actions.to_h { |robot, action| [robot, intended_square(robot, action)] }
    end

    # :reek:FeatureEnvy -- dispatching on the action's type is this method's whole job; the Action is pure data.
    def intended_square(robot, action)
      origin = @occupancy.position_of(robot)
      return resolve_move(robot, origin, action.direction) if action.move?

      if action.invalid?
        punish_solo_conflict(robot)
      elsif action.stay?
        robot.heal(1)
      end

      origin
    end

    def resolve_move(robot, origin, direction)
      result = @move_resolver.resolve(robot, origin, direction)
      unless result.legal
        punish_solo_conflict(robot)
        return origin
      end

      robot.apply_damage(1)
      result.destination
    end

    def punish_solo_conflict(robot)
      result = @illegal_move_resolver.resolve(robot)
      @solo_conflicts << SoloConflict.new(robot: robot, roll: result.roll)
    end

    # A robot can die during the movement phase itself — a solo-conflict
    # roll, or the -1 move cost, on low life. Dead robots take no
    # further part in the turn (rule 46), so they leave the board here.
    def drop_movement_deaths(destinations)
      destinations.keys.select(&:dead?).each { |robot| destinations.delete(robot) }
    end

    # --- Square conflicts, cascading returns, displacement (13-20) ----

    # :reek:TooManyStatements -- initial-conflict pass plus the cascading-return queue drain belong together (rules 13-20).
    def resolve_square_conflicts(destinations, origins, eliminated)
      settled = {}
      defeats = Hash.new(0)
      queue = []

      groups_by_square(destinations).each { |square, contenders| settle(square, contenders, settled, defeats, queue, eliminated) }

      until queue.empty?
        robot, lost_at = queue.shift.values_at(:robot, :lost_at)
        return_home(robot, lost_at, origins, settled, defeats, eliminated, queue)
      end

      settled
    end

    def groups_by_square(destinations)
      groups = Hash.new { |hash, square| hash[square] = [] }
      destinations.each { |robot, square| groups[square] << robot }
      groups
    end

    # Resolves one square's contenders: the sole robot, or the winner of
    # a conflict, settles there and (on conquest) claims it; every
    # surviving loser is queued to attempt its own return. The roll can
    # kill (rule 36), and a dead robot fights no further and wins
    # nothing (rule 46) — a dead winner conquers no square, a dead loser
    # never goes home.
    # :reek:TooManyStatements -- fight, log, settle-or-vacate, queue losers: one linear pass per contested square.
    # :reek:LongParameterList -- the cascade's working state is one turn's transient data (see return_home).
    def settle(square, contenders, settled, defeats, queue, eliminated)
      if contenders.one?
        settled[square] = contenders.first
        return
      end

      @conflict_resolver.resolve(contenders) => { winner:, losers:, roll: }
      winner_died = winner ? winner.dead? : false
      @conflicts << Conflict.new(square: square, robots: contenders, roll: roll,
                                 winner: winner, losers: losers, winner_died: winner_died)

      if winner && !winner_died
        settled[square] = winner
        record_conquest(square, winner)
      else
        eliminated << winner if winner_died
        settled.delete(square)
      end

      losers.each do |loser|
        next eliminated << loser if loser.dead?

        defeats[loser] += 1
        queue << { robot: loser, lost_at: square }
      end
    end

    # A conquest is always NEW ownership — no robot can legally enter a
    # square someone else owns (and displacement avoids them too), so a
    # conflict never happens on a square its winner already holds.
    def record_conquest(square, winner)
      @territory.claim!(square, winner)
      @claims << Claim.new(robot: winner, square: square)
    end

    # :reek:LongParameterList -- the cascade's working state (origins/settled/defeats/eliminated/queue) is one
    # turn's transient data; promoting it to ivars or a context object would outlive its single resolve! pass.
    # :reek:TooManyStatements -- the four return outcomes of rules 17-20 (displace, rival-owned home, free home, fight) in order.
    def return_home(robot, lost_at, origins, settled, defeats, eliminated, queue)
      home = origins[robot]

      if home == lost_at || defeats[robot] >= 2
        displace_or_eliminate(robot, lost_at, settled, eliminated)
        return
      end

      # An origin square a rival now owns cannot be re-entered (rules
      # 18/24, ruled 2026-09-17): the returner retreats to a free
      # neighbor or dies, exactly like a second defeat.
      if @territory.owned_by_other?(home, robot)
        displace_or_eliminate(robot, home, settled, eliminated)
        return
      end

      occupant = settled[home]
      if occupant.nil?
        settled[home] = robot
        return
      end

      settle(home, [robot, occupant], settled, defeats, queue, eliminated)
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

    # Only the living fight at range (rule 46): a robot killed in the
    # movement or conflict phases neither fires its attack nor
    # counter-fires its defense.
    def resolve_ranged_combat(actions)
      attacks = actions.filter_map { |robot, action| build_attack(robot, action) if action.attack? && robot.alive? }
      defenses = actions.filter_map { |robot, action| build_defense(robot, action) if action.defend? && robot.alive? }

      RangedCombatResolver.new(occupancy_map: @occupancy, board: @board).resolve(attacks: attacks, defenses: defenses)
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
