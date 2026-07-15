require "test_helper"

class ButtonIconTest < ActiveSupport::TestCase
  LabelObject = Data.define(:value) do
    def to_s = value
  end

  test "renders every variant and size without classes" do
    assert_predicate NitroKit::Button::VARIANTS, :frozen?
    assert_predicate NitroKit::Button::SIZES, :frozen?

    NitroKit::Button::VARIANTS.product(NitroKit::Button::SIZES).each do |variant, size|
      node = render_node(NitroKit::Button.new("Save", variant:, size:))

      assert_equal "button", node["data-nk"]
      assert_equal variant.to_s, node["data-variant"]
      assert_equal size.to_s, node["data-size"]
      assert_equal "Save", node.at_css("[data-slot='button-label']").text
      assert_empty node.css("[class], [style]")
    end
  end

  test "uses the default treatment when the ordinary action omits variant" do
    node = render_node(NitroKit::Button.new("Save changes"))

    assert_equal "default", node["data-variant"]
  end

  test "keeps label and icon structure stable for text and block content" do
    text_node = render_node(NitroKit::Button.new(LabelObject.new("Object label"), icon: :save))
    block_node = render_node(NitroKit::Button.new(icon_right: :arrow_right)) { "Block label" }

    assert_equal "Object label", text_node.at_css("[data-slot='button-label']").text
    assert_equal "icon", text_node.at_css("[data-slot='button-icon-start'] svg")["data-nk"]
    assert_equal "Block label", block_node.at_css("[data-slot='button-label']").text
    assert_equal "icon", block_node.at_css("[data-slot='button-icon-end'] svg")["data-nk"]
  end

  test "renders native links and accessible disabled links" do
    enabled = render_node(NitroKit::Button.new("Read", href: "/docs"))
    disabled = render_node(NitroKit::Button.new("Read", href: "/docs", disabled: true))

    assert_equal "a", enabled.name
    assert_equal "/docs", enabled["href"]
    assert_nil disabled["href"]
    assert_equal "true", disabled["aria-disabled"]
    assert_equal "-1", disabled["tabindex"]
  end

  test "does not allow disabled link semantics to be overridden" do
    aria_error = assert_raises(ArgumentError) do
      NitroKit::Button.new("Read", href: "/docs", disabled: true, aria: { disabled: false })
    end
    href_error = assert_raises(ArgumentError) do
      NitroKit::Button.new("Read", href: "/docs", disabled: true, html: { href: "/bypass" })
    end

    assert_match(/Duplicate ARIA attribute disabled/, aria_error.message)
    assert_match(/Duplicate HTML attribute href/, href_error.message)
  end

  test "requires accessible names for icon-only buttons" do
    error = assert_raises(ArgumentError) { NitroKit::Button.new(icon: :x).call }
    assert_match(/aria.*label/, error.message)

    node = render_node(NitroKit::Button.new(icon: :x, aria: { label: "Close" }))
    assert_equal "Close", node["aria-label"]
    assert_nil node.at_css("[data-slot='button-label']")
  end

  test "uses Flux icon geometry for labelled and square buttons" do
    labelled = render_node(NitroKit::Button.new("Export", icon: :download))
    square = render_node(NitroKit::Button.new(icon: :ellipsis, aria: { label: "More" }))

    assert_equal "sm", labelled.at_css("[data-nk='icon']")["data-size"]
    assert_equal "md", square.at_css("[data-nk='icon']")["data-size"]
  end

  test "validates closed vocabularies and native button type" do
    assert_raises(ArgumentError) { NitroKit::Button.new("Save", variant: :loud) }
    assert_raises(ArgumentError) { NitroKit::Button.new("Save", size: :huge) }
    assert_raises(ArgumentError) { NitroKit::Button.new("Save", type: :link) }
    assert_raises(ArgumentError) { NitroKit::Button.new("Save", type: nil) }
    assert_raises(ArgumentError) { NitroKit::Button.new("Save", disabled: "false") }
    assert_raises(ArgumentError) { NitroKit::Button.new("Save", class: "utility") }
    assert_raises(ArgumentError) { NitroKit::Button.new("").call }
    assert_raises(ArgumentError) { NitroKit::Button.new("Text").call { "Block" } }
    assert_raises(ArgumentError) { NitroKit::Button.new("Link", href: "") }
    assert_raises(ArgumentError) { NitroKit::Button.new("Link", href: "/", name: "action") }
    assert_raises(ArgumentError) { NitroKit::Button.new("Button", target: "_blank") }
  end

  test "renders decorative and meaningful icons with owned ARIA" do
    decorative = render_node(NitroKit::Icon.new(:save, aria: { hidden: false }))
    meaningful = render_node(NitroKit::Icon.new(:save, label: "Saved", aria: { label: "Wrong", hidden: true }))

    assert_equal "true", decorative["aria-hidden"]
    assert_equal "Saved", meaningful["aria-label"]
    assert_equal "false", meaningful["aria-hidden"]
    assert_equal "img", meaningful["role"]
    assert_empty meaningful.css("[class], [style]")
    assert_raises(ArgumentError) { NitroKit::Icon.new(:save, label: " ") }
  end

  private

  def render_node(component, &block)
    Nokogiri::HTML.fragment(component.call(&block)).first_element_child
  end
end
