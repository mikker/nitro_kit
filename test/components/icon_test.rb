require "test_helper"

class IconTest < ActiveSupport::TestCase
  test "renders every size and shares the Button size vocabulary" do
    assert_predicate NitroKit::Icon::SIZES, :frozen?
    assert_equal NitroKit::Button::SIZES, NitroKit::Icon::SIZES

    NitroKit::Icon::SIZES.each do |size|
      node = render_node(NitroKit::Icon.new(:save, size:))

      assert_equal "svg", node.name
      assert_equal "icon", node["data-nk"]
      assert_equal size.to_s, node["data-size"]
      assert_equal "0 0 24 24", node["viewbox"]
      assert_equal "currentColor", node["stroke"]
      assert_empty node.css("[class], [style]")
    end

    assert_equal "xl", render_node(NitroKit::Icon.new(:save, size: :xl))["data-size"]
    assert_raises(ArgumentError) { NitroKit::Icon.new(:save, size: :huge) }
    assert_raises(ArgumentError) { NitroKit::Icon.new(:save, size: nil) }
  end

  test "normalizes underscored names and raises for unknown icons" do
    assert_equal "circle-user", NitroKit::Icon.new(:circle_user).name
    assert_equal "circle-user", NitroKit::Icon.new("circle-user").name
    assert_equal "svg", render_node(NitroKit::Icon.new(:circle_user)).name

    error = assert_raises(ArgumentError) { NitroKit::Icon.new(:definitely_not_an_icon) }
    assert_match(/Unknown icon.*definitely-not-an-icon/, error.message)
    assert_raises(ArgumentError) { NitroKit::Icon.new("") }
  end

  test "renders decorative and meaningful icons and raises on ARIA collisions" do
    decorative = render_node(NitroKit::Icon.new(:save))
    meaningful = render_node(NitroKit::Icon.new(:save, label: "Saved", aria: { describedby: "help" }))

    assert_equal "true", decorative["aria-hidden"]
    assert_nil decorative["role"]
    assert_equal "Saved", meaningful["aria-label"]
    assert_equal "false", meaningful["aria-hidden"]
    assert_equal "img", meaningful["role"]
    assert_equal "help", meaningful["aria-describedby"]
    assert_empty meaningful.css("[class], [style]")
    assert_raises(ArgumentError) { NitroKit::Icon.new(:save, label: " ") }
    assert_raises(ArgumentError) { NitroKit::Icon.new(:save, label: :saved) }

    hidden_collision = assert_raises(ArgumentError) { NitroKit::Icon.new(:save, aria: { hidden: false }) }
    label_collision = assert_raises(ArgumentError) do
      NitroKit::Icon.new(:save, label: "Saved", aria: { label: "Wrong" })
    end

    assert_match(/Duplicate ARIA attribute hidden/, hidden_collision.message)
    assert_match(/Duplicate ARIA attribute label/, label_collision.message)
  end

  test "validates stroke width against its closed numeric range" do
    assert_equal 1.5, NitroKit::Icon.new(:save).stroke_width
    assert_equal "2", render_node(NitroKit::Icon.new(:save, stroke_width: 2))["stroke-width"]
    assert_equal "0.5", render_node(NitroKit::Icon.new(:save, stroke_width: 0.5))["stroke-width"]
    assert_equal "4", render_node(NitroKit::Icon.new(:save, stroke_width: 4))["stroke-width"]

    [ "1.5", nil, 0, 12, 4.5 ].each do |stroke_width|
      assert_match(
        /stroke_width/,
        assert_raises(ArgumentError) { NitroKit::Icon.new(:save, stroke_width:) }.message
      )
    end
  end

  test "passes through id and composes application attributes" do
    node = render_node(
      NitroKit::Icon.new(
        :save,
        id: "save-glyph",
        html: { title: "Save" },
        aria: { describedby: "save-help" },
        data: { tracking_id: "save" }
      )
    )

    assert_equal "save-glyph", node["id"]
    assert_equal "Save", node["title"]
    assert_equal "save-help", node["aria-describedby"]
    assert_equal "save", node["data-tracking-id"]
  end

  test "rejects reserved Nitro data and emits the deliberate class escape" do
    node = render_node(NitroKit::Icon.new(:save, desperately_need_a_class: "external-icon-hook"))

    assert_equal "external-icon-hook", node["class"]
    assert_equal "class", node["data-nk-escape"]
    assert_raises(ArgumentError) { NitroKit::Icon.new(:save, desperately_need_a_class: "") }

    %i[nk slot size variant].each do |reserved|
      assert_match(/reserved by Nitro Kit/, assert_raises(ArgumentError) do
        NitroKit::Icon.new(:save, data: { reserved => "replacement" })
      end.message)
    end
    assert_raises(ArgumentError) { NitroKit::Icon.new(:save, html: { class: "utility" }) }
    assert_raises(ArgumentError) { NitroKit::Icon.new(:save, html: { style: "display: none" }) }
  end

  test "is reachable through the gallery catalog" do
    entry = Gallery::Catalog.fetch!(kind: :component, slug: "icon")

    assert_equal Gallery::Components::IconPage, entry.page
    assert_includes entry.expected_roots, "icon"
  end

  private

  def render_node(component)
    Nokogiri::HTML.fragment(component.call).first_element_child
  end
end
