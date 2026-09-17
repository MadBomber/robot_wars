require "test_helper"
require "json"

class RobotWars::SpectatorUpdateTest < Minitest::Test
  def build_game
    game = RobotWars::Game.new(board: RobotWars::Board.new(width: 4, height: 4))
    game.add_robot(RobotWars::Robot.new(id: "alpha"), RobotWars::Position.new(x: 0, y: 0))
    game.add_robot(RobotWars::Robot.new(id: "bravo"), RobotWars::Position.new(x: 3, y: 3))
    game
  end

  def test_the_payload_carries_everything_the_page_needs_to_redraw_itself
    game = build_game
    report = game.play_turn(game.robots.to_h { |robot| [robot, RobotWars::Action.stay] })

    update = RobotWars::SpectatorUpdate.new(game: game, roster: game.robots,
                                            log_lines: ["turn 1: alpha=101, bravo=101"], events: report.events)
    payload = JSON.parse(update.to_json)

    assert_equal 1, payload.fetch("turn")
    assert_equal false, payload.fetch("over")
    assert_equal "turn 1 — 2 of 2 warriors standing", payload.fetch("status")
    assert_includes payload.fetch("board_svg"), "<svg"
    assert_includes payload.fetch("legend_html"), "<td>alpha</td>"
    assert_equal "<div>turn 1: alpha=101, bravo=101</div>", payload.fetch("log_html")
    assert_equal(%w[action action], payload.fetch("events").map { |event| event.fetch("type") })
  end

  def test_the_boards_svg_animates_the_turns_attacks
    game = build_game
    attack = RobotWars::Action.attack(square: RobotWars::Position.new(x: 3, y: 3), points: 5)
    report = game.play_turn({ game.robot("alpha") => attack, game.robot("bravo") => RobotWars::Action.stay })

    update = RobotWars::SpectatorUpdate.new(game: game, roster: game.robots, log_lines: [], events: report.events)

    assert_includes JSON.parse(update.to_json).fetch("board_svg"), %(class="shot-line")
  end

  def test_log_lines_are_html_escaped
    update = RobotWars::SpectatorUpdate.new(game: build_game, roster: nil, log_lines: ["<script>"])

    assert_includes JSON.parse(update.to_json).fetch("log_html"), "&lt;script&gt;"
  end

  def test_final_marks_the_payload_over_even_when_the_game_is_not
    game = build_game

    update = RobotWars::SpectatorUpdate.new(game: game, roster: game.robots, log_lines: [], final: true)

    assert JSON.parse(update.to_json).fetch("over")
  end

  def test_a_finished_game_is_over_without_the_final_flag
    game = build_game
    game.remove_robot(game.robot("alpha"))

    update = RobotWars::SpectatorUpdate.new(game: game, roster: nil, log_lines: [])

    assert JSON.parse(update.to_json).fetch("over")
  end
end
