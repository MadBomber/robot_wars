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

    # Advances every square's occupation streak from who is standing
    # there this turn, claiming ownership on the 3rd consecutive turn.
    def tick!(occupancy_map)
      current_by_position = occupancy_map.each_occupied.to_h

      stale_positions(current_by_position).each { |position| @streak_by_position.delete(position) }
      current_by_position.each_pair { |position, robot| record_occupation(position, robot) }
    end

    private

    def stale_positions(current_by_position)
      @streak_by_position.keys.reject do |position|
        current_by_position[position] == @streak_by_position[position].fetch(:robot)
      end
    end

    def record_occupation(position, robot)
      streak = (@streak_by_position[position] ||= { robot: robot, count: 0 })
      streak[:count] += 1
      claim!(position, robot) if streak.fetch(:count) >= TURNS_TO_OWN_BY_OCCUPATION
    end
  end
end
