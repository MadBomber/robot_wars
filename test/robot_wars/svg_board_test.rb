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

    # Column labels 0..2 BELOW the grid; row labels 0..1 up the left —
    # rule 47: row 0 is the SOUTH (bottom) row, and the x-axis reads
    # where an x-axis belongs, under the origin row.
    assert_equal 3 + 2, svg.scan("<text").size
    below_grid = PAD + (2 * CELL) + 18
    assert_includes svg, %(<text x="#{MARGIN + (2 * CELL) + (CELL / 2)}" y="#{below_grid}" text-anchor="middle")
    assert_includes svg, %(<text x="#{MARGIN - 8}" y="#{PAD + CELL + (CELL / 2) + 4}" text-anchor="end" ) +
                         %(font-family="#{RobotWars::SvgBoard::FONT}" font-size="11" ) +
                         %(fill="#{RobotWars::SvgBoard::LABEL_COLOR}">0</text>)
  end

  def test_a_robot_icon_is_drawn_at_its_cell_center_in_its_color
    icon = RobotWars::SvgBoard::Icon.new(id: "alpha", x: 2, y: 1, color: "#4fc3f7")
    svg = RobotWars::SvgBoard.new(width: 3, height: 2, icons: [icon]).to_s

    cx = MARGIN + (2 * CELL) + (CELL / 2)
    cy = PAD + (CELL / 2) # y=1 is the TOP row of a height-2 board (rule 47)
    assert_includes svg, %(<circle cx="#{cx}" cy="#{cy}" r="14" fill="#4fc3f7"/>)
    assert_includes svg, %(<title>alpha at (2,1)</title>)
    assert_includes svg, %(fill="#4fc3f7">alpha</text>)
  end

  def test_the_origin_square_is_drawn_at_the_bottom_left
    icon = RobotWars::SvgBoard::Icon.new(id: "sw", x: 0, y: 0, color: "#4fc3f7")
    svg = RobotWars::SvgBoard.new(width: 2, height: 3, icons: [icon]).to_s

    bottom_row_center = PAD + (2 * CELL) + (CELL / 2)
    assert_includes svg, %(<circle cx="#{MARGIN + (CELL / 2)}" cy="#{bottom_row_center}" r="14" fill="#4fc3f7"/>)
  end

  def test_an_icon_with_life_prints_it_beside_the_head_and_in_the_tooltip
    icon = RobotWars::SvgBoard::Icon.new(id: "alpha", x: 0, y: 0, color: "#4fc3f7", life: 87)
    svg = RobotWars::SvgBoard.new(width: 1, height: 1, icons: [icon]).to_s

    assert_includes svg, %(<title>alpha at (0,0) — life 87</title>)
    assert_includes svg, %(font-weight="600" fill="#4fc3f7">87</text>)
  end

  def test_owned_squares_are_washed_in_their_owners_color_under_the_grid
    owned = RobotWars::SvgBoard::OwnedSquare.new(x: 1, y: 0, color: "#81c784")
    svg = RobotWars::SvgBoard.new(width: 2, height: 1, owned: [owned]).to_s

    rect = %(<rect x="#{MARGIN + CELL}" y="#{PAD}" width="#{CELL}" height="#{CELL}" fill="#81c784" fill-opacity="0.22"/>)
    assert_includes svg, rect
    assert_operator svg.index(rect), :<, svg.index("<line"), "territory must be painted under the grid lines"
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
