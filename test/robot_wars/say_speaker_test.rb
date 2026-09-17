require "test_helper"

class RobotWars::SaySpeakerTest < Minitest::Test
  def test_call_runs_the_command_with_the_text
    argv = nil
    recorder = lambda do |*args|
      argv = args
      true
    end

    assert RobotWars::SaySpeaker.new(runner: recorder).call("hello fight fans")
    assert_equal ["say", "hello fight fans"], argv
  end

  def test_a_failed_command_reports_failure
    speaker = RobotWars::SaySpeaker.new(runner: ->(*) { false })

    refute speaker.call("boom")
  end

  def test_command_is_configurable
    argv = nil
    recorder = lambda do |*args|
      argv = args
      true
    end

    RobotWars::SaySpeaker.new(command: "espeak", runner: recorder).call("boom")

    assert_equal %w[espeak boom], argv
  end

  def test_default_runner_shells_out_and_waits_for_the_command
    # `true` ignores its argv and exits 0 — exercises the real
    # Kernel#system path without making a sound.
    assert RobotWars::SaySpeaker.new(command: "true").call("ignored")
  end
end
