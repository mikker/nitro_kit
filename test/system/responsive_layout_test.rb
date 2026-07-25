require "application_system_test_case"

class ResponsiveLayoutTest < ApplicationSystemTestCase
  GridState = Data.define(:width, :columns, :gap)
  FlexState = Data.define(:width, :direction, :gap, :alignment, :justification, :wrap)

  GRID_STATES = [
    GridState.new(width: 639, columns: 1, gap: 4),
    GridState.new(width: 640, columns: 2, gap: 8),
    GridState.new(width: 768, columns: 3, gap: 12),
    GridState.new(width: 1024, columns: 4, gap: 16),
    GridState.new(width: 1280, columns: 6, gap: 24),
    GridState.new(width: 1536, columns: 12, gap: 32)
  ].freeze

  FLEX_STATES = [
    FlexState.new(
      width: 639,
      direction: "column",
      gap: 4,
      alignment: "flex-start",
      justification: "flex-start",
      wrap: "nowrap"
    ),
    FlexState.new(
      width: 640,
      direction: "row",
      gap: 8,
      alignment: "center",
      justification: "center",
      wrap: "wrap"
    ),
    FlexState.new(
      width: 768,
      direction: "row-reverse",
      gap: 16,
      alignment: "flex-end",
      justification: "flex-end",
      wrap: "wrap-reverse"
    ),
    FlexState.new(
      width: 1024,
      direction: "column-reverse",
      gap: 32,
      alignment: "stretch",
      justification: "space-between",
      wrap: "nowrap"
    ),
    FlexState.new(
      width: 1280,
      direction: "row",
      gap: 48,
      alignment: "baseline",
      justification: "space-around",
      wrap: "wrap"
    ),
    FlexState.new(
      width: 1536,
      direction: "column",
      gap: 64,
      alignment: "center",
      justification: "space-evenly",
      wrap: "wrap-reverse"
    )
  ].freeze

  test "Grid resolves every fixed breakpoint at its minimum width" do
    visit gallery_component_path("grid")
    assert_selector "#gallery-grid-breakpoints"

    GRID_STATES.each do |expected|
      set_exact_viewport(expected.width)
      actual = grid_state("#gallery-grid-breakpoints")

      assert_equal "grid", actual.fetch("display")
      assert_equal expected.columns, actual.fetch("columns"), "at #{expected.width}px"
      assert_in_delta expected.gap, actual.fetch("gap"), 0.01, "at #{expected.width}px"
    end

    assert_no_severe_console_errors(context: "responsive Grid")
  end

  test "Flex resolves every property at every fixed breakpoint" do
    visit gallery_component_path("flex")
    assert_selector "#gallery-flex-breakpoints"

    FLEX_STATES.each do |expected|
      set_exact_viewport(expected.width)
      actual = flex_state("#gallery-flex-breakpoints")

      assert_equal "flex", actual.fetch("display")
      assert_equal expected.direction, actual.fetch("direction"), "at #{expected.width}px"
      assert_in_delta expected.gap, actual.fetch("gap"), 0.01, "at #{expected.width}px"
      assert_equal expected.alignment, actual.fetch("alignment"), "at #{expected.width}px"
      assert_equal expected.justification, actual.fetch("justification"), "at #{expected.width}px"
      assert_equal expected.wrap, actual.fetch("wrap"), "at #{expected.width}px"
    end

    assert_no_severe_console_errors(context: "responsive Flex")
  end

  private

  def set_exact_viewport(width)
    browser.execute_cdp(
      "Emulation.setDeviceMetricsOverride",
      width:,
      height: 1000,
      deviceScaleFactor: 1,
      mobile: false
    )

    assert_equal width, evaluate_script("window.innerWidth")
  end

  def grid_state(selector)
    evaluate_script(<<~JAVASCRIPT, find(selector))
      (() => {
        const style = getComputedStyle(arguments[0])

        return {
          display: style.display,
          columns: style.gridTemplateColumns.split(/\s+/).filter(Boolean).length,
          gap: Number.parseFloat(style.columnGap)
        }
      })()
    JAVASCRIPT
  end

  def flex_state(selector)
    evaluate_script(<<~JAVASCRIPT, find(selector))
      (() => {
        const style = getComputedStyle(arguments[0])

        return {
          display: style.display,
          direction: style.flexDirection,
          gap: Number.parseFloat(style.columnGap),
          alignment: style.alignItems,
          justification: style.justifyContent,
          wrap: style.flexWrap
        }
      })()
    JAVASCRIPT
  end
end
