require "test_helper"

class RobotWars::ConflictResolverTest < Minitest::Test
  def test_requires_at_least_2_robots
    resolver = RobotWars::ConflictResolver.new
    robot = RobotWars::Robot.new(id: "r1")

    assert_raises(ArgumentError) { resolver.resolve([robot]) }
  end

  def test_the_shared_roll_damages_every_robot_equally
    resolver = conflict_resolver(rolls: [6])
    strong = RobotWars::Robot.new(id: "strong", life: 100)
    weak = RobotWars::Robot.new(id: "weak", life: 50)

    resolver.resolve([strong, weak])

    assert_equal 94, strong.life
    assert_equal 44, weak.life
  end

  def test_the_higher_life_robot_wins_and_the_rest_lose
    resolver = conflict_resolver(rolls: [5])
    strong = RobotWars::Robot.new(id: "strong", life: 100)
    weak = RobotWars::Robot.new(id: "weak", life: 50)

    result = resolver.resolve([strong, weak])

    assert_equal strong, result.winner
    assert_equal [weak], result.losers
    assert_equal 5, result.roll
  end

  def test_a_tie_for_highest_life_means_no_winner
    resolver = conflict_resolver(rolls: [3])
    first = RobotWars::Robot.new(id: "a", life: 100)
    second = RobotWars::Robot.new(id: "b", life: 100)

    result = resolver.resolve([first, second])

    assert_nil result.winner
    assert_equal [first, second], result.losers
  end

  def test_a_roll_can_be_lethal_to_the_winner_too
    resolver = conflict_resolver(rolls: [10])
    strong = RobotWars::Robot.new(id: "strong", life: 8)
    weak = RobotWars::Robot.new(id: "weak", life: 5)

    result = resolver.resolve([strong, weak])

    assert_equal strong, result.winner
    assert_predicate strong, :dead?
  end

  private

  def conflict_resolver(rolls:)
    RobotWars::ConflictResolver.new(roll_generator: RobotWars::FixedRollGenerator.new(rolls))
  end
end
