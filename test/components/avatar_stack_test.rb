require "test_helper"

class AvatarStackTest < ActiveSupport::TestCase
  test "renders slotted avatars at the stack size" do
    node = render_node(NitroKit::AvatarStack.new(size: :sm, label: "Reviewers")) do |stack|
      stack.avatar(src: "https://example.test/ada.png", alt: "Ada Lovelace")
      stack.avatar(alt: "Grace Hopper")
      stack.overflow(4)
    end

    avatars = node.css("[data-slot='avatar-stack-avatar']")
    overflow = node.at_css("[data-slot='avatar-stack-overflow']")

    assert_equal "avatar-stack", node["data-nk"]
    assert_equal "sm", node["data-size"]
    assert_equal "group", node["role"]
    assert_equal "Reviewers", node["aria-label"]
    assert_equal 2, avatars.count
    assert avatars.all? { |avatar| avatar["data-nk"] == "avatar" }
    assert avatars.all? { |avatar| avatar["data-size"] == "sm" }
    assert_equal "+4", overflow.text
    assert_equal I18n.t("nitro_kit.avatar_stack.overflow", count: 4), overflow["aria-label"]
    assert_empty node.css("[class], [style]")
  end

  test "renders every stack size" do
    assert_predicate NitroKit::AvatarStack::SIZES, :frozen?

    NitroKit::AvatarStack::SIZES.each do |size|
      node = render_node(NitroKit::AvatarStack.new(size:, label: "Team")) { |stack| stack.overflow(2) }

      assert_equal size.to_s, node["data-size"]
      assert_equal "+2", node.at_css("[data-slot='avatar-stack-overflow']").text
    end
  end

  test "derives the overflow indicator from max" do
    node = render_node(NitroKit::AvatarStack.new(label: "Participants", max: 2)) do |stack|
      5.times { |index| stack.avatar(alt: "Person #{index}") }
    end

    assert_equal 2, node.css("[data-slot='avatar-stack-avatar']").count
    assert_equal "+3", node.at_css("[data-slot='avatar-stack-overflow']").text
    assert_equal I18n.t("nitro_kit.avatar_stack.overflow", count: 3), node.at_css("[data-slot='avatar-stack-overflow']")["aria-label"]
  end

  test "omits the overflow indicator when max is not exceeded" do
    node = render_node(NitroKit::AvatarStack.new(label: "Participants", max: 4)) do |stack|
      2.times { |index| stack.avatar(alt: "Person #{index}") }
    end

    assert_equal 2, node.css("[data-slot='avatar-stack-avatar']").count
    assert_nil node.at_css("[data-slot='avatar-stack-overflow']")
  end

  test "renders the overflow indicator last regardless of declaration order" do
    node = render_node(NitroKit::AvatarStack.new(label: "Reviewers")) do |stack|
      stack.overflow(2)
      stack.avatar(alt: "Ada Lovelace")
    end

    assert_equal(
      %w[avatar-stack-avatar avatar-stack-overflow],
      node.element_children.map { |child| child["data-slot"] }
    )
  end

  test "supports accessible overflow and explicit slot attributes" do
    node = render_node(NitroKit::AvatarStack.new(label: "Reviewers")) do |stack|
      stack.overflow(
        12,
        label: "12 additional reviewers",
        html: { title: "More reviewers" },
        aria: { describedby: "reviewer-help" },
        data: { tracking_id: "overflow" }
      )
    end
    overflow = node.at_css("[data-slot='avatar-stack-overflow']")

    assert_equal "Reviewers", node["aria-label"]
    assert_equal "12 additional reviewers", overflow["aria-label"]
    assert_equal "More reviewers", overflow["title"]
    assert_equal "reviewer-help", overflow["aria-describedby"]
    assert_equal "overflow", overflow["data-tracking-id"]
  end

  test "keeps label ownership explicit across normalized ARIA keys" do
    assert_match(/group label is owned/, assert_raises(ArgumentError) do
      NitroKit::AvatarStack.new(label: "Reviewers", aria: { "label" => "Override" })
    end.message)

    assert_match(/overflow label is owned/, assert_raises(ArgumentError) do
      render_node(NitroKit::AvatarStack.new(label: "Reviewers")) do |stack|
        stack.overflow(2, label: "Two more teammates", aria: { "label" => "Override" })
      end
    end.message)
  end

  test "validates the group name stack size max and overflow count" do
    assert_raises(ArgumentError) { NitroKit::AvatarStack.new }
    [ nil, "", :reviewers ].each do |label|
      assert_raises(ArgumentError) { NitroKit::AvatarStack.new(label:) }
    end
    assert_raises(ArgumentError) { NitroKit::AvatarStack.new(label: "Team", size: :xl) }
    [ 0, -1, 1.5, "2" ].each do |max|
      assert_raises(ArgumentError) { NitroKit::AvatarStack.new(label: "Team", max:) }
    end

    [ 0, -1, 1.5, "2" ].each do |count|
      error = assert_raises(ArgumentError) do
        NitroKit::AvatarStack.new(label: "Team").call { |stack| stack.overflow(count) }
      end
      assert_match(/positive Integer/, error.message)
    end

    assert_raises(ArgumentError) do
      NitroKit::AvatarStack.new(label: "Team").call { |stack| stack.overflow(2, label: :more) }
    end
    assert_raises(ArgumentError) do
      NitroKit::AvatarStack.new(label: "Team").call { |stack| stack.avatar(size: :lg) }
    end
    assert_raises(ArgumentError) do
      NitroKit::AvatarStack.new(label: "Team").call do |stack|
        stack.overflow(2)
        stack.overflow(3)
      end
    end
    assert_match(/max: already owns/, assert_raises(ArgumentError) do
      NitroKit::AvatarStack.new(label: "Team", max: 1).call do |stack|
        stack.avatar(alt: "Ada Lovelace")
        stack.overflow(2)
      end
    end.message)

    component = NitroKit::AvatarStack.new(label: "Team")
    assert_match(
      /inside the render block/,
      assert_raises(ArgumentError) { component.avatar(alt: "Too early") }.message
    )
  end

  test "supports root attributes and the class escape hatch" do
    node = render_node(
      NitroKit::AvatarStack.new(
        label: "Reviewers",
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
