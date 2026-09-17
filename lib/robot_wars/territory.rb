module RobotWars
  # Square ownership (RULES.md 22-25). Ownership comes from conquest
  # (#claim!, called by whoever resolves square conflicts) or from
  # occupation (#tick!, three consecutive turns per rule 23), and is
  # released when the owner dies (#release!).
  class Territory
    TURNS_TO_OWN_BY_OCCUPATION = 3

    def initialize
      @owner_by_position = {}
      @streak_by_position = {}
    end

    def owner_of(position)
      @owner_by_position[position]
    end

    def owned?(position)
      @owner_by_position.key?(position)
    end

    def owned_by?(position, robot)
      owner_of(position) == robot
    end

    def owned_by_other?(position, robot)
      owned?(position) && !owned_by?(position, robot)
    end

    def claim!(position, robot)
      @owner_by_position[position] = robot
    end

    def release!(robot)
      @owner_by_position.delete_if { |_position, owner| owner == robot }
    end

    def each_owned(&block)
      return enum_for(:each_owned) unless block

      @owner_by_position.each_pair(&block)
    end

    # Advances every square's occupation streak from who is standing
    # there this turn, claiming ownership on the 3rd consecutive turn.
    # Returns the squares that BECAME owned on this tick as
    # {position => robot} — squares the robot already owned don't
    # reappear on later ticks.
    def tick!(occupancy_map)
      current_by_position = occupancy_map.each_occupied.to_h

      stale_positions(current_by_position).each { |position| @streak_by_position.delete(position) }
      current_by_position.filter_map { |position, robot| record_occupation(position, robot) }.to_h
    end

    private

    def stale_positions(current_by_position)
      @streak_by_position.keys.reject do |position|
        current_by_position[position] == @streak_by_position[position].fetch(:robot)
      end
    end

    # Advances the square's streak; returns [position, robot] when the
    # occupation just turned into NEW ownership, nil otherwise.
    def record_occupation(position, robot)
      streak = (@streak_by_position[position] ||= { robot: robot, count: 0 })
      streak[:count] += 1
      return nil if streak.fetch(:count) < TURNS_TO_OWN_BY_OCCUPATION || owned_by?(position, robot)

      claim!(position, robot)
      [position, robot]
    end
  end
end
