require "test_helper"

class TableCssTest < ActiveSupport::TestCase
  STYLESHEET = NitroKit::Engine.root.join("src/stylesheets/nitro_kit/components/table.css")

  test "scopes alignment to table cells instead of nested layout components" do
    css = STYLESHEET.read

    assert_includes css, '[data-slot="table-header"][data-align="center"]'
    assert_includes css, '[data-slot="table-cell"][data-align="center"]'
    assert_includes css, '[data-slot="table-header"][data-align="right"]'
    assert_includes css, '[data-slot="table-cell"][data-align="right"]'
    refute_includes css, '[data-nk="table"] [data-align="center"]'
    refute_includes css, '[data-nk="table"] [data-align="right"]'
  end
end
