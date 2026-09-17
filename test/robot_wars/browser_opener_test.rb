require "test_helper"

class RobotWars::BrowserOpenerTest < Minitest::Test
  # Records every runner invocation without opening a window.
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

  URL = "http://127.0.0.1:8080/".freeze

  def test_macos_opens_through_open
    runner = FakeRunner.new
    opener = RobotWars::BrowserOpener.new(platform: "darwin24", runner: runner)

    assert opener.call(URL)
    assert_equal [["open", URL]], runner.calls
  end

  def test_windows_opens_through_cmd_start_with_an_empty_title
    runner = FakeRunner.new
    opener = RobotWars::BrowserOpener.new(platform: "mingw32", runner: runner)

    assert opener.call(URL)
    assert_equal [["cmd", "/c", "start", "", URL]], runner.calls
  end

  def test_everything_else_opens_through_xdg_open
    runner = FakeRunner.new
    opener = RobotWars::BrowserOpener.new(platform: "linux-gnu", runner: runner)

    assert opener.call(URL)
    assert_equal [["xdg-open", URL]], runner.calls
  end

  def test_a_failed_launcher_reports_failure
    opener = RobotWars::BrowserOpener.new(platform: "darwin24", runner: FakeRunner.new(result: false))

    refute opener.call(URL)
  end

  def test_the_default_runner_is_kernel_system
    opener = RobotWars::BrowserOpener.new(platform: "darwin24")

    assert_equal :system, opener.instance_variable_get(:@runner).name
  end
end
