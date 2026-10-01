require "test_helper"

class CardTest < ActiveSupport::TestCase
  test "renders the complete compound structure" do
    node = render_node(NitroKit::Card.new(id: "summary")) do |card|
      card.title("Account", level: 3)
      card.body { "Current plan" }
      card.divider
      card.full { card.body("Full bleed") }
      card.footer { "Actions" }
    end

    assert_equal "article", node.name
    assert_equal "card", node["data-nk"]
    assert_equal "summary", node["id"]
    assert_equal "h3", node.at_css("[data-slot='card-title']").name
    assert_equal "Current plan", node.at_css("[data-slot='card-body']").text
    assert node.at_css("[data-slot='card-divider']")
    assert node.at_css("[data-slot='card-full']")
    assert_equal "Actions", node.at_css("[data-slot='card-footer']").text
    assert_empty node.css("[class], [style]")
  end

  test "defaults to the existing medium raised surface" do
    node = render_node(NitroKit::Card.new) { |card| card.body("Summary") }

    assert_equal "md", node["data-size"]
    assert_equal "default", node["data-variant"]
  end

  test "renders every size and surface combination" do
    NitroKit::Card::SIZES.product(NitroKit::Card::VARIANTS).each do |size, variant|
      node = render_node(NitroKit::Card.new(size:, variant:)) do |card|
        card.full { "Media" }
        card.title("Summary", level: 3)
        card.body("Details")
        card.divider
        card.footer("Updated today")
      end

      assert_equal size.to_s, node["data-size"]
      assert_equal variant.to_s, node["data-variant"]
      assert_equal "article", node.name
      assert_empty node.css("[class], [style], [data-controller]")
    end
  end

  test "rejects unsupported sizes and variants" do
    [ :xs, :xl, "sm", nil ].each do |size|
      assert_raises(ArgumentError) { NitroKit::Card.new(size:) }
    end
    [ :soft, :filled, "outline", nil ].each do |variant|
      assert_raises(ArgumentError) { NitroKit::Card.new(variant:) }
    end
  end

  test "reserves root and slot identity while preserving the explicit class escape" do
    [ :size, :variant, :nk, :slot ].each do |key|
      assert_raises(ArgumentError) { NitroKit::Card.new(data: { key => "override" }) }
      assert_raises(ArgumentError) do
        NitroKit::Card.new.call { |card| card.body("Details", data: { key => "override" }) }
      end
    end

    node = render_node(NitroKit::Card.new(desperately_need_a_class: "external-card")) do |card|
      card.body("Details", aria: { label: "Summary" }, data: { record_id: "12" })
    end
    assert_equal "external-card", node["class"]
    assert_equal "class", node["data-nk-escape"]
    assert_equal "Summary", node.at_css("[data-slot='card-body']")["aria-label"]
    assert_equal "12", node.at_css("[data-slot='card-body']")["data-record-id"]
  end

  test "validates title levels and attribute boundaries" do
    assert_raises(ArgumentError) do
      NitroKit::Card.new.call { |card| card.title("Invalid", level: 7) }
    end
    assert_raises(ArgumentError) { NitroKit::Card.new(class: "utility") }
  end

  test "requires a content block" do
    error = assert_raises(ArgumentError) { NitroKit::Card.new.call }

    assert_equal "Card requires a block", error.message
    assert_raises(ArgumentError) { NitroKit::Card.new.call { |card| card.full } }
    assert_raises(ArgumentError) { NitroKit::Card.new.call { |card| card.header } }
    assert_raises(ArgumentError) { NitroKit::Card.new.call { |card| card.actions } }
  end

  test "requires non-blank text or a block in every region" do
    %i[title description body footer].each do |region|
      assert_raises(ArgumentError) { NitroKit::Card.new.call { |card| card.public_send(region) } }
      assert_raises(ArgumentError) { NitroKit::Card.new.call { |card| card.public_send(region, "  ") } }
    end
  end

  test "renders a header with title, description, and actions" do
    node = render_node(NitroKit::Card.new) do |card|
      card.header do
        card.title("Profile", level: 3)
        card.description("How others see you")
        card.actions { "Edit" }
      end
      card.divider
      card.footer { card.actions { "Save" } }
    end

    header = node.at_css("> [data-slot='card-header']")
    assert_equal "header", header.name
    assert_equal %w[card-title card-description card-actions], header.element_children.map { |child| child["data-slot"] }
    assert_equal "h3", header.at_css("[data-slot='card-title']").name
    assert_equal "p", header.at_css("[data-slot='card-description']").name
    assert_equal "Save", node.at_css("[data-slot='card-footer'] > [data-slot='card-actions']").text
  end

  test "keeps the shadowed Phlex elements available" do
    node = render_node(NitroKit::Card.new) do |card|
      card.body do
        card.html_title { "Native title" }
        card.html_header { "Native header" }
      end
    end

    assert_equal "Native title", node.at_css("[data-slot='card-body'] title").text
    assert_equal "Native header", node.at_css("[data-slot='card-body'] header:not([data-slot])").text
  end

  private

  def render_node(component, &block)
    Nokogiri::HTML.fragment(component.call(&block)).first_element_child
  end
end
