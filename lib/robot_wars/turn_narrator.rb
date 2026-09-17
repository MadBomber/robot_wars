module RobotWars
  # Turns one turn's Report into the play-by-play lines — the single
  # narrator behind both the terminal transcript and the browser
  # spectator's panel, so the two can never drift apart. Lines follow
  # the phases of rule 40: what everyone declared (with any squares
  # newly owned), then the movement-phase conflicts, then displacements,
  # then ranged combat, then the fallen.
  class TurnNarrator
    def initialize(report:)
      @report = report
    end

    def lines
      declared_lines +
        @report.solo_conflicts.map(&:to_s) +
        @report.conflicts.map(&:to_s) +
        @report.events.grep(TurnResolver::Displaced).map(&:to_s) +
        @report.ranged_effects.map(&:to_s) +
        @report.events.grep(TurnResolver::Death).map(&:to_s)
    end

    private

    def declared_lines
      @report.events.grep(TurnResolver::Declared).map { |event| declared_line(event) }
    end

    # The declared action, suffixed with any squares the turn made this
    # robot the NEW owner of (conquest or completed squat streak).
    # :reek:FeatureEnvy -- narrating an event means reading its fields; the narrator is where the line format lives.
    def declared_line(event)
      line = event.to_s
      owned = @report.claimed_squares_for(event.robot).map { |square| "(#{square.x},#{square.y})" }
      owned.empty? ? line : "#{line} — now owns #{owned.join(', ')}"
    end
  end
end
