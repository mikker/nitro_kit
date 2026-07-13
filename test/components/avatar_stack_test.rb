require "test_helper"

class AvatarStackTest < ActiveSupport::TestCase
  test "renders slotted avatars at the stack size" do
    node = render_node(NitroKit::AvatarStack.new(size: :sm)) do |stack|
      stack.avatar("https://example.test/ada.png", alt: "Ada Lovelace")
      stack.avatar(nil, alt: "Grace Hopper")
      stack.overflow(4)
    end

    avatars = node.css("[data-slot='avatar-stack-avatar']")
    overflow = node.at_css("[data-slot='avatar-stack-overflow']")

    assert_equal "avatar-stack", node["data-nk"]
    assert_equal "sm", node["data-size"]
    assert_equal "group", node["role"]
    assert_equal 2, avatars.count
    assert avatars.all? { |avatar| avatar["data-nk"] == "avatar" }
    assert avatars.all? { |avatar| avatar["data-size"] == "sm" }
    assert_equal "+4", overflow.text
    assert_equal "4 more avatars", overflow["aria-label"]
    assert_empty node.css("[class], [style]")
  end

  test "renders every stack size" do
    assert_predicate NitroKit::AvatarStack::SIZES, :frozen?

    NitroKit::AvatarStack::SIZES.each do |size|
      node = render_node(NitroKit::AvatarStack.new(size:)) { |stack| stack.overflow(2) }

      assert_equal size.to_s, node["data-size"]
      assert_equal "+2", node.at_css("[data-slot='avatar-stack-overflow']").text
    end
  end

  test "supports accessible overflow and explicit slot attributes" do
    node = render_node(NitroKit::AvatarStack.new(aria: { label: "Reviewers" })) do |stack|
      stack.overflow(
        12,
        label: "12 additional reviewers",
        html: { title: "More reviewers" },
        aria: { label: "Do not override the explicit label" },
        data: { tracking_id: "overflow" }
      )
    end
    overflow = node.at_css("[data-slot='avatar-stack-overflow']")

    assert_equal "Reviewers", node["aria-label"]
    assert_equal "12 additional reviewers", overflow["aria-label"]
    assert_equal "More reviewers", overflow["title"]
    assert_equal "overflow", overflow["data-tracking-id"]
  end

  test "keeps overflow label ownership explicit across normalized ARIA keys" do
    node = render_node(NitroKit::AvatarStack.new) do |stack|
      stack.overflow(2, label: "Two more teammates", aria: { "label" => "Override" })
    end

    assert_equal "Two more teammates", node.at_css("[data-slot='avatar-stack-overflow']")["aria-label"]
  end

  test "validates stack size and overflow count" do
    assert_raises(ArgumentError) { NitroKit::AvatarStack.new(size: :xl) }

    [ 0, -1, 1.5, "2" ].each do |count|
      error = assert_raises(ArgumentError) do
        NitroKit::AvatarStack.new.call { |stack| stack.overflow(count) }
      end
      assert_match(/positive Integer/, error.message)
    end

    assert_raises(ArgumentError) do
      NitroKit::AvatarStack.new.call { |stack| stack.overflow(2, label: :more) }
    end
    assert_raises(ArgumentError) do
      NitroKit::AvatarStack.new.call { |stack| stack.avatar(nil, size: :lg) }
    end
  end

  test "supports root attributes and the class escape hatch" do
    node = render_node(
      NitroKit::AvatarStack.new(
        id: "reviewers",
        data: { tracking_id: "reviewers" },
        desperately_need_a_class: "external-stack"
      )
    )

    assert_equal "reviewers", node["id"]
    assert_equal "reviewers", node["data-tracking-id"]
    assert_equal "external-stack", node["class"]
    assert_equal "class", node["data-nk-escape"]
  end

  private

  def render_node(component, &block)
    Nokogiri::HTML.fragment(component.call(&block)).first_element_child
  end
end
