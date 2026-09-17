module RobotWars
  # A warrior's brain: an LLM-backed decision-maker built from a human's
  # prompt template. `llm_robot` is anything answering `#run(message)`
  # with a result that answers `#reply` — a RobotLab::Robot in practice,
  # but never required by name, so tests can hand it a plain double.
  class LLMPilot
    def initialize(llm_robot:, parser: ActionParser.new)
      @llm_robot = llm_robot
      @parser = parser
    end

    def decide(report)
      reply = @llm_robot.run(report).reply
      @parser.parse(reply)
    end
  end
end
