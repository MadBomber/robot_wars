require "test_helper"
require "timeout"

class RobotWars::BoothTest < Minitest::Test
  # An announcer the test can hold mid-call: #announce blocks until the
  # test releases it, making every concurrency scenario deterministic.
  class GatedAnnouncer
    attr_reader :calls

    def initialize
      @calls = []
      @started = Queue.new
      @gate = Queue.new
    end

    def announce(text)
      @started << text
      @gate.pop
      @calls << text
    end

    def wait_until_speaking = Timeout.timeout(5) { @started.pop }
    def finish_speaking = @gate << true
  end

  def test_announce_returns_before_the_announcer_finishes
    announcer = GatedAnnouncer.new
    booth = RobotWars::Booth.new(announcer: announcer)

    Timeout.timeout(5) { booth.announce("turn 1") }

    assert_equal "turn 1", announcer.wait_until_speaking
    assert_empty announcer.calls
    announcer.finish_speaking
    booth.close
    assert_equal ["turn 1"], announcer.calls
  end

  def test_announcements_queued_while_speaking_are_coalesced_into_one_catch_up_call
    announcer = GatedAnnouncer.new
    booth = RobotWars::Booth.new(announcer: announcer)

    booth.announce("turn 1")
    announcer.wait_until_speaking
    booth.announce("turn 2")
    booth.announce("turn 3")
    announcer.finish_speaking

    assert_equal "turn 2\n\nturn 3", announcer.wait_until_speaking
    announcer.finish_speaking
    booth.close

    assert_equal ["turn 1", "turn 2\n\nturn 3"], announcer.calls
  end

  def test_close_waits_for_everything_queued_to_be_spoken
    announcer = GatedAnnouncer.new
    booth = RobotWars::Booth.new(announcer: announcer)
    booth.announce("finale")

    closer = Thread.new { booth.close }
    announcer.wait_until_speaking
    announcer.finish_speaking
    Timeout.timeout(5) { closer.join }

    assert_equal ["finale"], announcer.calls
  end

  def test_drain_blocks_until_everything_queued_so_far_is_spoken
    announcer = GatedAnnouncer.new
    booth = RobotWars::Booth.new(announcer: announcer)
    booth.announce("welcome to the arena")

    drainer = Thread.new { booth.drain }
    announcer.wait_until_speaking
    sleep 0.05
    assert_predicate drainer, :alive?, "drain must wait while the intro is still being spoken"

    announcer.finish_speaking
    Timeout.timeout(5) { drainer.join }

    assert_equal ["welcome to the arena"], announcer.calls
    booth.close
  end

  def test_drain_with_nothing_queued_returns_immediately_and_leaves_the_booth_open
    announcer = GatedAnnouncer.new
    booth = RobotWars::Booth.new(announcer: announcer)

    Timeout.timeout(5) { booth.drain }

    booth.announce("still on the air")
    announcer.wait_until_speaking
    announcer.finish_speaking
    booth.close
    assert_equal ["still on the air"], announcer.calls
  end

  def test_drain_counts_a_failed_announcement_as_delivered
    flaky = Object.new
    flaky.define_singleton_method(:announce) { |_text| raise "dead mic" }
    booth = RobotWars::Booth.new(announcer: flaky)

    assert_output("", /announcer failed/) do
      booth.announce("doomed")
      Timeout.timeout(5) { booth.drain }
      booth.close
    end
  end

  def test_close_with_nothing_queued_returns_and_is_idempotent
    booth = RobotWars::Booth.new(announcer: GatedAnnouncer.new)

    Timeout.timeout(5) { booth.close.close }
  end

  def test_announce_after_close_raises
    booth = RobotWars::Booth.new(announcer: GatedAnnouncer.new)
    booth.close

    assert_raises(RobotWars::Error) { booth.announce("too late") }
  end

  def test_a_failing_announcer_is_warned_about_and_the_booth_carries_on
    calls = []
    flaky = Object.new
    flaky.define_singleton_method(:announce) do |text|
      calls << text
      raise "LLM went out for coffee" if calls.size == 1
    end
    booth = RobotWars::Booth.new(announcer: flaky)

    assert_output("", /announcer failed: RuntimeError: LLM went out for coffee/) do
      booth.announce("turn 1")
      Timeout.timeout(5) { sleep 0.01 until calls.size == 1 }
      booth.announce("turn 2")
      booth.close
    end

    assert_equal ["turn 1", "turn 2"], calls
  end
end
