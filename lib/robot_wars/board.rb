module RobotWars
  # Board geometry only (RULES.md 1: bounded board; 2: size set at game
  # start). Holds no robots or ownership — see OccupancyMap and Territory.
  class Board
    attr_reader :width, :height

    def initialize(width:, height:)
      raise ArgumentError, "width must be positive" unless width.positive?
      raise ArgumentError, "height must be positive" unless height.positive?

      @width = width
      @height = height
    end

    def on_board?(position)
      position.x.between?(0, width - 1) && position.y.between?(0, height - 1)
    end

    def neighbors_of(position)
      position.neighbors.select { |neighbor| on_board?(neighbor) }
    end

    # :reek:NestedIterators -- a 2D grid walk is inherently two loops deep.
    # :reek:UncommunicativeVariableName -- x and y ARE the communicative names for grid coordinates.
    def each_position
      return enum_for(:each_position) unless block_given?

      (0...width).each do |x|
        (0...height).each { |y| yield Position.new(x: x, y: y) }
      end
    end

    def random_position(random: Random.new)
      Position.new(x: random.rand(width), y: random.rand(height))
    end

    # `count` distinct squares (RULES.md 6: no two robots share a
    # starting square).
    # :reek:FeatureEnvy -- `squares` is a local snapshot of this board's own positions, not another object's data.
    def sample_positions(count, random: Random.new)
      squares = each_position.to_a
      raise ArgumentError, "cannot place #{count} robots on #{squares.size} squares" if count > squares.size

      squares.sample(count, random: random)
    end
  end
end
