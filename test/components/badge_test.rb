require "test_helper"

class BadgeTest < ActiveSupport::TestCase
  test "renders the complete variant size and color matrix" do
    assert_predicate NitroKit::Badge::VARIANTS, :frozen?
    assert_predicate NitroKit::Badge::SIZES, :frozen?
    assert_predicate NitroKit::Badge::COLORS, :frozen?
    assert_equal 22, NitroKit::Badge::COLORS.size
    assert_equal %i[neutral info success warning destructive], NitroKit::Badge::SEMANTIC_COLORS
    assert_equal 17, NitroKit::Badge::PALETTE_COLORS.size
    assert_empty NitroKit::Badge::SEMANTIC_COLORS & NitroKit::Badge::PALETTE_COLORS

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

  test "renders text or one block, never both" do
    assert_equal "From a block", render_node(NitroKit::Badge.new { "From a block" }).text

    error = assert_raises(ArgumentError) do
      NitroKit::Badge.new("Status").call { "From a block" }
    end
    assert_match(/not both/, error.message)
  end

  test "validates blank label text at construction and stringifies scalar labels" do
    error = assert_raises(ArgumentError) { NitroKit::Badge.new("") }
    assert_match(/label content is required/, error.message)
    assert_raises(ArgumentError) { NitroKit::Badge.new("   ") }
    assert_raises(ArgumentError) { NitroKit::Badge.new.call }

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
    variant_error = assert_raises(ArgumentError) { NitroKit::Badge.new("Status", variant: :quiet) }
    size_error = assert_raises(ArgumentError) { NitroKit::Badge.new("Status", size: :lg) }
    color_error = assert_raises(ArgumentError) { NitroKit::Badge.new("Status", color: :chartreuse) }

    assert_match(/Unknown variant :quiet/, variant_error.message)
    assert_match(/Unknown size :lg/, size_error.message)
    assert_match(/Unknown color :chartreuse/, color_error.message)
    assert_raises(ArgumentError) { NitroKit::Badge.new("Status", class: "utility") }
  end

  test "supports the class escape hatch" do
    node = render_node(NitroKit::Badge.new("Custom", desperately_need_a_class: "external-badge"))

    assert_equal "external-badge", node["class"]
    assert_equal "class", node["data-nk-escape"]
  end

  test "resolves every color to public tokens so applications can retheme them" do
    css = NitroKit::Engine.root.join(
      "src/stylesheets/nitro_kit/components/palette.css"
    ).read

    NitroKit::Badge::SEMANTIC_COLORS.each do |color|
      assert_includes css, %(data-color="#{color}")
      assert_includes css, "--_nk-semantic-accent: var(--nk-palette-#{color})"
      assert_includes css, "--_nk-semantic-content: var(--nk-palette-#{color}-content)"
    end

    NitroKit::Badge::PALETTE_COLORS.each do |color|
      assert_includes css, %(data-color="#{color}")
      assert_includes css, "--_nk-semantic-accent: var(--nk-palette-#{color})"
      assert_includes css, "--_nk-semantic-content: var(--nk-palette-#{color}-content)"
    end

    refute_match(/oklch\(/, css, "Badge colors must come from tokens, not literal values")
  end

  # `red` and `destructive` used to resolve to identical CSS, so the two spellings
  # were indistinguishable. They are now separate systems: a semantic family
  # follows the application's brand, a hue stays the color it names.
  test "keeps semantic families and decorative hues independently themeable" do
    css = NitroKit::Engine.root.join(
      "src/stylesheets/nitro_kit/components/palette.css"
    ).read

    { destructive: :red, success: :green, warning: :amber }.each do |semantic, hue|
      assert_includes css, "--_nk-semantic-accent: var(--nk-palette-#{semantic})"
      assert_includes css, "--_nk-semantic-accent: var(--nk-palette-#{hue})"
    end

    tokens = NitroKit::Engine.root.join("src/stylesheets/nitro_kit/tokens.css").read
    NitroKit::Badge::PALETTE_COLORS.each do |hue|
      assert_includes tokens, "--nk-palette-#{hue}:"
      assert_includes tokens, "--nk-palette-#{hue}-content:"
    end
  end

  test "pairs each tint with its own readable foreground" do
    css = NitroKit::Engine.root.join(
      "src/stylesheets/nitro_kit/components/badge.css"
    ).read

    assert_includes css, "color: var(--_nk-semantic-content)"
    assert_includes css, "var(--_nk-semantic-accent) var(--_nk-badge-tint-strength)"
    refute_includes css, "--_nk-palette-"
  end

  private

  def render_node(component, &block)
    Nokogiri::HTML.fragment(component.call(&block)).first_element_child
  end
end
