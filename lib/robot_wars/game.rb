module RobotWars
  # A full match: setup, one turn at a time, until it ends (rule 39).
  class Game
    attr_reader :board, :occupancy, :territory, :turn_number

    # The default roll generator is derived from the SAME `random`, so a
    # seeded match reproduces its conflict rolls too — not just its
    # placement and displacement picks.
    # :reek:ControlParameter -- `x || Default.new` is an injectable-collaborator fallback, not behavior selection.
    def initialize(board:, roll_generator: nil, random: Random.new)
      @board = board
      @occupancy = OccupancyMap.new
      @territory = Territory.new
      @robots = []
      @turn_number = 0
      @turn_resolver = TurnResolver.new(
        board: board, occupancy: @occupancy, territory: @territory,
        roll_generator: roll_generator || RollGenerator.new(random: random), random: random
      )
    end

    # Places robots on distinct random squares (rule 6), each starting
    # with `life` points (rule 5's 100 unless the match says otherwise).
    def self.start(board:, robot_ids:, life: Robot::STARTING_LIFE, roll_generator: nil, random: Random.new)
      game = new(board: board, roll_generator: roll_generator, random: random)
      positions = board.sample_positions(robot_ids.size, random: random)

      robot_ids.zip(positions).each { |id, position| game.add_robot(Robot.new(id: id, life: life), position) }
      game
    end

    def add_robot(robot, position)
      @occupancy.place(robot, position)
      @robots << robot
      self
    end

    def robots
      @robots.dup
    end

    def robot(id)
      @robots.find { |robot| robot.id == id }
    end

    def alive_robots
      @robots.select(&:alive?)
    end

    # Removes a robot from the match outside normal turn resolution —
    # the rule 45 "brain dead" case: a pilot that failed to answer in
    # time. The robot dies; its square is vacated and its territory
    # released, exactly as a mid-turn death would be handled.
    def remove_robot(robot)
      robot.eliminate!
      position = @occupancy.position_of(robot)
      @occupancy.vacate(position) if position
      @territory.release!(robot)
      @robots.delete(robot)
      robot
    end

    def over?
      alive_robots.size <= 1
    end

    def winner
      over? ? alive_robots.first : nil
    end

    def tie?
      over? && alive_robots.empty?
    end

    # actions: Hash{Robot => Action}, exactly one entry per living robot.
    def play_turn(actions)
      raise ArgumentError, "the game is already over" if over?

      validate_actions!(actions)
      @turn_number += 1

      report = @turn_resolver.resolve!(actions)
      @robots -= report.deaths
      report
    end

    private

    def validate_actions!(actions)
      provided = actions.keys
      return if (alive_robots - provided).empty? && (provided - alive_robots).empty?

      raise ArgumentError, "expected exactly one action per living robot"
    end
  end
end
