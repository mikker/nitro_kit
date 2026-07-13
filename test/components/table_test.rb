require "test_helper"

class NitroKitTableComponentTest < ActiveSupport::TestCase
  test "renders semantic structure with canonical qualified slots" do
    node = render_node(NitroKit::Table.new(id: "people")) do |table|
      table.caption("People")
      table.thead do
        table.tr do
          table.th("Name")
          table.th("Balance", align: :right)
        end
      end
      table.tbody do
        table.tr do
          table.td("Ada")
          table.td("42", align: :right)
        end
      end
    end

    assert_equal "people", node["id"]
    assert_equal "table", node["data-nk"]
    assert node.at_css("table[data-slot='table-element']")
    %w[caption head body row header cell].each do |slot|
      assert node.at_css("[data-slot='table-#{slot}']"), "missing table-#{slot}"
    end
    assert_equal "right", node.css("[data-align='right']").last["data-align"]
    assert_empty node.css("[class], [style]")
  end

  test "validates cell alignment" do
    assert_raises(ArgumentError) do
      NitroKit::Table.new.call { |table| table.td("Invalid", align: :decimal) }
    end
    assert_raises(ArgumentError) do
      NitroKit::Table.new.call { |table| table.th("Invalid", scope: :column) }
    end
  end

  private

  def render_node(component, &block)
    Nokogiri::HTML.fragment(component.call(&block)).first_element_child
  end
end
