require "test_helper"

class RobotWars::FixedRollGeneratorTest < Minitest::Test
  def test_returns_queued_rolls_in_order
    generator = RobotWars::FixedRollGenerator.new([3, 7, 1])

    assert_equal 3, generator.roll
    assert_equal 7, generator.roll
    assert_equal 1, generator.roll
  end

  def test_raises_once_the_queue_is_exhausted
    generator = RobotWars::FixedRollGenerator.new([5])
    generator.roll

    assert_raises(RobotWars::FixedRollGenerator::Exhausted) { generator.roll }
  end

  def test_does_not_mutate_the_array_passed_in
    rolls = [1, 2]
    RobotWars::FixedRollGenerator.new(rolls).roll

    assert_equal [1, 2], rolls
  end
end
