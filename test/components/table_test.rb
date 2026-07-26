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

  test "omits the alignment attribute for the default alignment" do
    node = render_node(NitroKit::Table.new) do |table|
      table.thead { table.tr { table.th("Name", align: :left) } }
      table.tbody { table.tr { table.td("Ada") } }
    end

    assert_empty node.css("[data-align='left']")
    assert_nil node.at_css("th")["data-align"]
    assert_nil node.at_css("td")["data-align"]
  end

  test "validates cell alignment" do
    assert_raises(ArgumentError) do
      NitroKit::Table.new.call { |table| table.td("Invalid", align: :decimal) }
    end
    assert_raises(ArgumentError) do
      NitroKit::Table.new.call { |table| table.th("Invalid", scope: :column) }
    end
  end

  test "collects sections into valid table order and constrains cell context" do
    node = render_node(NitroKit::Table.new) do |table|
      table.tbody do
        table.tr { table.td("Ada") }
      end
      table.caption("People")
      table.thead do
        table.tr { table.th("Name") }
      end
    end
    element = node.at_css("table")

    assert_equal %w[caption thead tbody], element.element_children.map(&:name)
    assert_raises(ArgumentError) do
      NitroKit::Table.new.call do |table|
        table.caption("First")
        table.caption("Second")
      end
    end
    assert_raises(ArgumentError) { NitroKit::Table.new.call { |table| table.tr { table.td("Invalid") } } }
    assert_raises(ArgumentError) { NitroKit::Table.new.call { |table| table.td("Invalid") } }
  end

  test "renders sortable headers with caller-owned URLs and active native sort state" do
    node = render_node(NitroKit::Table.new(sort: :name, direction: :asc, id: "people")) do |table|
      table.caption("People")
      table.thead do
        table.tr do
          table.th(
            sort: :name,
            href: "/people?q%5Bs%5D=name+desc",
            sort_data: { turbo_action: "replace" }
          )
          table.th("Balance", sort: :balance, href: "/people?q%5Bs%5D=balance+asc", align: :right)
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

    assert_equal "name", node["data-sort"]
    assert_equal "asc", node["data-direction"]

    headers = node.css("[data-slot='table-header'][data-sort-key]")
    assert_equal %w[name balance], headers.map { |header| header["data-sort-key"] }
    assert_equal "right", headers.last["data-align"]
    assert_equal "ascending", headers.first["aria-sort"]
    assert_equal "none", headers.last["aria-sort"]
    assert_nil node.css("[data-slot='table-header']").last["aria-sort"]

    active_link = headers.first.at_css("[data-slot='table-sort']")
    assert_equal "/people?q%5Bs%5D=name+desc", active_link["href"]
    assert_equal "replace", active_link["data-turbo-action"]
    assert_equal "Name", active_link.at_css("[data-slot='table-sort-label']").text
    indicator = active_link.at_css("[data-slot='table-sort-indicator']")
    assert_equal "icon", indicator["data-nk"]
    assert_equal "true", indicator["aria-hidden"]
    assert_empty node.css("[class], [style]")
  end

  test "renders descending and unsorted sort affordances" do
    descending = render_node(NitroKit::Table.new(sort: "updated_at", direction: "desc")) do |table|
      table.thead { table.tr { table.th(sort: :updated_at, href: "/records?sort=updated_at-asc") } }
    end

    assert_equal "descending", descending.at_css("th")["aria-sort"]
    assert_equal "Updated at", descending.at_css("[data-slot='table-sort-label']").text
    assert descending.at_css("[data-slot='table-sort-indicator']")

    unsorted = render_node(NitroKit::Table.new) do |table|
      table.thead { table.tr { table.th(sort: :name, href: "/records?sort=name-asc") } }
    end

    assert_nil unsorted["data-sort"]
    assert_nil unsorted["data-direction"]
    assert_equal "none", unsorted.at_css("th")["aria-sort"]
    assert unsorted.at_css("[data-slot='table-sort-indicator']")
  end

  test "accepts block content for a sortable header label" do
    node = render_node(NitroKit::Table.new) do |table|
      table.thead do
        table.tr do
          table.th(sort: :name, href: "/records") { "Workspace" }
        end
      end
    end

    assert_equal "Workspace", node.at_css("[data-slot='table-sort-label']").text
  end

  test "validates sort state keys and hrefs before emitting the header" do
    assert_raises(ArgumentError) { NitroKit::Table.new(sort: :name) }
    assert_raises(ArgumentError) { NitroKit::Table.new(direction: :asc) }
    assert_raises(ArgumentError) { NitroKit::Table.new(sort: :name, direction: :sideways) }
    assert_raises(ArgumentError) { NitroKit::Table.new(sort: " ", direction: :asc) }

    assert_raises(ArgumentError) do
      NitroKit::Table.new.call do |table|
        table.thead { table.tr { table.th(sort: :name) } }
      end
    end

    assert_raises(ArgumentError) do
      NitroKit::Table.new.call do |table|
        table.thead { table.tr { table.th(sort: :name, href: " ") } }
      end
    end

    assert_raises(ArgumentError) do
      NitroKit::Table.new.call do |table|
        table.thead { table.tr { table.th("Name", href: "/records") } }
      end
    end

    assert_raises(ArgumentError) do
      NitroKit::Table.new.call do |table|
        table.thead do
          table.tr do
            table.th(sort: :name, href: "/records")
            table.th(sort: "name", href: "/records")
          end
        end
      end
    end
  end

  test "keeps shared root attributes explicit" do
    node = render_node(
      NitroKit::Table.new(
        id: "records",
        html: { title: "Sortable records" },
        aria: { label: "Record controls" },
        data: { tracking_id: "records-1" },
        table_aria: { label: "Records" },
        desperately_need_a_class: "external-table"
      )
    ) do |table|
      table.thead { table.tr { table.th(sort: :name, href: "/records") } }
    end

    assert_equal "records", node["id"]
    assert_equal "Sortable records", node["title"]
    assert_equal "Record controls", node["aria-label"]
    assert_equal "records-1", node["data-tracking-id"]
    assert_equal "external-table", node["class"]
    assert_equal "class", node["data-nk-escape"]
    assert_equal "Records", node.at_css("table")["aria-label"]
    assert_empty node.css("[style]")
  end

  private

  def render_node(component, &block)
    Nokogiri::HTML.fragment(component.call(&block)).first_element_child
  end
end
