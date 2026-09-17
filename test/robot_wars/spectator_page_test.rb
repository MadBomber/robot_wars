require "test_helper"

class RobotWars::SpectatorPageTest < Minitest::Test
  def build_game
    game = RobotWars::Game.new(board: RobotWars::Board.new(width: 5, height: 4))
    game.add_robot(RobotWars::Robot.new(id: "alpha"), RobotWars::Position.new(x: 1, y: 2))
    game.add_robot(RobotWars::Robot.new(id: "bravo"), RobotWars::Position.new(x: 4, y: 0))
    game
  end

  def stay_all(game)
    game.play_turn(game.robots.to_h { |robot| [robot, RobotWars::Action.stay] })
  end

  def test_renders_a_dark_page_with_the_board_a_legend_and_a_log_panel
    html = RobotWars::SpectatorPage.new(game: build_game).to_html

    assert_includes html, "<!DOCTYPE html>"
    assert_includes html, "<title>RobotWars</title>"
    assert_includes html, "background: #0d1117"
    assert_includes html, "<svg"
    assert_includes html, %(<div class="log" id="log">)
    assert_includes html, %(new EventSource("/events"))
    assert_includes html, "2 warriors on a 5x4 board — initial placement"
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

  def test_a_mid_match_page_reports_the_turn_and_the_standing_count
    game = build_game
    stay_all(game)

    page = RobotWars::SpectatorPage.new(game: game)

    assert_equal "turn 1 — 2 of 2 warriors standing", page.status_text
  end

  def test_the_page_is_a_snapshot_untouched_by_later_game_changes
    game = build_game
    page = RobotWars::SpectatorPage.new(game: game)
    game.robot("alpha").apply_damage(37)

    assert_includes page.to_html, "<td>alpha</td><td>100</td>"
  end

  def test_a_fallen_warrior_keeps_a_dimmed_legend_row_and_its_color_stays_stable
    game = build_game
    roster = game.robots
    game.remove_robot(game.robot("alpha"))

    page = RobotWars::SpectatorPage.new(game: game, roster: roster)
    legend = page.legend_html

    assert_includes legend, %(<tr class="dead"><td><span class="swatch" style="background:#{RobotWars::SvgBoard.color_for(0)}")
    assert_includes legend, "<td>alpha</td><td>&dagger;</td><td>&mdash;</td>"
    # bravo keeps its roster color even though it is now the only robot.
    assert_includes legend, %(style="background:#{RobotWars::SvgBoard.color_for(1)}")
    refute_includes page.board_svg, ">alpha</text>"
  end

  def test_the_winner_headline
    game = build_game
    roster = game.robots
    game.remove_robot(game.robot("alpha"))

    assert_equal "winner: bravo after 0 turns", RobotWars::SpectatorPage.new(game: game, roster: roster).status_text
  end

  def test_the_tie_headline
    game = build_game
    roster = game.robots
    game.robots.each { |robot| game.remove_robot(robot) }

    assert_equal "tie — the last warriors fell together on turn 0",
                 RobotWars::SpectatorPage.new(game: game, roster: roster).status_text
  end

  def test_owned_squares_are_shaded_in_the_owners_color
    game = build_game
    game.territory.claim!(RobotWars::Position.new(x: 3, y: 3), game.robot("bravo"))

    svg = RobotWars::SpectatorPage.new(game: game).board_svg

    cell = RobotWars::SvgBoard::CELL
    margin = RobotWars::SvgBoard::MARGIN
    pad = RobotWars::SvgBoard::PAD
    # y=3 is the TOP row of the height-4 board (rule 47: y grows north).
    assert_includes svg, %(<rect x="#{margin + (3 * cell)}" y="#{pad}" width="#{cell}" height="#{cell}" ) +
                         %(fill="#{RobotWars::SvgBoard.color_for(1)}" fill-opacity="0.22"/>)
  end

  def attack(x, y, points: 5)
    RobotWars::Action.attack(square: RobotWars::Position.new(x: x, y: y), points: points)
  end

  def test_an_attack_animates_a_shot_from_the_attackers_square_in_its_color
    game = build_game
    report = game.play_turn({ game.robot("alpha") => attack(4, 0), game.robot("bravo") => RobotWars::Action.stay })

    svg = RobotWars::SpectatorPage.new(game: game, events: report.events).board_svg

    cell = RobotWars::SvgBoard::CELL
    margin = RobotWars::SvgBoard::MARGIN
    pad = RobotWars::SvgBoard::PAD
    # alpha fired from (1,2) at (4,0) — bravo's square, a HIT. On the
    # height-4 board, y=2 is one row down from the top; y=0 is the bottom.
    assert_includes svg, %(<line class="shot-line" x1="#{margin + cell + (cell / 2)}" y1="#{pad + cell + (cell / 2)}" ) +
                         %(x2="#{margin + (4 * cell) + (cell / 2)}" y2="#{pad + (3 * cell) + (cell / 2)}" ) +
                         %(pathLength="1" stroke="#{RobotWars::SvgBoard.color_for(0)}")
    assert_includes svg, "--splash-opacity:.9"
  end

  def test_a_missed_attack_still_animates_but_splashes_dimly
    game = build_game
    report = game.play_turn({ game.robot("alpha") => attack(0, 0), game.robot("bravo") => RobotWars::Action.stay })

    svg = RobotWars::SpectatorPage.new(game: game, events: report.events).board_svg

    assert_includes svg, %(class="shot-line")
    assert_includes svg, "--splash-opacity:.45"
  end

  def test_counter_fire_animates_a_delayed_shot_from_defender_back_to_attacker
    game = build_game
    report = game.play_turn({ game.robot("alpha") => attack(4, 0),
                              game.robot("bravo") => RobotWars::Action.defend(points: 3) })

    svg = RobotWars::SpectatorPage.new(game: game, events: report.events).board_svg

    cell = RobotWars::SvgBoard::CELL
    margin = RobotWars::SvgBoard::MARGIN
    pad = RobotWars::SvgBoard::PAD
    # bravo, hit on (4,0), fires back at alpha on (1,2) in its own color.
    assert_includes svg, %(<g class="shot-counter">)
    assert_includes svg, %(<line class="shot-line" x1="#{margin + (4 * cell) + (cell / 2)}" y1="#{pad + (3 * cell) + (cell / 2)}" ) +
                         %(x2="#{margin + cell + (cell / 2)}" y2="#{pad + cell + (cell / 2)}" ) +
                         %(pathLength="1" stroke="#{RobotWars::SvgBoard.color_for(1)}")
  end

  def test_a_turn_without_attacks_animates_nothing
    game = build_game
    report = stay_all(game)

    refute_includes RobotWars::SpectatorPage.new(game: game, events: report.events).board_svg, "shot-line"
  end

  def test_icons_carry_life_numbers
    svg = RobotWars::SpectatorPage.new(game: build_game).board_svg

    assert_includes svg, %(font-weight="600" fill="#{RobotWars::SvgBoard.color_for(0)}">100</text>)
  end
end
