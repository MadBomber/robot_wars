require "test_helper"

class RobotWars::SaySpeakerTest < Minitest::Test
  # Records every runner invocation without making a sound.
  class FakeRunner
    attr_reader :calls

    def initialize(result: true)
      @calls = []
      @result = result
    end

    def call(*argv)
      @calls << argv
      @result
    end
  end

  def test_macos_speaks_through_say
    runner = FakeRunner.new
    speaker = RobotWars::SaySpeaker.new(platform: "darwin24", runner: runner)

    assert speaker.call("hello fight fans")
    assert_equal [["say", "hello fight fans"]], runner.calls
  end

  def test_windows_speaks_through_powershell_system_speech
    runner = FakeRunner.new
    speaker = RobotWars::SaySpeaker.new(platform: "mingw32", runner: runner)

    assert speaker.call("what a hit")

    argv = runner.calls.fetch(0)
    assert_equal ["powershell", "-NoProfile", "-Command"], argv[0..2]
    assert_includes argv[3], "System.Speech.Synthesis.SpeechSynthesizer"
    assert_includes argv[3], ".Speak('what a hit')"
  end

  def test_windows_escapes_single_quotes_by_doubling
    runner = FakeRunner.new
    speaker = RobotWars::SaySpeaker.new(platform: "mingw32", runner: runner)

    speaker.call("it's over")

    assert_includes runner.calls.fetch(0)[3], ".Speak('it''s over')"
  end

  def test_linux_uses_the_first_installed_engine
    runner = FakeRunner.new
    speaker = RobotWars::SaySpeaker.new(platform: "linux-gnu", runner: runner,
                                        finder: ->(command) { command == "espeak-ng" })

    assert speaker.call("boom")
    assert_equal [%w[espeak-ng boom]], runner.calls
  end

  def test_linux_engine_lookup_happens_once_per_speaker
    lookups = []
    runner = FakeRunner.new
    finder = lambda do |command|
      lookups << command
      command == "spd-say"
    end
    speaker = RobotWars::SaySpeaker.new(platform: "linux-gnu", runner: runner, finder: finder)

    speaker.call("turn one")
    speaker.call("turn two")

    assert_equal ["spd-say"], lookups
    assert_equal 2, runner.calls.size
  end

  def test_linux_without_any_engine_warns_once_and_stays_silent
    runner = FakeRunner.new
    speaker = RobotWars::SaySpeaker.new(platform: "linux-gnu", runner: runner, finder: ->(*) { false })

    assert_output("", /no text-to-speech engine found \(tried spd-say, espeak-ng, espeak\)/) do
      refute speaker.call("boom")
      refute speaker.call("again")
    end
    assert_empty runner.calls
  end

  def test_a_failed_speech_command_reports_failure
    speaker = RobotWars::SaySpeaker.new(platform: "darwin24", runner: FakeRunner.new(result: false))

    refute speaker.call("boom")
  end

  def test_default_runner_shells_out_and_waits_for_the_command
    # `true` ignores its argv and exits 0 — exercises the real
    # Kernel#system path without making a sound.
    speaker = RobotWars::SaySpeaker.new(platform: "linux-gnu", engines: ["true"], finder: ->(*) { true })

    assert speaker.call("ignored")
  end

  def test_default_finder_locates_installed_commands
    speaker = RobotWars::SaySpeaker.new(platform: "linux-gnu", engines: ["sh"], runner: FakeRunner.new)

    assert speaker.call("found via which")
  end
end
