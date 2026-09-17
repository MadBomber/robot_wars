require "test_helper"

class RobotWarsTest < Minitest::Test
  def test_it_has_a_version_number
    refute_nil RobotWars::VERSION
    assert_match(/\A\d+\.\d+\.\d+\z/, RobotWars::VERSION)
  end

  def test_error_is_a_standard_error
    assert_operator RobotWars::Error, :<, StandardError
  end
end
