module RobotWars
  # Where each living robot stands right now (RULES.md 4: one robot per
  # square). Pure position bookkeeping — combat and ownership live in
  # ConflictResolver and Territory.
  class OccupancyMap
    def initialize
      @robot_by_position = {}
    end

    def place(robot, position)
      raise ArgumentError, "#{position} is already occupied" if occupied?(position)

      @robot_by_position[position] = robot
    end

    def vacate(position)
      @robot_by_position.delete(position)
    end

    def move(robot, from:, to:)
      raise ArgumentError, "#{robot} is not at #{from}" unless robot_at(from).equal?(robot)

      vacate(from)
      place(robot, to)
    end

    def robot_at(position)
      @robot_by_position[position]
    end

    def occupied?(position)
      @robot_by_position.key?(position)
    end

    def position_of(robot)
      @robot_by_position.key(robot)
    end

    def each_occupied(&block)
      return enum_for(:each_occupied) unless block

      @robot_by_position.each_pair(&block)
    end
  end
end
