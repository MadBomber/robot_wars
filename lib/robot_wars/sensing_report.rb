module RobotWars
  # What one robot is told before it acts (RULES.md 33-35): its own
  # position and life, and the full map of owned squares — never any
  # other robot's position.
  #
  # Two details rule 35 leaves open are implemented here as defaults,
  # not settled rules (see notes.md): the map names each square's owner
  # rather than just distinguishing mine/theirs, and the report says how
  # many warriors remain and who they are.
  class SensingReport
    # attack_outcome: :hit or :miss when the robot attacked last turn
    # (see TurnResolver::Report#attack_outcome_for), nil otherwise —
    # Battleship-style feedback, the one thing an attacker learns about
    # where its rivals are.
    def initialize(game:, robot:, attack_outcome: nil)
      @game = game
      @robot = robot
      @attack_outcome = attack_outcome
    end

    def to_s
      [
        "Turn #{@game.turn_number + 1}.",
        "Your position: #{position_text}. Your life: #{@robot.life}.",
        attack_feedback_text,
        ownership_text,
        survivors_text
      ].compact.join("\n") << "\n"
    end

    private

    def attack_feedback_text
      @attack_outcome && "Your attack last turn was a #{@attack_outcome.to_s.upcase}."
    end

    def position_text
      position = @game.occupancy.position_of(@robot)
      "(#{position.x},#{position.y})"
    end

    def ownership_text
      owned = @game.territory.each_owned.to_a
      return "No squares are owned yet." if owned.empty?

      lines = owned.map { |square, owner| "  (#{square.x},#{square.y}) owned by #{owner.id}#{mine(owner)}" }
      (["Owned squares:"] + lines).join("\n")
    end

    # :reek:ControlParameter -- comparing the owner against @robot is the method's entire purpose.
    def mine(owner)
      owner == @robot ? " (yours)" : ""
    end

    # :reek:FeatureEnvy -- `survivors` is a local snapshot formatted in place; there is nowhere better for it.
    def survivors_text
      survivors = @game.alive_robots
      "#{survivors.size} warriors remain: #{survivors.map(&:id).join(', ')}."
    end
  end
end
