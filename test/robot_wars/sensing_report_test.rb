require "test_helper"

class RobotWars::SensingReportTest < Minitest::Test
  def setup
    @game = RobotWars::Game.new(board: RobotWars::Board.new(width: 5, height: 5))
    @robot = RobotWars::Robot.new(id: "alpha", life: 87)
    @rival = RobotWars::Robot.new(id: "bravo")
    @game.add_robot(@robot, RobotWars::Position.new(x: 3, y: 2))
    @game.add_robot(@rival, RobotWars::Position.new(x: 0, y: 0))
  end

  def test_reports_the_upcoming_turn_number
    assert_includes report, "Turn 1."
  end

  def test_reports_own_position_and_life
    assert_includes report, "Your position: (3,2). Your life: 87."
  end

  def test_reports_no_owned_squares_when_none_are_claimed
    assert_includes report, "No squares are owned yet."
  end

  def test_reports_owned_squares_with_their_owner
    @game.territory.claim!(RobotWars::Position.new(x: 3, y: 2), @robot)
    @game.territory.claim!(RobotWars::Position.new(x: 0, y: 0), @rival)

    assert_includes report, "(3,2) owned by alpha (yours)"
    assert_includes report, "(0,0) owned by bravo"
    refute_includes report, "(0,0) owned by bravo (yours)"
  end

  def test_reports_the_surviving_warriors
    assert_includes report, "2 warriors remain: alpha, bravo."
  end

  def test_tells_an_attacker_its_last_attack_hit
    text = RobotWars::SensingReport.new(game: @game, robot: @robot, attack_outcome: :hit).to_s

    assert_includes text, "Your attack last turn was a HIT."
  end

  def test_tells_an_attacker_its_last_attack_missed
    text = RobotWars::SensingReport.new(game: @game, robot: @robot, attack_outcome: :miss).to_s

    assert_includes text, "Your attack last turn was a MISS."
  end

  def test_tells_an_attacker_its_last_attack_went_off_the_board
    text = RobotWars::SensingReport.new(game: @game, robot: @robot, attack_outcome: :off_board).to_s

    assert_includes text, "Your attack last turn was OFF THE BOARD and cost you half its committed points."
  end

  def test_says_nothing_about_attacks_when_the_robot_did_not_attack
    refute_includes report, "Your attack last turn"
  end

  private

  def report
    RobotWars::SensingReport.new(game: @game, robot: @robot).to_s
  end
end
