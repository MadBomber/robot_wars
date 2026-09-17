require "simplecov"
SimpleCov.start do
  skip "/test/"
  skip "/vendor/"

  group "RobotWars", "lib/robot_wars"

  enable_coverage :branch
end

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "robot_wars"

require "minitest/autorun"
