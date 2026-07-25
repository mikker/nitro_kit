require "test_helper"

class AvatarTest < ActiveSupport::TestCase
  IMAGE_URL = "https://example.test/avatar.png"

  test "renders every size with a native image and fallback" do
    assert_predicate NitroKit::Avatar::SIZES, :frozen?

    NitroKit::Avatar::SIZES.each do |size|
      node = render_node(NitroKit::Avatar.new(IMAGE_URL, alt: "Ada Lovelace", size:))
      image = node.at_css("[data-slot='avatar-image']")
      fallback = node.at_css("[data-slot='avatar-fallback']")

      assert_equal "avatar", node["data-nk"]
      assert_equal size.to_s, node["data-size"]
      assert_equal IMAGE_URL, image["src"]
      assert_equal "Ada Lovelace", image["alt"]
      assert_equal "lazy", image["loading"]
      assert_equal "async", image["decoding"]
      assert_equal "AL", fallback.text
      assert_equal "true", fallback["aria-hidden"]
      refute node.key?("class")
      refute node.key?("style")
    end
  end

  test "supports keyword sources and explicit fallbacks" do
    node = render_node(
      NitroKit::Avatar.new(src: IMAGE_URL, alt: "Ada Lovelace", fallback: "NK")
    )

    assert_equal IMAGE_URL, node.at_css("img")["src"]
    assert_equal "NK", node.at_css("[data-slot='avatar-fallback']").text
  end

  test "renders an accessible fallback when no image is available" do
    node = render_node(NitroKit::Avatar.new(alt: "Grace Brewster Hopper"))

    assert_equal "img", node["role"]
    assert_equal "Grace Brewster Hopper", node["aria-label"]
    assert_equal "GH", node.at_css("[data-slot='avatar-fallback']").text
    assert_nil node.at_css("img")
  end

  test "keeps an unnamed fallback exposed instead of inventing an accessible name" do
    node = render_node(NitroKit::Avatar.new)
    fallback = node.at_css("[data-slot='avatar-fallback']")

    assert_nil node["role"]
    assert_nil node["aria-label"]
    assert_nil fallback["aria-hidden"]
    assert_equal "?", fallback.text
  end

  test "keeps root attributes explicit" do
    node = render_node(
      NitroKit::Avatar.new(
        alt: "Ada Lovelace",
        id: "ada",
        html: { title: "Profile photo" },
        aria: { label: "Profile: Ada" },
        data: { tracking_id: "avatar-1" }
      )
    )

    assert_equal "ada", node["id"]
    assert_equal "Profile photo", node["title"]
    assert_equal "Profile: Ada", node["aria-label"]
    assert_equal "avatar-1", node["data-tracking-id"]
  end

  test "validates closed and accessibility options" do
    assert_raises(ArgumentError) { NitroKit::Avatar.new(size: :xl) }
    assert_raises(ArgumentError) { NitroKit::Avatar.new(IMAGE_URL, src: IMAGE_URL) }
    assert_raises(ArgumentError) { NitroKit::Avatar.new(alt: nil) }
    assert_raises(ArgumentError) { NitroKit::Avatar.new(fallback: 42) }
    assert_raises(ArgumentError) { NitroKit::Avatar.new(class: "utility") }
  end

  test "supports the class escape hatch without adding internal classes" do
    node = render_node(
      NitroKit::Avatar.new(alt: "Ada", desperately_need_a_class: "external-avatar")
    )

    assert_equal "external-avatar", node["class"]
    assert_equal "class", node["data-nk-escape"]
    assert_empty node.css("[style]")
  end

  private

  def render_node(component)
    Nokogiri::HTML.fragment(component.call).first_element_child
  end
end
