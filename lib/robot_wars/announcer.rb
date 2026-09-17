module RobotWars
  # The ringside radio voice of a match: an LLM persona that turns each
  # raw log moment — the lineup, a turn's recap, the final result — into
  # on-air play-by-play and speaks it aloud. `llm_robot` is anything
  # answering `#run(message)` with a result that answers `#reply` (a
  # RobotLab::Robot in practice, never required by name); `speaker` is
  # anything answering `#call(text)` — SaySpeaker by default.
  class Announcer
    # The booth's default brain, in ModelSpec "<provider>/<model id>"
    # form: gpt-oss served locally by LM Studio.
    DEFAULT_MODEL = "lms/openai/gpt-oss-20b".freeze

    PERSONA = <<~PROMPT.freeze
      You are the live radio play-by-play announcer for a RobotWars
      match — an over-the-top ringside sports broadcaster calling robot
      combat on a grid. Each message you receive is the raw log of one
      moment of the match: the pre-match lineup, a single turn's recap,
      or the final result.

      Reply with ONLY the words you will say on the air:
      - Two or three short, punchy sentences. This is live radio —
        pace beats completeness; never recite every number.
      - Plain spoken prose. No markdown, no emojis, no stage
        directions, no brackets, no sound effects.
      - Say grid coordinates naturally: "four two", never "(4,2)".
      - You are calling the whole match, so build continuity —
        rivalries, momentum, near-death escapes — instead of
        re-introducing the warriors every time.
      - HITs, MISSes, INVALID commands, brain-dead pilots, deaths,
        and the final result are the big moments. Lean into them.
    PROMPT

    def initialize(llm_robot:, speaker: SaySpeaker.new)
      @llm_robot = llm_robot
      @speaker = speaker
    end

    # Narrate one moment of the match and speak it aloud. Blocks until
    # the speech finishes, so the match runs at broadcast pace.
    #
    # @param event [String] raw log text for the moment
    # @return [String] the words that went on the air ("" when the
    #   booth had nothing to say)
    def announce(event)
      commentary = @llm_robot.run(event).reply.to_s.strip
      @speaker.call(commentary) unless commentary.empty?
      commentary
    end
  end
end
