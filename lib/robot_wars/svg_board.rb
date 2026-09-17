require "erb"

module RobotWars
  # Draws the game board as an SVG: the bounded grid (RULES.md 1) with
  # coordinate labels matching the transcript's (x,y) notation, and one
  # colored robot icon per occupied square. The board is a standard
  # math plot (RULES.md 47): square (0,0) sits at the BOTTOM left and y
  # grows north, so board rows are flipped when mapped onto SVG's
  # top-down pixel rows — north stays up on screen. The drawing has a
  # transparent background — whatever hosts it (SpectatorPage's dark
  # theme) shows through.
  class SvgBoard
    # One icon to draw: a robot's id, its board square, its color, and
    # (when known) its life points to print beside it.
    Icon = Data.define(:id, :x, :y, :color, :life) do
      # :reek:UncommunicativeParameterName -- x and y ARE the communicative names for grid coordinates.
      def initialize(id:, x:, y:, color:, life: nil)
        super
      end
    end

    # One owned square to shade in its owner's color.
    OwnedSquare = Data.define(:x, :y, :color)

    # One attack to animate: a tracer from the attacker's square to the
    # shelled square, with a splash where it lands. `hit` brightens the
    # splash; a miss splashes dimly on the empty square. `counter` marks
    # counter-fire, animated on a delay so it reads as the response it
    # is: the attack lands first, then the return fire draws back.
    Shot = Data.define(:from_x, :from_y, :to_x, :to_y, :color, :hit, :counter) do
      # :reek:BooleanParameter -- hit and counter are recorded facts carried into the drawing, not behavior switches.
      def initialize(from_x:, from_y:, to_x:, to_y:, color:, hit: false, counter: false)
        super
      end
    end

    # Distinct hues that stay readable on a dark background; assigned to
    # robots by roster index, cycling when a match outgrows the palette.
    PALETTE = %w[#4fc3f7 #ff8a65 #81c784 #ba68c8 #ffd54f #f06292 #4db6ac #a1887f #90a4ae #dce775].freeze

    CELL        = 48 # px per board square
    MARGIN      = 28 # room for the coordinate labels (left and bottom)
    PAD         = 8  # top/right breathing room past the grid lines
    GRID_COLOR  = "#3d444d".freeze
    LABEL_COLOR = "#8b949e".freeze
    EYE_COLOR   = "#10151b".freeze
    FONT        = "ui-monospace, SFMono-Regular, Menlo, monospace".freeze

    def self.color_for(index) = PALETTE[index % PALETTE.size]

    # @param width [Integer] board squares across
    # @param height [Integer] board squares down
    # @param icons [Array<Icon>] the robots to draw
    # @param owned [Array<OwnedSquare>] territory to shade
    # @param shots [Array<Shot>] this turn's attacks to animate
    def initialize(width:, height:, icons: [], owned: [], shots: [])
      @width = width
      @height = height
      @icons = icons
      @owned = owned
      @shots = shots
    end

    def to_s
      <<~SVG
        <svg xmlns="http://www.w3.org/2000/svg" width="#{pixel_width}" height="#{pixel_height}" viewBox="0 0 #{pixel_width} #{pixel_height}">
        #{territory_rects.join("\n")}
        #{grid_lines.join("\n")}
        #{axis_labels.join("\n")}
        #{@icons.map { |icon| icon_svg(icon) }.join("\n")}
        #{shot_layer}
        </svg>
      SVG
    end

    private

    def pixel_width  = MARGIN + (@width * CELL) + PAD
    def pixel_height = PAD + (@height * CELL) + MARGIN

    # The grid hangs from a thin top pad; the label band sits BELOW it,
    # next to the origin row — matching rule 47's bottom-left (0,0).
    def grid_top    = PAD
    def grid_bottom = PAD + (@height * CELL)

    # Owned squares wear their owner's color as a translucent wash —
    # under the grid lines, so the lattice stays crisp.
    # :reek:UncommunicativeVariableName -- x and y ARE the communicative names for grid coordinates.
    def territory_rects
      @owned.map do |square|
        square => { x:, y:, color: }
        %(<rect x="#{MARGIN + (x * CELL)}" y="#{center_y(y) - (CELL / 2)}" ) +
          %(width="#{CELL}" height="#{CELL}" fill="#{color}" fill-opacity="0.22"/>)
      end
    end

    def grid_lines = vertical_lines + horizontal_lines

    # :reek:UncommunicativeVariableName -- x IS the communicative name for a grid coordinate.
    def vertical_lines
      (0..@width).map do |column|
        x = MARGIN + (column * CELL)
        %(<line x1="#{x}" y1="#{grid_top}" x2="#{x}" y2="#{grid_bottom}" stroke="#{GRID_COLOR}"/>)
      end
    end

    # :reek:UncommunicativeVariableName -- y IS the communicative name for a grid coordinate.
    def horizontal_lines
      right = MARGIN + (@width * CELL)
      (0..@height).map do |row|
        y = grid_top + (row * CELL)
        %(<line x1="#{MARGIN}" y1="#{y}" x2="#{right}" y2="#{y}" stroke="#{GRID_COLOR}"/>)
      end
    end

    def axis_labels
      columns = (0...@width).map do |column|
        %(<text x="#{center_x(column)}" y="#{grid_bottom + 18}" text-anchor="middle" #{label_font}>#{column}</text>)
      end
      rows = (0...@height).map do |row|
        %(<text x="#{MARGIN - 8}" y="#{center_y(row) + 4}" text-anchor="end" #{label_font}>#{row}</text>)
      end
      columns + rows
    end

    def label_font = %(font-family="#{FONT}" font-size="11" fill="#{LABEL_COLOR}")

    # The pixel center of a board column.
    def center_x(column) = MARGIN + (column * CELL) + (CELL / 2)

    # The pixel center of a board row — flipped, because board y grows
    # north (up) while SVG pixel y grows down.
    def center_y(row) = grid_top + ((@height - 1 - row) * CELL) + (CELL / 2)

    # A robot: antenna, round head, two eyes, and its id beneath — all in
    # the robot's own color so the icon alone identifies it.
    # :reek:FeatureEnvy -- drawing an icon means reading every one of its fields; there is nowhere better for this to live.
    def icon_svg(icon)
      icon => { x:, y:, color:, life: }
      cx = center_x(x)
      cy = center_y(y)
      id = ERB::Util.html_escape(icon.id)
      <<~ICON.chomp
        <g>
        <title>#{id} at (#{x},#{y})#{" — life #{life}" if life}</title>
        <line x1="#{cx}" y1="#{cy - 14}" x2="#{cx}" y2="#{cy - 20}" stroke="#{color}" stroke-width="2"/>
        <circle cx="#{cx}" cy="#{cy - 20}" r="2" fill="#{color}"/>
        <circle cx="#{cx}" cy="#{cy}" r="14" fill="#{color}"/>
        <circle cx="#{cx - 5}" cy="#{cy - 3}" r="2.5" fill="#{EYE_COLOR}"/>
        <circle cx="#{cx + 5}" cy="#{cy - 3}" r="2.5" fill="#{EYE_COLOR}"/>
        #{life_text(cx, cy, color, life)}<text x="#{cx}" y="#{cy + 23}" text-anchor="middle" font-family="#{FONT}" font-size="9" fill="#{color}">#{id}</text>
        </g>
      ICON
    end

    # Shots land ABOVE the icons — a tracer over the battlefield — and
    # bring their animation style along only when there is something to
    # animate. An off-board shot keeps its tracer (the viewBox clips it
    # at the edge) and its splash lands out of sight, which is the story.
    def shot_layer
      return "" if @shots.empty?

      ([shot_style] + @shots.map { |shot| shot_svg(shot) }).join("\n")
    end

    # The attack animation, embedded so it travels with the drawing: the
    # tracer draws itself toward the target, the splash pops on impact,
    # both hold for a beat, and both fade to nothing (fill-mode keeps
    # them invisible after). CSS animations restart whenever the SVG is
    # (re)inserted into the DOM, so every turn's board swap replays only
    # that turn's shots — no script required.
    def shot_style
      <<~CSS_SVG.chomp
        <style>
        .shot-line { stroke-dasharray: 1; stroke-dashoffset: 1;
                     animation: shot-draw .18s ease-out forwards, shot-fade .3s ease-in .9s forwards; }
        .shot-splash { opacity: 0; transform-box: fill-box; transform-origin: center;
                       animation: shot-splash 1s ease-out .18s forwards; }
        @keyframes shot-draw { to { stroke-dashoffset: 0; } }
        @keyframes shot-fade { to { opacity: 0; } }
        @keyframes shot-splash {
          0% { opacity: var(--splash-opacity, .9); transform: scale(.2); }
          35% { transform: scale(1); }
          70% { opacity: var(--splash-opacity, .9); transform: scale(1); }
          100% { opacity: 0; transform: scale(1.15); }
        }
        .shot-counter .shot-line { animation-delay: .5s, 1.3s; }
        .shot-counter .shot-splash { animation-delay: .68s; }
        </style>
      CSS_SVG
    end

    # :reek:FeatureEnvy -- drawing a shot means reading every one of its fields; see icon_svg.
    # :reek:UncommunicativeVariableName -- x2/y2 ARE the communicative names for the tracer's endpoint.
    def shot_svg(shot)
      shot => { from_x:, from_y:, to_x:, to_y:, color:, hit:, counter: }
      x2 = center_x(to_x)
      y2 = center_y(to_y)
      <<~SHOT.chomp
        <g#{' class="shot-counter"' if counter}>
        <line class="shot-line" x1="#{center_x(from_x)}" y1="#{center_y(from_y)}" x2="#{x2}" y2="#{y2}" pathLength="1" stroke="#{color}" stroke-width="2.5" stroke-linecap="round"/>
        <g class="shot-splash" style="--splash-opacity:#{hit ? '.9' : '.45'}">
        <circle cx="#{x2}" cy="#{y2}" r="18" fill="none" stroke="#{color}" stroke-width="2.5"/>
        <circle cx="#{x2}" cy="#{y2}" r="6" fill="#{color}"/>
        </g>
        </g>
      SHOT
    end

    # The life count in the cell's top-right corner, next to the head.
    # :reek:UtilityFunction :reek:LongParameterList -- four scalars of one icon's drawing state; private plumbing.
    def life_text(cx, cy, color, life)
      return "" unless life

      %(<text x="#{cx + 22}" y="#{cy - 13}" text-anchor="end" font-family="#{FONT}" font-size="10" ) +
        %(font-weight="600" fill="#{color}">#{life}</text>\n)
    end
  end
end
