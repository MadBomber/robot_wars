require "test_helper"

class RobotWars::SvgBoardTest < Minitest::Test
  CELL   = RobotWars::SvgBoard::CELL
  MARGIN = RobotWars::SvgBoard::MARGIN
  PAD    = RobotWars::SvgBoard::PAD

  def test_the_drawing_has_a_transparent_background
    svg = RobotWars::SvgBoard.new(width: 3, height: 2).to_s

    # Grid is lines and robots are circles — no rect anywhere means no
    # background fill; the host page's theme shows through.
    refute_includes svg, "<rect"
    assert_includes svg, %(<svg xmlns="http://www.w3.org/2000/svg")
  end

  def test_pixel_size_covers_the_grid_labels_and_padding
    svg = RobotWars::SvgBoard.new(width: 3, height: 2).to_s

    assert_includes svg, %(width="#{MARGIN + (3 * CELL) + PAD}" height="#{MARGIN + (2 * CELL) + PAD}")
  end

  def test_grid_draws_one_line_per_column_and_row_boundary
    svg = RobotWars::SvgBoard.new(width: 3, height: 2).to_s

    assert_equal (3 + 1) + (2 + 1), svg.scan("<line").size
  end

  def test_axis_labels_number_every_column_and_row
    svg = RobotWars::SvgBoard.new(width: 3, height: 2).to_s

    # Column labels 0..2 across the top, row labels 0..1 down the left.
    assert_equal 3 + 2, svg.scan("<text").size
    assert_includes svg, %(<text x="#{MARGIN + (2 * CELL) + (CELL / 2)}" y="#{MARGIN - 8}" text-anchor="middle")
    assert_includes svg, %(<text x="#{MARGIN - 8}" y="#{MARGIN + CELL + (CELL / 2) + 4}" text-anchor="end")
  end

  def test_a_robot_icon_is_drawn_at_its_cell_center_in_its_color
    icon = RobotWars::SvgBoard::Icon.new(id: "alpha", x: 2, y: 1, color: "#4fc3f7")
    svg = RobotWars::SvgBoard.new(width: 3, height: 2, icons: [icon]).to_s

    cx = MARGIN + (2 * CELL) + (CELL / 2)
    cy = MARGIN + (1 * CELL) + (CELL / 2)
    assert_includes svg, %(<circle cx="#{cx}" cy="#{cy}" r="14" fill="#4fc3f7"/>)
    assert_includes svg, %(<title>alpha at (2,1)</title>)
    assert_includes svg, %(fill="#4fc3f7">alpha</text>)
  end

  def test_robot_ids_are_html_escaped
    icon = RobotWars::SvgBoard::Icon.new(id: "<sneaky>", x: 0, y: 0, color: "#4fc3f7")
    svg = RobotWars::SvgBoard.new(width: 1, height: 1, icons: [icon]).to_s

    refute_includes svg, "<sneaky>"
    assert_includes svg, "&lt;sneaky&gt;"
  end

  def test_color_for_assigns_by_index_and_cycles_past_the_palette
    palette = RobotWars::SvgBoard::PALETTE

    assert_equal palette.first, RobotWars::SvgBoard.color_for(0)
    assert_equal palette.last, RobotWars::SvgBoard.color_for(palette.size - 1)
    assert_equal palette.first, RobotWars::SvgBoard.color_for(palette.size)
  end
end
