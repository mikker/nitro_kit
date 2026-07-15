require "test_helper"

class AlertTest < ActiveSupport::TestCase
  class ProbeIcon < NitroKit::Component
    def initialize
      super(component: :probe_icon)
    end

    def view_template
      svg(**root_attributes)
    end
  end

  test "renders every variant as owned component data" do
    assert_predicate NitroKit::Alert::VARIANTS, :frozen?

    NitroKit::Alert::VARIANTS.each do |variant|
      node = render_node(NitroKit::Alert.new(variant:))

      assert_equal "alert", node["data-nk"]
      assert_equal variant.to_s, node["data-variant"]
      assert_nil node["role"]
      refute node.key?("class")
      refute node.key?("style")
    end
  end

  test "renders qualified title and description slots" do
    component = NitroKit::Alert.new
    node = render_node(
      component,
      &proc do |alert|
        alert.title("A balanced title", html: { id: "title" })
        alert.description(aria: { live: "polite" }) { "A useful description" }
      end
    )

    title = node.at_css("[data-slot='alert-title']")
    description = node.at_css("[data-slot='alert-description']")

    assert_equal "title", title["id"]
    assert_equal "A balanced title", title.text
    assert_equal "polite", description["aria-live"]
    assert_equal "A useful description", description.text
  end

  test "renders a nested component in the qualified icon slot" do
    node = render_node(NitroKit::Alert.new) do |alert|
      alert.icon(ProbeIcon.new)
      alert.title("Heads up")
    end
    icon = node.at_css("[data-slot='alert-icon']")

    assert_equal "probe-icon", icon["data-nk"]
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

    assert_raises(ArgumentError) { NitroKit::Alert.new(class: "utility") }
    assert_raises(ArgumentError) { NitroKit::Alert.new(style: "display: none") }
    assert_raises(ArgumentError) { NitroKit::Alert.new(role: "status") }
    assert_raises(ArgumentError) { NitroKit::Alert.new(html: { role: "status" }) }
    assert_raises(ArgumentError) do
      NitroKit::Alert.new.call { |alert| alert.icon(Object.new) }
    end
    assert_raises(ArgumentError) { NitroKit::Alert.new(live: :loud) }
    assert_raises(ArgumentError) do
      NitroKit::Alert.new.call do |alert|
        alert.title("First")
        alert.title("Second")
      end
    end

    node = render_node(NitroKit::Alert.new(desperately_need_a_class: "external-alert"))
    assert_equal "external-alert", node["class"]
    assert_equal "class", node["data-nk-escape"]
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
