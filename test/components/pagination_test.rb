require "test_helper"

class PaginationComponentTest < ActiveSupport::TestCase
  test "builds conventional navigation from a modern Pagy object" do
    pagy = Class.new do
      attr_reader :previous, :next

      def initialize
        @previous = 4
        @next = 6
      end

      def page_url(page) = "/projects?page=#{page}"

      protected

      def series = [ 1, :gap, 4, "5", 6, :gap, 12 ]
    end.new

    node = render_node(NitroKit::Pagination.new(pagy:))
    items = node.css("[data-slot='pagination-item']")

    assert_equal %w[previous page ellipsis page page page ellipsis page next],
      items.map { |item| item["data-kind"] }
    assert_equal "/projects?page=4",
      node.at_css("[data-slot='pagination-previous']")["href"]
    assert_equal "5", node.at_css("[aria-current='page']").text
    assert_equal "/projects?page=6",
      node.at_css("[data-slot='pagination-next']")["href"]
  end

  test "supports older Pagy objects through an explicit page URL callable" do
    pagy = Class.new do
      attr_reader :prev, :next

      def initialize
        @prev = nil
        @next = 2
      end

      protected

      def series = [ "1", 2, :gap, 8 ]
    end.new
    page_url = ->(page) { "/legacy?page=#{page}" }

    node = render_node(NitroKit::Pagination.new(pagy:, page_url:))

    assert_equal "true",
      node.at_css("[data-slot='pagination-previous']")["aria-disabled"]
    assert_equal "/legacy?page=2",
      node.at_css("[data-slot='pagination-next']")["href"]
  end

  test "keeps the Pagy dependency optional and validates its boundary" do
    pagy = Object.new

    assert_raises(ArgumentError) { NitroKit::Pagination.new(pagy:) }
    assert_raises(ArgumentError) do
      NitroKit::Pagination.new(pagy: nil, page_url: "/pages")
    end
    assert_raises(ArgumentError) do
      valid_pagy = Class.new do
        attr_reader :previous, :next

        protected

        def series = [ 1 ]
      end.new

      NitroKit::Pagination.new(pagy: valid_pagy).call
    end
    valid_pagy = Class.new do
      attr_reader :previous, :next

      protected

      def series = [ "1" ]
    end.new
    assert_raises(ArgumentError) do
      NitroKit::Pagination.new(pagy: valid_pagy).call do |pagination|
        pagination.page(1, current: true)
      end
    end
  end

  test "renders one ordered native navigation list" do
    assert_predicate NitroKit::Pagination::ITEM_KINDS, :frozen?
    assert_equal %i[previous page ellipsis next], NitroKit::Pagination::ITEM_KINDS

    node = render_node(NitroKit::Pagination.new) do |pagination|
      pagination.prev(href: "/pages/1")
      pagination.page(1, href: "/pages/1")
      pagination.page(2, current: true)
      pagination.ellipsis
      pagination.page(20, href: "/pages/20")
      pagination.next(href: "/pages/3")
    end
    list = node.at_xpath("./*[@data-slot='pagination-list']")
    items = list.xpath("./*[@data-slot='pagination-item']")

    assert_equal "nav", node.name
    assert_equal "pagination", node["data-nk"]
    assert_equal "Pagination", node["aria-label"]
    assert_equal "ol", list.name
    assert_equal %w[previous page page ellipsis page next], items.map { |item| item["data-kind"] }
    assert_equal [ "ghost" ], node.css("[data-nk='button']").map { |button| button["data-variant"] }.uniq
    assert_equal [ "sm" ], node.css("[data-nk='button']").map { |button| button["data-size"] }.uniq
    assert_empty node.css("[class], [style]")
  end

  test "marks a current page link without misrepresenting it as disabled" do
    node = render_node(NitroKit::Pagination.new) do |pagination|
      pagination.page("12", href: "/pages/12", current: true)
    end
    current = node.at_css("[data-slot='pagination-page']")

    assert_equal "a", current.name
    assert_equal "page", current["aria-current"]
    assert_nil current["aria-disabled"]
    assert_nil current["tabindex"]
    assert_equal "/pages/12", current["href"]
  end

  test "allows a current page without an href and rejects missing destinations elsewhere" do
    current_node = render_node(NitroKit::Pagination.new) do |pagination|
      pagination.page(1, current: true)
    end

    current = current_node.at_css("span[data-slot='pagination-page'][aria-current='page']")
    assert current
    assert_nil current["aria-disabled"]
    assert_nil current["tabindex"]
    assert_raises(ArgumentError) do
      NitroKit::Pagination.new.call { |pagination| pagination.page(2) }
    end
  end

  test "renders missing previous and next hrefs as disabled links" do
    node = render_node(NitroKit::Pagination.new) do |pagination|
      pagination.prev(nil)
      pagination.page(1, current: true)
      pagination.next(nil)
    end
    previous = node.at_css("[data-slot='pagination-previous']")
    following = node.at_css("[data-slot='pagination-next']")

    [ previous, following ].each do |link|
      assert_equal "a", link.name
      assert_equal "true", link["aria-disabled"]
      assert_equal "-1", link["tabindex"]
      assert_nil link["href"]
      assert link.at_css("[data-nk='icon']")
      assert_nil link.at_css("[data-slot='button-label']")
    end
    assert_equal "Previous page", previous["aria-label"]
    assert_equal "Next page", following["aria-label"]
  end

  test "supports long labels blocks and controls without icons" do
    long_label = "Go back to the previous collection of archived audit records"
    node = render_node(NitroKit::Pagination.new(label: "Audit log pages")) do |pagination|
      pagination.prev(long_label, href: "/older", icon: nil)
      pagination.page(href: "/custom") { "A custom page label" }
      pagination.next(href: "/newer", icon: nil) { "Continue through audit records" }
    end

    assert_equal "Audit log pages", node["aria-label"]
    assert_equal long_label, node.at_css("[data-slot='pagination-previous']").text
    assert_equal "A custom page label", node.at_css("[data-slot='pagination-page']").text
    assert_equal "Continue through audit records", node.at_css("[data-slot='pagination-next']").text
    assert_empty node.css("[data-nk='icon']")
  end

  test "renders an accessible non-interactive ellipsis" do
    node = render_node(NitroKit::Pagination.new) do |pagination|
      pagination.page(1, href: "/1")
      pagination.ellipsis(label: "Pages 2 through 9 omitted")
    end
    ellipsis = node.at_css("[data-slot='pagination-ellipsis']")
    label = node.at_css("[data-slot='pagination-ellipsis-label']")

    assert_equal "…", ellipsis.text
    assert_equal "true", ellipsis["aria-hidden"]
    assert_equal "Pages 2 through 9 omitted", label.text
    assert_nil ellipsis["role"]
    assert_nil ellipsis["tabindex"]
  end

  test "keeps root and item attributes explicit" do
    node = render_node(
      NitroKit::Pagination.new(
        label: "Search pages",
        id: "search-pages",
        html: { title: "Search result navigation" },
        aria: { describedby: "result-count" },
        data: { tracking_id: "pagination-1" }
      )
    ) do |pagination|
      pagination.page(
        1,
        href: "/search?page=1",
        id: "page-1",
        html: { title: "Page one" },
        aria: { label: "Go to page one" },
        data: { tracking_id: "page-1" }
      )
    end
    page = node.at_css("[data-slot='pagination-page']")

    assert_equal "search-pages", node["id"]
    assert_equal "Search pages", node["aria-label"]
    assert_equal "Search result navigation", node["title"]
    assert_equal "result-count", node["aria-describedby"]
    assert_equal "pagination-1", node["data-tracking-id"]
    assert_equal "page-1", page["id"]
    assert_equal "Page one", page["title"]
    assert_equal "Go to page one", page["aria-label"]
    assert_equal "page-1", page["data-tracking-id"]
  end

  test "enforces unique current previous and next items in order" do
    assert_raises(ArgumentError) do
      NitroKit::Pagination.new.call do |pagination|
        pagination.page(1, current: true)
        pagination.page(2, current: true)
      end
    end
    assert_raises(ArgumentError) do
      NitroKit::Pagination.new.call do |pagination|
        pagination.prev(href: "/older")
        pagination.prev(href: "/oldest")
      end
    end
    assert_raises(ArgumentError) do
      NitroKit::Pagination.new.call do |pagination|
        pagination.next(href: "/newer")
        pagination.next(href: "/newest")
      end
    end
    assert_raises(ArgumentError) do
      NitroKit::Pagination.new.call do |pagination|
        pagination.page(1, href: "/1")
        pagination.prev(href: "/older")
      end
    end
    assert_raises(ArgumentError) do
      NitroKit::Pagination.new.call do |pagination|
        pagination.next(href: "/newer")
        pagination.page(2, href: "/2")
      end
    end
  end

  test "validates empty and malformed item collections" do
    assert_raises(ArgumentError) { NitroKit::Pagination.new.call }
    assert_raises(ArgumentError) do
      NitroKit::Pagination.new.call { |pagination| pagination.ellipsis }
    end
    assert_raises(ArgumentError) do
      NitroKit::Pagination.new.call do |pagination|
        pagination.page(1, href: "/1")
        pagination.ellipsis
        pagination.ellipsis
      end
    end
    assert_raises(ArgumentError) do
      NitroKit::Pagination.new.call { |pagination| pagination.ellipsis(label: "") }
    end
  end

  test "validates labels booleans icons and owned ARIA" do
    assert_raises(ArgumentError) { NitroKit::Pagination.new(label: "") }
    assert_raises(ArgumentError) { NitroKit::Pagination.new(label: :pages) }
    assert_raises(ArgumentError) { NitroKit::Pagination.new(aria: "invalid") }
    assert_raises(ArgumentError) { NitroKit::Pagination.new(aria: { label: "Duplicate" }) }
    assert_raises(ArgumentError) do
      NitroKit::Pagination.new.call { |pagination| pagination.page(1, href: "/1", current: :yes) }
    end
    assert_raises(ArgumentError) do
      NitroKit::Pagination.new.call { |pagination| pagination.prev(disabled: :yes) }
    end
    assert_raises(ArgumentError) do
      NitroKit::Pagination.new.call { |pagination| pagination.page(nil, href: "/1") }
    end
    assert_raises(ArgumentError) do
      NitroKit::Pagination.new.call { |pagination| pagination.prev(nil, icon: nil) }
    end
    assert_raises(ArgumentError) do
      NitroKit::Pagination.new.call { |pagination| pagination.page(1, href: "/1", aria: { current: "page" }) }
    end
    assert_raises(ArgumentError) do
      NitroKit::Pagination.new.call { |pagination| pagination.next(aria: { disabled: false }) }
    end
    assert_raises(ArgumentError) do
      NitroKit::Pagination.new.call { |pagination| pagination.prev(href: "/1", icon: "not-a-real-icon") }
    end
  end

  test "rejects classes and supports the root class escape hatch" do
    assert_raises(ArgumentError) { NitroKit::Pagination.new(class: "utility") }
    assert_raises(ArgumentError) { NitroKit::Pagination.new(html: { style: "width: 100%" }) }
    assert_raises(ArgumentError) do
      NitroKit::Pagination.new.call do |pagination|
        pagination.page(1, href: "/1", html: { class: "utility" })
      end
    end

    node = render_node(
      NitroKit::Pagination.new(desperately_need_a_class: "external-pagination")
    ) { |pagination| pagination.page(1, current: true) }

    assert_equal "external-pagination", node["class"]
    assert_equal "class", node["data-nk-escape"]
    assert_empty node.css("[style]")
  end

  private

  def render_node(component, &block)
    Nokogiri::HTML.fragment(component.call(&block)).first_element_child
  end
end
