require "test_helper"

class RobotWars::AnnouncerTest < Minitest::Test
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

  class FakeSpeaker
    attr_reader :spoken

    def initialize
      @spoken = []
    end

    def call(text)
      @spoken << text
    end
  end

  def test_announce_runs_the_llm_robot_with_the_event_and_speaks_the_reply
    llm_robot = FakeLLMRobot.new("  What a hit, folks!  ")
    speaker = FakeSpeaker.new
    announcer = RobotWars::Announcer.new(llm_robot: llm_robot, speaker: speaker)

    commentary = announcer.announce("turn 4: warmonger's attack was a HIT")

    assert_equal "What a hit, folks!", commentary
    assert_equal ["What a hit, folks!"], speaker.spoken
    assert_equal "turn 4: warmonger's attack was a HIT", llm_robot.received
  end

  def test_a_blank_reply_is_not_spoken
    speaker = FakeSpeaker.new
    announcer = RobotWars::Announcer.new(llm_robot: FakeLLMRobot.new("   "), speaker: speaker)

    assert_equal "", announcer.announce("turn 1")
    assert_empty speaker.spoken
  end

  def test_a_nil_reply_is_not_spoken
    speaker = FakeSpeaker.new
    announcer = RobotWars::Announcer.new(llm_robot: FakeLLMRobot.new(nil), speaker: speaker)

    assert_equal "", announcer.announce("turn 1")
    assert_empty speaker.spoken
  end
end
