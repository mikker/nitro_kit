require "test_helper"

class BadgeTest < ActiveSupport::TestCase
  test "renders the complete variant size and color matrix" do
    assert_predicate NitroKit::Badge::VARIANTS, :frozen?
    assert_predicate NitroKit::Badge::SIZES, :frozen?
    assert_predicate NitroKit::Badge::COLORS, :frozen?
    assert_equal 23, NitroKit::Badge::COLORS.size
    assert_includes NitroKit::Badge::COLORS, :zinc
    assert_includes NitroKit::Badge::COLORS, :rose

    NitroKit::Badge::VARIANTS.product(NitroKit::Badge::SIZES, NitroKit::Badge::COLORS).each do |variant, size, color|
      node = render_node(NitroKit::Badge.new("Status", variant:, size:, color:))

      assert_equal "badge", node["data-nk"]
      assert_equal variant.to_s, node["data-variant"]
      assert_equal size.to_s, node["data-size"]
      assert_equal color.to_s, node["data-color"]
      assert_equal "Status", node.at_css("[data-slot='badge-label']").text
      refute node.key?("class")
      refute node.key?("style")
    end
  end

  test "renders constructor and call-time block content" do
    constructor_node = render_node(NitroKit::Badge.new { "From constructor" })
    call_node = render_node(NitroKit::Badge.new) { "From call" }

    assert_equal "From constructor", constructor_node.text
    assert_equal "From call", call_node.text
  end

  test "requires label content and stringifies scalar labels" do
    error = assert_raises(ArgumentError) { NitroKit::Badge.new.call }
    assert_match(/label content is required/, error.message)
    assert_raises(ArgumentError) { NitroKit::Badge.new("").call }
    assert_raises(ArgumentError) { NitroKit::Badge.new("   ").call }

    assert_equal "42", render_node(NitroKit::Badge.new(42)).text
    assert_equal "ready", render_node(NitroKit::Badge.new(:ready)).text
  end

  test "escapes badge text" do
    node = render_node(NitroKit::Badge.new("<script>unsafe()</script>"))

    assert_equal "<script>unsafe()</script>", node.text
    assert_nil node.at_css("script")
  end

  test "keeps root attributes explicit" do
    node = render_node(
      NitroKit::Badge.new(
        "New",
        id: "new-badge",
        html: { title: "Recently added" },
        aria: { label: "New item" },
        data: { tracking_id: "badge-1" }
      )
    )

    assert_equal "new-badge", node["id"]
    assert_equal "Recently added", node["title"]
    assert_equal "New item", node["aria-label"]
    assert_equal "badge-1", node["data-tracking-id"]
  end

  test "validates every closed option immediately" do
    variant_error = assert_raises(ArgumentError) { NitroKit::Badge.new(variant: :quiet) }
    size_error = assert_raises(ArgumentError) { NitroKit::Badge.new(size: :lg) }
    color_error = assert_raises(ArgumentError) { NitroKit::Badge.new(color: :chartreuse) }

    assert_match(/Unknown variant :quiet/, variant_error.message)
    assert_match(/Unknown size :lg/, size_error.message)
    assert_match(/Unknown color :chartreuse/, color_error.message)
    assert_raises(ArgumentError) { NitroKit::Badge.new(class: "utility") }
  end

  test "supports the class escape hatch" do
    node = render_node(NitroKit::Badge.new("Custom", desperately_need_a_class: "external-badge"))

    assert_equal "external-badge", node["class"]
    assert_equal "class", node["data-nk-escape"]
  end

  test "ships the complete Tailwind color palette" do
    css = NitroKit::Engine.root.join(
      "src/stylesheets/nitro_kit/components/palette.css"
    ).read

    NitroKit::Badge::COLORS.first(18).each do |color|
      assert_includes css, %(data-color="#{color}")
    end
  end

  private

  def render_node(component, &block)
    Nokogiri::HTML.fragment(component.call(&block)).first_element_child
  end
end
