require "erb"
require "json"

module RobotWars
  # One turn's payload for the browser spectator: the re-rendered page
  # fragments, the full play-by-play so far, and the turn's typed event
  # stream as data. Built on the match thread (the only thread allowed
  # to read game state) and published as an immutable JSON string.
  #
  # The payload is deliberately idempotent — everything needed to draw
  # the whole page — so a late-joining browser, a refresh, or an
  # EventSource reconnect needs nothing but the latest update.
  class SpectatorUpdate
    # `final: true` marks the match's last word (win, tie, or the
    # max-turns stop), telling the page to close its event stream.
    # :reek:BooleanParameter :reek:ControlParameter -- final is a recorded fact carried into the payload, not a behavior switch.
    def initialize(game:, roster:, log_lines:, events: [], final: false)
      @page = SpectatorPage.new(game: game, roster: roster)
      @turn = game.turn_number
      @over = game.over? || final
      @log_lines = log_lines.dup
      @events = events
    end

    def to_json(*)
      JSON.generate(payload)
    end

    def payload
      { turn: @turn, over: @over, status: @page.status_text, board_svg: @page.board_svg,
        legend_html: @page.legend_html, log_html: log_html, events: @events.map(&:to_h) }
    end

    private

    def log_html
      @log_lines.map { |line| "<div>#{ERB::Util.html_escape(line)}</div>" }.join
    end
  end
end
