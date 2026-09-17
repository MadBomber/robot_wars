require "erb"

module RobotWars
  # The browser spectator's page: a dark-themed HTML document holding
  # the SvgBoard drawing and a legend mapping each robot's color to its
  # id, life, and square. This is the referee's God view — it shows
  # everything rule 33's sensing hides from the players, and must never
  # feed back into them.
  #
  # The page captures the game's state at construction time, so it can
  # be served from another thread while the match mutates the game.
  class SpectatorPage
    # One robot's snapshot: identity, vitals, square, and legend color.
    Entry = Data.define(:id, :life, :x, :y, :color)

    def initialize(game:)
      board = game.board
      @width = board.width
      @height = board.height
      @turn = game.turn_number
      @entries = game.robots.each_with_index.map do |robot, index|
        position = game.occupancy.position_of(robot)
        Entry.new(id: robot.id, life: robot.life, x: position.x, y: position.y, color: SvgBoard.color_for(index))
      end
    end

    def to_html
      <<~HTML
        <!DOCTYPE html>
        <html lang="en">
        <head>
        <meta charset="utf-8">
        <title>RobotWars</title>
        <style>#{style}</style>
        </head>
        <body>
        <h1>RobotWars</h1>
        <p class="status">#{status_line}</p>
        <div class="arena">
        #{board_svg.chomp}
        <table class="legend">
        <tr><th></th><th>warrior</th><th>life</th><th>square</th></tr>
        #{legend_rows.join("\n")}
        </table>
        </div>
        </body>
        </html>
      HTML
    end

    private

    def status_line
      moment = @turn.zero? ? "initial placement" : "turn #{@turn}"
      "#{@entries.size} warriors on a #{@width}x#{@height} board &mdash; #{moment}"
    end

    def board_svg
      icons = @entries.map { |entry| icon_for(entry) }
      SvgBoard.new(width: @width, height: @height, icons: icons).to_s
    end

    # :reek:UtilityFunction :reek:FeatureEnvy -- converting an Entry means reading its fields; private page plumbing.
    def icon_for(entry)
      entry => { id:, x:, y:, color: }
      SvgBoard::Icon.new(id: id, x: x, y: y, color: color)
    end

    def legend_rows = @entries.map { |entry| legend_row(entry) }

    # :reek:UtilityFunction :reek:FeatureEnvy -- rendering an Entry means reading its fields; private page plumbing.
    def legend_row(entry)
      entry => { id:, life:, x:, y:, color: }
      swatch = %(<td><span class="swatch" style="background:#{color}"></span></td>)
      cells = [ERB::Util.html_escape(id), life, "(#{x},#{y})"]
      "<tr>#{swatch}#{cells.map { |cell| "<td>#{cell}</td>" }.join}</tr>"
    end

    def style
      <<~CSS.chomp
        body { background: #0d1117; color: #e6edf3; margin: 2rem;
               font-family: ui-monospace, SFMono-Regular, Menlo, monospace; }
        h1 { font-size: 1.4rem; margin: 0 0 .25rem; }
        .status { color: #8b949e; margin: 0 0 1.5rem; }
        .arena { display: flex; gap: 2.5rem; align-items: flex-start; flex-wrap: wrap; }
        .legend { border-collapse: collapse; }
        .legend th, .legend td { text-align: left; padding: .3rem .8rem .3rem 0; }
        .legend th { color: #8b949e; font-weight: normal; }
        .swatch { display: inline-block; width: .85em; height: .85em; border-radius: 50%; }
      CSS
    end
  end
end
