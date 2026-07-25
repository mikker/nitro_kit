require "test_helper"

class SortableTableTest < ActiveSupport::TestCase
  test "composes Table with sortable links and active native sort state" do
    node = render_node(
      NitroKit::SortableTable.new(current: :name, direction: :asc, id: "people")
    ) do |table|
      table.caption("People")
      table.thead do
        table.tr do
          table.sortable_th(
            :name,
            href: "/people?q%5Bs%5D=name+desc",
            data: { turbo_action: "replace" }
          )
          table.sortable_th(:balance, "Balance", href: "/people?q%5Bs%5D=balance+asc", align: :right)
          table.th("Actions")
        end
      end
      table.tbody do
        table.tr do
          table.td("Ada")
          table.td("42", align: :right)
          table.td("View")
        end
      end
    end

    assert_equal "people", node["id"]
    assert_equal "sortable-table", node["data-nk"]
    assert_equal "name", node["data-current"]
    assert_equal "asc", node["data-direction"]
    assert node.at_css("[data-nk='table'][data-slot='sortable-table-table']")

    headers = node.css("[data-slot='table-header'][data-sort-key]")
    assert_equal %w[name balance], headers.map { |header| header["data-sort-key"] }
    assert_equal "right", headers.last["data-align"]
    assert_equal "ascending", headers.first["aria-sort"]
    assert_nil headers.last["aria-sort"]

    active_link = headers.first.at_css("[data-slot='sortable-table-link']")
    assert_equal "/people?q%5Bs%5D=name+desc", active_link["href"]
    assert_equal "replace", active_link["data-turbo-action"]
    assert_equal "Name↑", active_link.text
    assert_equal "true", active_link.at_css("[data-slot='sortable-table-indicator']")["aria-hidden"]
    assert_empty node.css("[class], [style]")
  end

  test "renders descending and unsorted states" do
    descending = render_node(NitroKit::SortableTable.new(current: "updated_at", direction: "desc")) do |table|
      table.thead { table.tr { table.sortable_th(:updated_at, href: "/records?sort=updated_at-asc") } }
    end

    assert_equal "descending", descending.at_css("th")["aria-sort"]
    assert_equal "Updated at↓", descending.at_css("[data-slot='sortable-table-link']").text

    unsorted = render_node(NitroKit::SortableTable.new) do |table|
      table.thead { table.tr { table.sortable_th(:name, href: "/records?sort=name-asc") } }
    end

    assert_nil unsorted["data-current"]
    assert_nil unsorted["data-direction"]
    assert_nil unsorted.at_css("th")["aria-sort"]
    assert_nil unsorted.at_css("[data-slot='sortable-table-indicator']")
  end

  test "keeps shared root attributes explicit" do
    node = render_node(
      NitroKit::SortableTable.new(
        id: "records",
        html: { title: "Sortable records" },
        aria: { label: "Record controls" },
        data: { tracking_id: "records-1" },
        desperately_need_a_class: "external-sortable-table"
      )
    ) do |table|
      table.thead { table.tr { table.sortable_th(:name, href: "/records") } }
    end

    assert_equal "records", node["id"]
    assert_equal "Sortable records", node["title"]
    assert_equal "Record controls", node["aria-label"]
    assert_equal "records-1", node["data-tracking-id"]
    assert_equal "external-sortable-table", node["class"]
    assert_equal "class", node["data-nk-escape"]
    assert_empty node.css("[style]")
  end

  test "validates both halves of sort state" do
    assert_raises(ArgumentError) { NitroKit::SortableTable.new(current: :name) }
    assert_raises(ArgumentError) { NitroKit::SortableTable.new(direction: :asc) }
    assert_raises(ArgumentError) { NitroKit::SortableTable.new(current: :name, direction: :sideways) }
  end

  test "validates headers keys labels and hrefs" do
    assert_raises(ArgumentError) { NitroKit::SortableTable.new.call }

    assert_raises(ArgumentError) do
      NitroKit::SortableTable.new.call do |table|
        table.thead { table.tr { table.sortable_th(" ", href: "/records") } }
      end
    end

    assert_raises(ArgumentError) do
      NitroKit::SortableTable.new.call do |table|
        table.thead { table.tr { table.sortable_th(:" ", href: "/records") } }
      end
    end

    assert_raises(ArgumentError) do
      NitroKit::SortableTable.new.call do |table|
        table.thead { table.tr { table.sortable_th(:name, " ", href: "/records") } }
      end
    end

    assert_raises(ArgumentError) do
      NitroKit::SortableTable.new.call do |table|
        table.thead { table.tr { table.sortable_th(:name, href: " ") } }
      end
    end

    assert_raises(ArgumentError) do
      NitroKit::SortableTable.new.call do |table|
        table.thead { table.tr { table.sortable_th(:name, href: "/records", align: :decimal) } }
      end
    end

    assert_raises(ArgumentError) do
      NitroKit::SortableTable.new.call do |table|
        table.thead do
          table.tr do
            table.sortable_th(:name, href: "/records")
            table.sortable_th("name", href: "/records")
          end
        end
      end
    end
  end

  test "requires current to match a declared sortable header" do
    assert_raises(ArgumentError) do
      NitroKit::SortableTable.new(current: :missing, direction: :asc).call do |table|
        table.thead { table.tr { table.sortable_th(:name, href: "/records") } }
      end
    end
  end

  private

  def render_node(component, &block)
    Nokogiri::HTML.fragment(component.call(&block)).first_element_child
  end
end
