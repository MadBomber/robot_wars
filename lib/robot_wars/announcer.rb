module RobotWars
  # The ringside radio voice of a match: an LLM persona that turns each
  # raw log moment — the lineup, a turn's recap, the final result — into
  # on-air play-by-play and speaks it aloud. The persona itself belongs
  # to the `llm_robot`'s prompt: rwars builds it from the warriors
  # directory's _announcer.md template, editable like any warrior brain.
  # `llm_robot` is anything answering `#run(message)` with a result that
  # answers `#reply` (a RobotLab::Robot in practice, never required by
  # name); `speaker` is anything answering `#call(text)` — SaySpeaker by
  # default.
  class Announcer
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
