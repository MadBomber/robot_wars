require "erb"

module RobotWars
  # The browser spectator's page: a dark-themed HTML document holding
  # the SvgBoard drawing (icons, life numbers, territory shading), a
  # legend mapping each robot's color to its id, life, and square, and
  # a play-by-play log fed live over SSE. This is the referee's God
  # view — it shows everything rule 33's sensing hides from the
  # players, and must never feed back into them.
  #
  # The page captures the game's state at construction time, so its
  # fragments can be served or published from another thread while the
  # match mutates the game. `roster` is the match's ORIGINAL robot
  # list: colors are assigned by roster index so they stay stable as
  # robots die, and the fallen keep a (dimmed) legend row.
  class SpectatorPage
    # One robot's snapshot; x/y are nil once it has no square.
    Entry = Data.define(:id, :life, :x, :y, :color, :alive)

    # `events` is the turn's typed event stream (TurnResolver's Report#events);
    # the page mines it for the attacks to animate on the board.
    # :reek:ControlParameter -- `roster || game.robots` is an injectable-collaborator fallback, not behavior selection.
    def initialize(game:, roster: nil, events: [])
      board = game.board
      @width = board.width
      @height = board.height
      @turn = game.turn_number
      @tie = game.tie?
      @winner = game.winner&.id
      @entries = (roster || game.robots).each_with_index.map { |robot, index| entry_for(game, robot, index) }
      color_by_id = @entries.to_h { |entry| [entry.id, entry.color] }
      @owned = game.territory.each_owned.map do |position, robot|
        SvgBoard::OwnedSquare.new(x: position.x, y: position.y, color: color_by_id.fetch(robot.id))
      end
      @shots = shots_from(events, color_by_id)
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
        <p class="status" id="status">#{status_text}</p>
        <div class="arena">
        <div id="board">
        #{board_svg.chomp}
        </div>
        <div class="side">
        <table class="legend" id="legend">
        #{legend_html.chomp}
        </table>
        <div class="log" id="log"></div>
        </div>
        </div>
        <script>#{script}</script>
        </body>
        </html>
      HTML
    end

    def status_text
      if @tie             then "tie — the last warriors fell together on turn #{@turn}"
      elsif @winner       then "winner: #{@winner} after #{@turn} turns"
      elsif @turn.zero?   then "#{@entries.size} warriors on a #{@width}x#{@height} board — initial placement"
      else                     "turn #{@turn} — #{@entries.count(&:alive)} of #{@entries.size} warriors standing"
      end
    end

    def board_svg
      icons = @entries.select(&:alive).map do |entry|
        entry => { id:, life:, x:, y:, color: }
        SvgBoard::Icon.new(id: id, x: x, y: y, color: color, life: life)
      end
      SvgBoard.new(width: @width, height: @height, icons: icons, owned: @owned, shots: @shots).to_s
    end

    def legend_html
      rows = ["<tr><th></th><th>warrior</th><th>life</th><th>square</th></tr>"]
      rows.concat(@entries.map { |entry| legend_row(entry) })
      "#{rows.join("\n")}\n"
    end

    private

    # A robot with no square is out of the match — dead, or removed as
    # brain dead — and keeps a dimmed legend row.
    def entry_for(game, robot, index)
      position = game.occupancy.position_of(robot)
      Entry.new(id: robot.id, life: robot.life, x: position&.x, y: position&.y,
                color: SvgBoard.color_for(index), alive: !position.nil?)
    end

    # Each aimed attack (hit, miss, or off the board) becomes a SvgBoard
    # Shot in the attacker's color: the tracer runs from the square the
    # attacker declared its action on to the shelled square. Counter-fire
    # is the same tracer in reverse — defender back to attacker, in the
    # DEFENDER's color, on a delay so it reads as the response — with
    # both squares looked up from the declarations (neither an attacker
    # nor a defender moves). Only the unchallenged-defense premium aims
    # nowhere and draws nothing.
    # :reek:UtilityFunction :reek:FeatureEnvy -- pure event-stream-to-drawing translation; private page plumbing.
    def shots_from(events, color_by_id)
      hashes = events.map(&:to_h)
      origins = {}
      hashes.each do |hash|
        case hash
        in { type: :action, robot:, origin: { x:, y: } } then origins[robot] = [x, y]
        else nil
        end
      end
      hashes.filter_map { |hash| shot_for(hash, origins, color_by_id) }
    end

    # :reek:UtilityFunction -- see shots_from.
    def shot_for(hash, origins, color_by_id)
      case hash
      in { type: :ranged, kind: :hit | :miss | :off_board => kind, source:, square: { x:, y: } } if origins.key?(source)
        from_x, from_y = origins.fetch(source)
        SvgBoard::Shot.new(from_x: from_x, from_y: from_y, to_x: x, to_y: y,
                           color: color_by_id.fetch(source), hit: kind == :hit)
      in { type: :ranged, kind: :counter_fire, robot:, source: } if origins.key?(source) && origins.key?(robot)
        from_x, from_y = origins.fetch(source)
        to_x, to_y = origins.fetch(robot)
        SvgBoard::Shot.new(from_x: from_x, from_y: from_y, to_x: to_x, to_y: to_y,
                           color: color_by_id.fetch(source), hit: true, counter: true)
      else
        nil
      end
    end

    # :reek:UtilityFunction :reek:FeatureEnvy -- rendering an Entry means reading its fields; private page plumbing.
    def legend_row(entry)
      entry => { id:, life:, x:, y:, color:, alive: }
      swatch = %(<td><span class="swatch" style="background:#{color}"></span></td>)
      cells = alive ? [ERB::Util.html_escape(id), life, "(#{x},#{y})"] : [ERB::Util.html_escape(id), "&dagger;", "&mdash;"]
      %(<tr#{' class="dead"' unless alive}>#{swatch}#{cells.map { |cell| "<td>#{cell}</td>" }.join}</tr>)
    end

    # The page keeps itself current from the SSE feed: every update
    # carries the full re-rendered fragments (idempotent, so refreshes
    # and EventSource reconnects just work), and the final one closes
    # the stream, leaving the finished board on screen.
    def script
      <<~JS.chomp
        (function () {
          var board = document.getElementById("board");
          var legend = document.getElementById("legend");
          var status = document.getElementById("status");
          var log = document.getElementById("log");
          var es = new EventSource("/events");
          es.onmessage = function (event) {
            var update = JSON.parse(event.data);
            board.innerHTML = update.board_svg;
            legend.innerHTML = update.legend_html;
            status.textContent = update.status;
            log.innerHTML = update.log_html;
            log.scrollTop = log.scrollHeight;
            if (update.over) { es.close(); }
          };
        })();
      JS
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
        .legend .dead { opacity: .45; }
        .swatch { display: inline-block; width: .85em; height: .85em; border-radius: 50%; }
        .log { margin-top: 1.2rem; max-height: 22rem; min-width: 26rem; overflow-y: auto;
               background: #161b22; border-radius: 6px; padding: .6rem .9rem;
               font-size: .8rem; line-height: 1.55; color: #c9d1d9; }
        .log div { white-space: pre-wrap; }
        .log:empty { display: none; }
      CSS
    end
  end
end
