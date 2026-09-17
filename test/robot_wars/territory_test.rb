require "test_helper"

class RobotWars::TerritoryTest < Minitest::Test
  def setup
    @territory = RobotWars::Territory.new
    @robot = RobotWars::Robot.new(id: "r1")
    @rival = RobotWars::Robot.new(id: "r2")
    @square = RobotWars::Position.new(x: 2, y: 2)
  end

  def test_a_square_starts_unowned
    refute @territory.owned?(@square)
    assert_nil @territory.owner_of(@square)
  end

  def test_claim_marks_the_square_as_owned
    @territory.claim!(@square, @robot)

    assert @territory.owned?(@square)
    assert @territory.owned_by?(@square, @robot)
    refute @territory.owned_by_other?(@square, @robot)
    assert @territory.owned_by_other?(@square, @rival)
  end

  def test_each_owned_yields_every_owned_square_and_its_owner
    other_square = RobotWars::Position.new(x: 3, y: 3)
    @territory.claim!(@square, @robot)
    @territory.claim!(other_square, @rival)

    pairs = @territory.each_owned.to_a

    assert_includes pairs, [@square, @robot]
    assert_includes pairs, [other_square, @rival]
  end

  def test_release_frees_every_square_the_robot_owned
    other_square = RobotWars::Position.new(x: 3, y: 3)
    @territory.claim!(@square, @robot)
    @territory.claim!(other_square, @robot)

    @territory.release!(@robot)

    refute @territory.owned?(@square)
    refute @territory.owned?(other_square)
  end

  def test_release_does_not_affect_other_robots_squares
    @territory.claim!(@square, @rival)
    @territory.release!(@robot)

    assert @territory.owned_by?(@square, @rival)
  end

  def test_occupying_a_square_for_3_consecutive_ticks_grants_ownership
    map = RobotWars::OccupancyMap.new
    map.place(@robot, @square)

    2.times do
      assert_empty @territory.tick!(map)
      refute @territory.owned?(@square)
    end

    assert_equal({ @square => @robot }, @territory.tick!(map))
    assert @territory.owned_by?(@square, @robot)
  end

  def test_tick_does_not_re_report_a_square_already_owned
    map = RobotWars::OccupancyMap.new
    map.place(@robot, @square)
    3.times { @territory.tick!(map) }

    assert_empty @territory.tick!(map)
    assert @territory.owned_by?(@square, @robot)
  end

  def test_tick_does_not_report_a_square_the_streak_holder_already_conquered
    map = RobotWars::OccupancyMap.new
    map.place(@robot, @square)
    @territory.claim!(@square, @robot)

    3.times { assert_empty @territory.tick!(map) }
  end

  def test_leaving_a_square_and_returning_resets_the_streak
    map = RobotWars::OccupancyMap.new
    map.place(@robot, @square)
    2.times { @territory.tick!(map) }

    elsewhere = RobotWars::Position.new(x: 5, y: 5)
    map.vacate(@square)
    map.place(@robot, elsewhere)
    @territory.tick!(map)

    map.vacate(elsewhere)
    map.place(@robot, @square)
    2.times { @territory.tick!(map) }
    refute @territory.owned?(@square)

    @territory.tick!(map)

    assert @territory.owned_by?(@square, @robot)
  end

  def test_a_new_occupant_restarts_the_streak
    map = RobotWars::OccupancyMap.new
    map.place(@robot, @square)
    2.times { @territory.tick!(map) }

    map.vacate(@square)
    map.place(@rival, @square)
    3.times { @territory.tick!(map) }

    assert @territory.owned_by?(@square, @rival)
  end
end
