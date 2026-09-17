require "erb"

module RobotWars
  # Draws the game board as an SVG: the bounded grid (RULES.md 1) with
  # coordinate labels matching the transcript's (x,y) notation, and one
  # colored robot icon per occupied square. North is up: y grows
  # southward (Direction::NORTH is y-1), which is also SVG's natural
  # coordinate direction. The drawing has a transparent background —
  # whatever hosts it (SpectatorPage's dark theme) shows through.
  class SvgBoard
    # One icon to draw: a robot's id, its board square, and its color.
    Icon = Data.define(:id, :x, :y, :color)

    # Distinct hues that stay readable on a dark background; assigned to
    # robots by roster index, cycling when a match outgrows the palette.
    PALETTE = %w[#4fc3f7 #ff8a65 #81c784 #ba68c8 #ffd54f #f06292 #4db6ac #a1887f #90a4ae #dce775].freeze

    CELL        = 48 # px per board square
    MARGIN      = 28 # room for the coordinate labels (left and top)
    PAD         = 8  # right/bottom breathing room past the last grid line
    GRID_COLOR  = "#3d444d".freeze
    LABEL_COLOR = "#8b949e".freeze
    EYE_COLOR   = "#10151b".freeze
    FONT        = "ui-monospace, SFMono-Regular, Menlo, monospace".freeze

    def self.color_for(index) = PALETTE[index % PALETTE.size]

    # @param width [Integer] board squares across
    # @param height [Integer] board squares down
    # @param icons [Array<Icon>] the robots to draw
    def initialize(width:, height:, icons: [])
      @width = width
      @height = height
      @icons = icons
    end

    def to_s
      <<~SVG
        <svg xmlns="http://www.w3.org/2000/svg" width="#{pixel_width}" height="#{pixel_height}" viewBox="0 0 #{pixel_width} #{pixel_height}">
        #{grid_lines.join("\n")}
        #{axis_labels.join("\n")}
        #{@icons.map { |icon| icon_svg(icon) }.join("\n")}
        </svg>
      SVG
    end

    private

    def pixel_width  = MARGIN + (@width * CELL) + PAD
    def pixel_height = MARGIN + (@height * CELL) + PAD

    def grid_lines = vertical_lines + horizontal_lines

    # :reek:UncommunicativeVariableName -- x IS the communicative name for a grid coordinate.
    def vertical_lines
      bottom = MARGIN + (@height * CELL)
      (0..@width).map do |column|
        x = MARGIN + (column * CELL)
        %(<line x1="#{x}" y1="#{MARGIN}" x2="#{x}" y2="#{bottom}" stroke="#{GRID_COLOR}"/>)
      end
    end

    # :reek:UncommunicativeVariableName -- y IS the communicative name for a grid coordinate.
    def horizontal_lines
      right = MARGIN + (@width * CELL)
      (0..@height).map do |row|
        y = MARGIN + (row * CELL)
        %(<line x1="#{MARGIN}" y1="#{y}" x2="#{right}" y2="#{y}" stroke="#{GRID_COLOR}"/>)
      end
    end

    def axis_labels
      columns = (0...@width).map do |column|
        %(<text x="#{center(column)}" y="#{MARGIN - 8}" text-anchor="middle" #{label_font}>#{column}</text>)
      end
      rows = (0...@height).map do |row|
        %(<text x="#{MARGIN - 8}" y="#{center(row) + 4}" text-anchor="end" #{label_font}>#{row}</text>)
      end
      columns + rows
    end

    def label_font = %(font-family="#{FONT}" font-size="11" fill="#{LABEL_COLOR}")

    # The pixel center of board coordinate n along either axis.
    def center(coordinate) = MARGIN + (coordinate * CELL) + (CELL / 2)

    # A robot: antenna, round head, two eyes, and its id beneath — all in
    # the robot's own color so the icon alone identifies it.
    # :reek:FeatureEnvy -- drawing an icon means reading every one of its fields; there is nowhere better for this to live.
    def icon_svg(icon)
      icon => { x:, y:, color: }
      cx = center(x)
      cy = center(y)
      id = ERB::Util.html_escape(icon.id)
      <<~ICON.chomp
        <g>
        <title>#{id} at (#{x},#{y})</title>
        <line x1="#{cx}" y1="#{cy - 14}" x2="#{cx}" y2="#{cy - 20}" stroke="#{color}" stroke-width="2"/>
        <circle cx="#{cx}" cy="#{cy - 20}" r="2" fill="#{color}"/>
        <circle cx="#{cx}" cy="#{cy}" r="14" fill="#{color}"/>
        <circle cx="#{cx - 5}" cy="#{cy - 3}" r="2.5" fill="#{EYE_COLOR}"/>
        <circle cx="#{cx + 5}" cy="#{cy - 3}" r="2.5" fill="#{EYE_COLOR}"/>
        <text x="#{cx}" y="#{cy + 23}" text-anchor="middle" font-family="#{FONT}" font-size="9" fill="#{color}">#{id}</text>
        </g>
      ICON
    end
  end
end
