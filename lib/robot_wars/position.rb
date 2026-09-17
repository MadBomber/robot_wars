module RobotWars
  # A single square's coordinates. Values only — no board-bounds checking
  # here; see Board#on_board?.
  Position = Data.define(:x, :y) do
    def +(other)
      Position.new(x: x + other.x, y: y + other.y)
    end

    def neighbors
      Direction::OFFSETS.map { |offset| self + offset }
    end
  end
end
