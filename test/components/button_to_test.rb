require "test_helper"

class ButtonToTest < ActiveSupport::TestCase
  test "renders a Rails method form around a slotted Button" do
    node = render_node(
      NitroKit::ButtonTo.new(
        "Delete account",
        href: "/account",
        method: :delete,
        variant: :destructive,
        data: { turbo_confirm: "Delete everything?" },
        button_data: { action: "click->analytics#track" }
      )
    )
    button = node.at_css("[data-slot='button-to-button']")

    assert_equal "form", node.name
    assert_equal "button-to", node["data-nk"]
    assert_equal "/account", node["action"]
    assert_equal "post", node["method"]
    assert_equal "delete", node.at_css("input[name='_method']")["value"]
    assert_equal "Delete everything?", node["data-turbo-confirm"]
    assert_equal "button", button.name
    assert_equal "submit", button["type"]
    assert_equal "destructive", button["data-variant"]
    assert_equal "click->analytics#track", button["data-action"]
  end

  test "supports icon-only accessible actions and every Rails method" do
    NitroKit::ButtonTo::METHODS.each do |method|
      node = render_node(
        NitroKit::ButtonTo.new(nil, href: "/records/1", method:, icon: :trash, label: "Delete record")
      )

      assert_equal "Delete record", node.at_css("button")["aria-label"]
    end
  end

  test "validates destination and method" do
    assert_raises(ArgumentError) { NitroKit::ButtonTo.new("Save", href: "") }
    assert_raises(ArgumentError) { NitroKit::ButtonTo.new("Save", href: :account) }
    assert_raises(ArgumentError) { NitroKit::ButtonTo.new("Save", href: "/", method: :trace) }
  end

  test "ships a layout-transparent form root" do
    source = NitroKit::Engine.root.join("src/stylesheets/nitro_kit/components/button_to.css").read

    assert_includes source, ':where([data-nk="button-to"])'
    assert_includes source, "display: contents"
  end

  private

  def render_node(component, &block)
    html = ApplicationController.renderer.render(component, &block)
    Nokogiri::HTML.fragment(html).at_css("[data-nk='button-to']")
  end
end
