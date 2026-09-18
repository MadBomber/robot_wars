require_relative "lib/robot_wars/version"

Gem::Specification.new do |spec|
  spec.name = "robot_wars"
  spec.version = RobotWars::VERSION
  spec.authors = ["Dewayne VanHoozer"]
  spec.email = ["dvanhoozer@gmail.com"]

  spec.summary = "Turn-based last-robot-standing game for RobotLab robots on a 2D grid board."
  spec.description = "A turn-based game built on the RobotLab framework: each robot occupies a square on a 2D grid, " \
                     "all robots move simultaneously each turn, conflicts are resolved between turns, " \
                     "and the last robot remaining wins."
  spec.homepage = "https://github.com/MadBomber/robot_wars"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.4.0"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/MadBomber/robot_wars"
  spec.metadata["changelog_uri"] = "https://github.com/MadBomber/robot_wars/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[Gemfile .gitignore test/])
    end
  end
  spec.bindir = "bin"
  spec.executables = spec.files.grep(%r{\Abin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "robot_lab", "~> 0.3"
end
