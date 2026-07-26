require "test_helper"

class StatGridTest < ActiveSupport::TestCase
  test "renders ordered keyed records inside one description list" do
    node = render_node(NitroKit::StatGrid.new(id: "workspace-stats")) do |stats|
      stats.stat(key: :active_projects, label: "Active projects", value: "12", detail: "Across 4 teams")
      stats.stat(key: "members", label: "Members", value: "87")
      stats.stat(key: :uptime, label: "Uptime", value: "99.99%", detail: "Past 30 days")
    end

    grid = node.element_children.sole
    assert_equal "grid", grid["data-nk"]
    assert_equal "stat-grid-grid", grid["data-slot"]
    assert_equal "1 sm:2 lg:3", grid["data-cols"]

    list = grid.element_children.sole
    assert_equal "dl", list.name
    assert_equal "stat-grid-list", list["data-slot"]
    assert_equal %w[div div div], list.element_children.map(&:name)
    assert_equal %w[active-projects members uptime], list.element_children.map { |child| child["data-key"] }
    assert_equal %w[dt dd dd], list.element_children.first.element_children.map(&:name)
    assert_equal [ "Active projects", "Members", "Uptime" ], list.css("[data-slot='stat-grid-label']").map(&:text)
    assert_equal %w[12 87 99.99%], list.css("[data-slot='stat-grid-value']").map(&:text)
    assert_equal 2, list.css("[data-slot='stat-grid-detail']").count
    assert_empty node.css("[class], [style], [data-nk-escape]")
  end

  test "accepts any value and calls to_s" do
    node = render_node(NitroKit::StatGrid.new) do |stats|
      stats.stat(key: :members, label: :members, value: 87, detail: 4)
    end

    assert_equal "members", node.at_css("[data-slot='stat-grid-label']").text
    assert_equal "87", node.at_css("[data-slot='stat-grid-value']").text
    assert_equal "4", node.at_css("[data-slot='stat-grid-detail']").text
  end

  test "accepts the Grid column and gap vocabulary" do
    node = render_node(NitroKit::StatGrid.new(cols: "1 md:4", gap: 6)) do |stats|
      stats.stat(key: :members, label: "Members", value: "87")
    end
    grid = node.element_children.sole

    assert_equal "1 md:4", grid["data-cols"]
    assert_equal "6", grid["data-gap"]
    assert_raises(ArgumentError) { NitroKit::StatGrid.new(cols: 13) }
    assert_raises(ArgumentError) { NitroKit::StatGrid.new(cols: "1 xs:2") }
    assert_raises(ArgumentError) { NitroKit::StatGrid.new(gap: 7) }
  end

  test "requires records with unique normalized keys and non-blank copy" do
    assert_raises(ArgumentError) { render_node(NitroKit::StatGrid.new) }
    assert_raises(ArgumentError) do
      render_node(NitroKit::StatGrid.new) do |stats|
        stats.stat(key: :active_users, label: "Users", value: "10")
        stats.stat(key: "active-users", label: "Members", value: "11")
      end
    end
    assert_raises(ArgumentError) do
      NitroKit::StatGrid.new.call { |stats| stats.stat(key: :users, label: "", value: "10") }
    end
    assert_raises(ArgumentError) do
      NitroKit::StatGrid.new.call { |stats| stats.stat(key: :users, label: "Users", value: " ") }
    end
  end

  test "keeps root attributes explicit and rejects reserved boundaries" do
    node = render_node(
      NitroKit::StatGrid.new(
        id: "stats",
        html: { title: "Workspace statistics" },
        aria: { label: "Statistics" },
        data: { tracking_id: "stats-1" },
        desperately_need_a_class: "external-stat-grid"
      )
    ) { |stats| stats.stat(key: :members, label: "Members", value: "87") }

    assert_equal "stats", node["id"]
    assert_equal "Workspace statistics", node["title"]
    assert_equal "Statistics", node["aria-label"]
    assert_equal "stats-1", node["data-tracking-id"]
    assert_equal "external-stat-grid", node["class"]
    assert_equal "class", node["data-nk-escape"]
    assert_raises(ArgumentError) { NitroKit::StatGrid.new(class: "utility") }
    assert_raises(ArgumentError) { NitroKit::StatGrid.new(data: { nk: "custom" }) }
  end

  private

  def render_node(component, &block)
    Nokogiri::HTML.fragment(component.call(&block)).first_element_child
  end
end
