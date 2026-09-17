require "test_helper"

class RobotWars::RollGeneratorTest < Minitest::Test
  def test_roll_is_always_within_1_to_10
    generator = RobotWars::RollGenerator.new(random: Random.new(7))

    100.times { assert_includes RobotWars::RollGenerator::RANGE, generator.roll }
  end

  def test_the_same_seed_produces_the_same_sequence
    first = RobotWars::RollGenerator.new(random: Random.new(123))
    second = RobotWars::RollGenerator.new(random: Random.new(123))

    10.times { assert_equal first.roll, second.roll }
  end
end
