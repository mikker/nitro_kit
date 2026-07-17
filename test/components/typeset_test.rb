require "test_helper"

class TypesetTest < ActiveSupport::TestCase
  test "renders rich semantic content without classes" do
    node = render_typeset(id: "article") { "A useful article." }

    assert_equal "typeset", node["data-nk"]
    assert_equal "article", node["id"]
    assert_equal "A useful article.", node.text
    assert_empty node.css("[class], [style]")
  end

  test "requires content and keeps attributes bounded" do
    assert_raises(ArgumentError) { NitroKit::Typeset.new.call }
    assert_raises(ArgumentError) { NitroKit::Typeset.new(class: "prose") }
    assert_raises(ArgumentError) { NitroKit::Typeset.new(html: { style: "x" }) }

    node = render_typeset(
      html: { lang: "en" },
      data: { controller: "article" },
      aria: { label: "Article" }
    ) { p { "Body" } }

    assert_equal "en", node["lang"]
    assert_equal "article", node["data-controller"]
    assert_equal "Article", node["aria-label"]
  end

  test "ships streaming-stable styles and an opt-out boundary" do
    css = NitroKit::Engine.root.join(
      "src/stylesheets/nitro_kit/components/typeset.css"
    ).read

    assert_includes css, "--nk-typeset-flow"
    assert_includes css, '[data-typeset="off"]'
    assert_includes css, '[data-nk]:not([data-nk="typeset"])'
    refute_includes css, ":last-child"
    refute_includes css, ":has("
    refute_includes css, ":empty"
  end

  private
    def render_typeset(**attributes, &block)
      component = NitroKit::Typeset.new(**attributes)
      Nokogiri::HTML.fragment(component.call(&block)).first_element_child
    end
end
