require "test_helper"

load File.expand_path("../../lib/tasks/nitro_kit_tasks.rake", __dir__) unless defined?(NitroKit::CssBundle)

class PaginationBarTest < ActiveSupport::TestCase
  test "renders owned regions in semantic order regardless of declaration order" do
    node = render_node(NitroKit::PaginationBar.new) do |bar|
      bar.pagination(NitroKit::Pagination.new) { |pagination| pagination.page(1, current: true) }
      bar.summary("1 result")
    end

    assert_equal "div", node.name
    assert_equal "pagination-bar", node["data-nk"]
    assert_equal %w[pagination-bar-summary pagination-bar-pagination],
      node.element_children.map { |child| child["data-slot"] }
  end

  test "composes caller summary with exactly one typed Pagination" do
    node = render_pagination_bar
    summary = node.at_xpath("./*[@data-slot='pagination-bar-summary']")
    pagination = node.at_xpath("./*[@data-slot='pagination-bar-pagination']")

    assert_equal "pagination-bar", node["data-nk"]
    assert_equal "p", summary.name
    assert_equal "Showing 26–50 of 121 members", summary.text
    assert_equal "polite", summary["aria-live"]
    assert_equal "nav", pagination.name
    assert_equal "pagination", pagination["data-nk"]
    assert_equal "Member pages", pagination["aria-label"]
    assert_equal "page", pagination.at_css("[data-slot='pagination-current'][aria-current]")["aria-current"]
    assert_empty node.css("[class], [style], [data-nk-escape]")
  end

  test "renders summary block content as well as summary text" do
    node = render_node(NitroKit::PaginationBar.new) do |bar|
      bar.summary { "Showing every archived record" }
      bar.pagination(NitroKit::Pagination.new) { |pagination| pagination.page(1, current: true) }
    end

    assert_equal "Showing every archived record", node.at_css("[data-slot='pagination-bar-summary']").text
  end

  test "announces summary changes politely by default" do
    node = render_node(NitroKit::PaginationBar.new) do |bar|
      bar.summary("Showing 1–25 of 121 members")
      bar.pagination(NitroKit::Pagination.new) { |pagination| pagination.page(1, current: true) }
    end
    assertive = render_node(NitroKit::PaginationBar.new) do |bar|
      bar.summary("Showing 1–25 of 121 members", aria: { live: "assertive" })
      bar.pagination(NitroKit::Pagination.new) { |pagination| pagination.page(1, current: true) }
    end

    assert_equal "polite", node.at_css("[data-slot='pagination-bar-summary']")["aria-live"]
    assert_equal "assertive", assertive.at_css("[data-slot='pagination-bar-summary']")["aria-live"]
  end

  test "allows an omitted summary but rejects missing wrong and duplicate Pagination" do
    without_summary = render_node(NitroKit::PaginationBar.new) do |bar|
      bar.pagination(NitroKit::Pagination.new) { |pagination| pagination.page(1, current: true) }
    end

    assert_empty without_summary.xpath("./*[@data-slot='pagination-bar-summary']")
    assert_equal 1, without_summary.xpath("./*[@data-slot='pagination-bar-pagination']").count
    assert_match(/requires one Pagination/, assert_raises(ArgumentError) { NitroKit::PaginationBar.new.call }.message)
    assert_raises(ArgumentError) do
      NitroKit::PaginationBar.new.call { |bar| bar.summary("No navigation") }
    end
    [ nil, :summary, "", "  " ].each do |summary|
      assert_raises(ArgumentError) do
        NitroKit::PaginationBar.new.call { |bar| bar.summary(summary) }
      end
    end
    assert_raises(ArgumentError) do
      NitroKit::PaginationBar.new.call { |bar| bar.summary("Text") { "Block" } }
    end
    assert_match(/must be a NitroKit::Pagination/, assert_raises(ArgumentError) do
      NitroKit::PaginationBar.new.call { |bar| bar.pagination(NitroKit::Button.new("Wrong")) }
    end.message)
    assert_raises(ArgumentError) do
      NitroKit::PaginationBar.new.call do |bar|
        bar.pagination(NitroKit::Pagination.new) { |pagination| pagination.page(1, current: true) }
        bar.pagination(NitroKit::Pagination.new) { |pagination| pagination.page(2, current: true) }
      end
    end
    assert_raises(ArgumentError) do
      NitroKit::PaginationBar.new.call do |bar|
        bar.summary("First")
        bar.summary("Second")
      end
    end
  end

  test "composes application attributes on the root the summary and the child Pagination" do
    node = render_node(
      NitroKit::PaginationBar.new(
        id: "pagination-bar-attrs",
        html: { title: "Member pages" },
        data: { application_state: "ready" }
      )
    ) do |bar|
      bar.summary("Summary", html: { id: "summary-attrs" }, data: { region: "summary" })
      bar.pagination(NitroKit::Pagination.new) { |pagination| pagination.page(1, current: true) }
    end

    assert_equal "pagination-bar-attrs", node["id"]
    assert_equal "Member pages", node["title"]
    assert_equal "ready", node["data-application-state"]
    assert_equal "summary", node.at_css("#summary-attrs")["data-region"]
    assert_equal "pagination-bar-pagination", node.at_css("[data-nk='pagination']")["data-slot"]
    assert_empty node.css("[class], [style], [data-nk-escape]")
  end

  test "rejects reserved Nitro data and emits the deliberate class escape" do
    node = render_node(
      NitroKit::PaginationBar.new(desperately_need_a_class: "external-pagination-bar")
    ) do |bar|
      bar.summary("Summary", html: { id: "summary-attrs" }, desperately_need_a_class: "external-summary")
      bar.pagination(NitroKit::Pagination.new(desperately_need_a_class: "external-pagination")) do |pagination|
        pagination.page(1, current: true)
      end
    end

    assert_equal "external-pagination-bar", node["class"]
    assert_equal "class", node["data-nk-escape"]
    assert_equal "class", node.at_css("#summary-attrs")["data-nk-escape"]
    assert_equal "class", node.at_css("[data-nk='pagination']")["data-nk-escape"]

    assert_raises(ArgumentError) { NitroKit::PaginationBar.new(html: { class: "utility" }) }
    assert_raises(ArgumentError) { NitroKit::PaginationBar.new(html: { style: "display: none" }) }
    %i[nk slot variant size state].each do |reserved|
      assert_raises(ArgumentError) { NitroKit::PaginationBar.new(data: { reserved => "replacement" }) }
    end
    assert_raises(ArgumentError) do
      NitroKit::PaginationBar.new.call { |bar| bar.summary("Summary", data: { slot: "replacement" }) }
    end
  end

  test "owns wide placement and narrow stacking in static CSS" do
    source = NitroKit::Engine.root.join("src/stylesheets/nitro_kit/components/pagination_bar.css").read
    css = NitroKit::CssBundle.compile

    assert_includes css, %([data-nk="pagination-bar"])
    assert_includes css, %([data-nk="pagination"][data-slot="pagination-bar-pagination"])
    assert_includes source, "@media (max-width: 48rem)"
    refute_includes source, "transition: all"
    refute_match(/(?:\:where\(\s*|,\s*)\[data-slot=/m, source)
  end

  test "is reachable through the gallery catalog" do
    entry = Gallery::Catalog.fetch!(kind: :block, slug: "pagination-bar")

    assert_equal Gallery::Blocks::PaginationBarPage, entry.page
    assert_includes entry.expected_roots, "pagination-bar"
  end

  private

  def render_pagination_bar
    render_node(NitroKit::PaginationBar.new(id: "member-pages")) do |bar|
      bar.summary(
        "Showing 26–50 of 121 members",
        html: { id: "member-summary" },
        aria: { live: "polite" }
      )
      bar.pagination(NitroKit::Pagination.new(label: "Member pages")) do |pagination|
        pagination.prev(href: "/members?page=1")
        pagination.page(1, href: "/members?page=1")
        pagination.page(2, current: true)
        pagination.next(href: "/members?page=3")
      end
    end
  end

  def render_node(component, &block)
    Nokogiri::HTML.fragment(component.call(&block)).first_element_child
  end
end
