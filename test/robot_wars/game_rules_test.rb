require "test_helper"

class RobotWars::GameRulesTest < Minitest::Test
  def test_the_rules_file_ships_inside_the_gem_codebase
    assert RobotWars::GameRules::FILE.start_with?(File.expand_path("../../lib", __dir__)),
           "expected #{RobotWars::GameRules::FILE} to live under lib/"
    assert_path_exists RobotWars::GameRules::FILE
  end

  def test_text_recaps_the_game_and_the_response_grammar
    text = RobotWars::GameRules.text

    assert_includes text, "You are a warrior in RobotWars"
    assert_includes text, "The rules, in brief:"
    assert_includes text, "HIT (a robot was on the square)"
    assert_includes text, "Respond with EXACTLY one line"
    %w[STAY MOVE ATTACK DEFEND].each { |command| assert_includes text, command }
  end
end
