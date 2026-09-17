require "test_helper"

class RobotWars::SpectatorPageTest < Minitest::Test
  def build_game
    game = RobotWars::Game.new(board: RobotWars::Board.new(width: 5, height: 4))
    game.add_robot(RobotWars::Robot.new(id: "alpha"), RobotWars::Position.new(x: 1, y: 2))
    game.add_robot(RobotWars::Robot.new(id: "bravo"), RobotWars::Position.new(x: 4, y: 0))
    game
  end

  def test_renders_a_dark_page_with_the_board_and_a_legend
    html = RobotWars::SpectatorPage.new(game: build_game).to_html

    assert_includes html, "<!DOCTYPE html>"
    assert_includes html, "<title>RobotWars</title>"
    assert_includes html, "background: #0d1117"
    assert_includes html, "<svg"
    assert_includes html, "2 warriors on a 5x4 board &mdash; initial placement"
  end

  def test_legend_lists_each_warrior_with_its_color_life_and_square
    html = RobotWars::SpectatorPage.new(game: build_game).to_html

    assert_includes html, %(style="background:#{RobotWars::SvgBoard.color_for(0)}")
    assert_includes html, %(style="background:#{RobotWars::SvgBoard.color_for(1)}")
    assert_includes html, "<td>alpha</td><td>100</td><td>(1,2)</td>"
    assert_includes html, "<td>bravo</td><td>100</td><td>(4,0)</td>"
  end

  def test_warrior_ids_are_html_escaped_in_the_legend
    game = RobotWars::Game.new(board: RobotWars::Board.new(width: 2, height: 1))
    game.add_robot(RobotWars::Robot.new(id: "<b>bold</b>"), RobotWars::Position.new(x: 0, y: 0))

    html = RobotWars::SpectatorPage.new(game: game).to_html

    refute_includes html, "<td><b>bold</b></td>"
    assert_includes html, "<td>&lt;b&gt;bold&lt;/b&gt;</td>"
  end

  def test_a_mid_match_page_reports_the_turn_number
    game = build_game
    game.play_turn(game.robots.to_h { |robot| [robot, RobotWars::Action.stay] })

    html = RobotWars::SpectatorPage.new(game: game).to_html

    assert_includes html, "&mdash; turn 1"
  end

  def test_the_page_is_a_snapshot_untouched_by_later_game_changes
    game = build_game
    page = RobotWars::SpectatorPage.new(game: game)
    game.robot("alpha").apply_damage(37)

    assert_includes page.to_html, "<td>alpha</td><td>100</td>"
  end
end
