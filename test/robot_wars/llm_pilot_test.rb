require "test_helper"

class RobotWars::LLMPilotTest < Minitest::Test
  FakeResult = Struct.new(:reply)

  # Stands in for a RobotLab::Robot without making any real LLM call.
  class FakeLLMRobot
    attr_reader :received

    def initialize(reply)
      @reply = reply
    end

    def run(message)
      @received = message
      FakeResult.new(@reply)
    end
  end

  def test_decide_runs_the_llm_robot_with_the_report_and_parses_the_reply
    llm_robot = FakeLLMRobot.new("MOVE east")
    pilot = RobotWars::LLMPilot.new(llm_robot: llm_robot)

    action = pilot.decide("sensing report text")

    assert_predicate action, :move?
    assert_equal RobotWars::Direction::EAST, action.direction
    assert_equal "sensing report text", llm_robot.received
  end

  def test_an_unparseable_reply_becomes_an_invalid_action
    pilot = RobotWars::LLMPilot.new(llm_robot: FakeLLMRobot.new("I refuse to choose."))

    assert_predicate pilot.decide("report"), :invalid?
  end
end
