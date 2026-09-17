module RobotWars
  # Determines a move's destination and legality (RULES.md 9 and 21).
  # Board boundaries and rival ownership make a destination illegal;
  # another robot simply standing there does not — that's a conflict,
  # not an illegal move.
  class MoveResolver
    Result = Data.define(:legal, :destination)

    def initialize(board:, territory:)
      @board = board
      @territory = territory
    end

    def resolve(robot, origin, direction)
      destination = origin + direction

      if legal_destination?(destination, robot)
        Result.new(legal: true, destination: destination)
      else
        Result.new(legal: false, destination: origin)
      end
    end

    private

    def legal_destination?(destination, robot)
      @board.on_board?(destination) && !@territory.owned_by_other?(destination, robot)
    end
  end
end
