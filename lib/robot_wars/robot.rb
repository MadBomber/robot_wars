module RobotWars
  # A player in the game. Life-point bookkeeping only (RULES.md 5, 10,
  # 11, 12, 36) — position, ownership, and actions live elsewhere so
  # each piece of state can be tested on its own.
  class Robot
    STARTING_LIFE = 100

    attr_reader :id, :life

    def initialize(id:, life: STARTING_LIFE)
      @id = id
      @life = life
      @eliminated = false
    end

    def alive?
      !@eliminated && life.positive?
    end

    def dead?
      !alive?
    end

    # Death by displacement (RULES.md 37) — a separate cause from life
    # reaching 0 or less (rule 36), so the life total is left as-is.
    def eliminate!
      @eliminated = true
      self
    end

    def apply_damage(amount)
      raise ArgumentError, "amount must not be negative" if amount.negative?

      @life -= amount
      self
    end

    def heal(amount)
      raise ArgumentError, "amount must not be negative" if amount.negative?

      @life += amount
      self
    end

    def to_s
      "##{id} (#{life} life)"
    end
  end
end
