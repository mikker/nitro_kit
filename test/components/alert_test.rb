require "test_helper"

class AlertTest < ActiveSupport::TestCase
  test "renders every variant as owned component data" do
    assert_predicate NitroKit::Alert::VARIANTS, :frozen?
    assert_equal NitroKit::Toast::Item::VARIANTS, NitroKit::Alert::VARIANTS

    NitroKit::Alert::VARIANTS.each do |variant|
      node = render_node(NitroKit::Alert.new(variant:))

      assert_equal "alert", node["data-nk"]
      assert_equal variant.to_s, node["data-variant"]
      assert_nil node["data-color"]
      assert_nil node["role"]
      refute node.key?("class")
      refute node.key?("style")
    end
  end

  test "takes its colors from the shared semantic palette, not a private one" do
    refute NitroKit::Alert.const_defined?(:COLORS, false)
    refute NitroKit::Alert.const_defined?(:VARIANT_PALETTE, false),
      "Alert no longer maps variants to hue families; the palette resolves them from tokens"

    css = NitroKit::Engine.root.join("src/stylesheets/nitro_kit/components/palette.css").read
    NitroKit::Alert::VARIANTS.each do |variant|
      assert_includes css, %([data-nk="alert"][data-variant="#{variant}"])
    end

    alert_css = NitroKit::Engine.root.join("src/stylesheets/nitro_kit/components/alert.css").read
    assert_includes alert_css, %([data-nk="alert"][data-variant])
    refute_includes alert_css, "data-color"
    refute_includes alert_css, "--_nk-palette-"
    refute_match(/oklch\(/, alert_css)
  end

  # The defect this replaces: Alert resolved its colors from a private hardcoded
  # palette while Toast resolved the same variant names from `--nk-color-*`, so
  # one "success" rendered as two different greens and rethemeing moved only one
  # of them.
  test "renders identically to a Toast of the same variant" do
    palette = NitroKit::Engine.root.join("src/stylesheets/nitro_kit/components/palette.css").read
    alert_css = NitroKit::Engine.root.join("src/stylesheets/nitro_kit/components/alert.css").read
    toast_css = NitroKit::Engine.root.join("src/stylesheets/nitro_kit/components/toast.css").read

    assert_equal NitroKit::Toast::Item::VARIANTS, NitroKit::Alert::VARIANTS

    NitroKit::Alert::VARIANTS.each do |variant|
      assert_includes palette, %([data-nk="alert"][data-variant="#{variant}"])
      assert_includes palette, %([data-nk="toast-item"][data-variant="#{variant}"])
    end

    %w[surface border content].each do |part|
      assert_includes alert_css, "var(--_nk-semantic-#{part})"
      assert_includes toast_css, "var(--_nk-semantic-#{part})"
    end

    refute_match(/oklch\(/, toast_css)
    refute_includes toast_css, "var(--nk-color-info)"
  end

  test "accepts constructor text and matching compound declarations" do
    constructor = render_node(
      NitroKit::Alert.new(title: "Scheduled maintenance", description: "Deploys pause tonight.")
    )
    compound = render_node(NitroKit::Alert.new) do |alert|
      alert.title("Scheduled maintenance")
      alert.description { "Deploys pause tonight." }
    end

    [ constructor, compound ].each do |node|
      assert_equal "Scheduled maintenance", node.at_css("[data-slot='alert-title']").text
      assert_equal "Deploys pause tonight.", node.at_css("[data-slot='alert-description']").text
    end
  end

  test "renders declared regions in owned order regardless of declaration order" do
    node = render_node(NitroKit::Alert.new) do |alert|
      alert.description("A useful description")
      alert.title("A balanced title")
      alert.icon(NitroKit::Icon.new(:info))
    end

    assert_equal(
      %w[alert-icon alert-title alert-description],
      node.element_children.map { |child| child["data-slot"] }
    )
  end

  test "renders a nested Icon in the qualified icon slot" do
    node = render_node(NitroKit::Alert.new) do |alert|
      alert.icon(NitroKit::Icon.new(:circle_check))
      alert.title("Heads up")
    end
    icon = node.at_css("[data-slot='alert-icon']")

    assert_equal "icon", icon["data-nk"]
    assert_equal "svg", icon.name
  end

  test "keeps root HTML ARIA and data attributes explicit" do
    node = render_node(
      NitroKit::Alert.new(
        id: "notice",
        html: { title: "Status notice" },
        aria: { atomic: true },
        data: { tracking_id: "notice-1" }
      )
    )

    assert_equal "notice", node["id"]
    assert_nil node["role"]
    assert_equal "Status notice", node["title"]
    assert_equal "true", node["aria-atomic"]
    assert_equal "notice-1", node["data-tracking-id"]
  end

  test "escapes content and emits no Nitro classes" do
    node = render_node(NitroKit::Alert.new) do |alert|
      alert.title("<script>unsafe()</script>")
      alert.description("<b>plain text</b>")
    end

    assert_equal "<script>unsafe()</script>", node.at_css("[data-slot='alert-title']").text
    assert_equal "<b>plain text</b>", node.at_css("[data-slot='alert-description']").text
    assert_empty node.css("script, b, [class], [style]")
  end

  test "validates options and supports the class escape hatch" do
    error = assert_raises(ArgumentError) { NitroKit::Alert.new(variant: :loud) }
    assert_match(/Unknown variant :loud/, error.message)
    assert_raises(ArgumentError) { NitroKit::Alert.new(color: :red) }

    assert_raises(ArgumentError) { NitroKit::Alert.new(class: "utility") }
    assert_raises(ArgumentError) { NitroKit::Alert.new(style: "display: none") }
    assert_raises(ArgumentError) { NitroKit::Alert.new(role: "status") }
    assert_raises(ArgumentError) { NitroKit::Alert.new(html: { role: "status" }) }
    assert_raises(ArgumentError) { NitroKit::Alert.new(title: "") }
    assert_raises(ArgumentError) do
      NitroKit::Alert.new.call { |alert| alert.icon(Object.new) }
    end
    assert_raises(ArgumentError) do
      NitroKit::Alert.new.call { |alert| alert.icon(NitroKit::Badge.new("Nope")) }
    end
    assert_raises(ArgumentError) { NitroKit::Alert.new(live: :loud) }
    assert_raises(ArgumentError) do
      NitroKit::Alert.new.call do |alert|
        alert.title("First")
        alert.title("Second")
      end
    end
    assert_raises(ArgumentError) do
      NitroKit::Alert.new(title: "Constructor").call { |alert| alert.title("Compound") }
    end

    node = render_node(NitroKit::Alert.new(desperately_need_a_class: "external-alert"))
    assert_equal "external-alert", node["class"]
    assert_equal "class", node["data-nk-escape"]
  end

  test "rejects declarations outside the render block" do
    component = NitroKit::Alert.new

    assert_match(
      /inside the render block/,
      assert_raises(ArgumentError) { component.title("Too early") }.message
    )
    assert_raises(ArgumentError) { component.description("Too early") }
    assert_raises(ArgumentError) { component.icon(NitroKit::Icon.new(:info)) }
  end

  test "opts into live-region semantics deliberately" do
    assert_equal "status", render_node(NitroKit::Alert.new(live: :polite))["role"]
    assert_equal "alert", render_node(NitroKit::Alert.new(live: :assertive))["role"]
  end

  private

  def render_node(component, &block)
    Nokogiri::HTML.fragment(component.call(&block)).first_element_child
  end
end
