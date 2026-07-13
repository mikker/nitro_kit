require "test_helper"

class ButtonGroupTest < ActiveSupport::TestCase
  test "accepts Button children and gives each a qualified slot" do
    node = render_node(
      NitroKit::ButtonGroup.new(
        buttons: [
          NitroKit::Button.new("Save", variant: :primary),
          NitroKit::Button.new("Cancel", href: "/cancel")
        ]
      )
    )
    buttons = node.xpath("./*[@data-slot='button-group-button']")

    assert_equal "button-group", node["data-nk"]
    assert_equal "group", node["role"]
    assert_equal 2, buttons.count
    assert_equal %w[button a], buttons.map(&:name)
    assert buttons.all? { |button| button["data-nk"] == "button" }
    assert_empty node.css("[class], [style]")
  end

  test "constructs buttons with links icons disabled state and long labels" do
    long_label = "Export every selected record as a comma-separated value file"
    node = render_node(NitroKit::ButtonGroup.new(label: "Record actions")) do |group|
      group.button(long_label, href: "/exports", icon: "download")
      group.button("Archive", icon_right: "archive", disabled: true)
      group.button(nil, icon: "trash-2", aria: { label: "Delete records" })
    end
    buttons = node.xpath("./*[@data-slot='button-group-button']")

    assert_equal "Record actions", node["aria-label"]
    assert_equal long_label, buttons.first.at_css("[data-slot='button-label']").text
    assert buttons.first.at_css("[data-slot='button-icon-start'] [data-nk='icon']")
    assert buttons[1].key?("disabled")
    assert buttons[1].at_css("[data-slot='button-icon-end'] [data-nk='icon']")
    assert_equal "Delete records", buttons[2]["aria-label"]
    assert_nil buttons[2].at_css("[data-slot='button-label']")
  end

  test "preserves render-time content for constructed and accepted buttons" do
    accepted = NitroKit::Button.new
    node = render_node(NitroKit::ButtonGroup.new) do |group|
      group.button(href: "/older") { "A long custom action label" }
      group.add(accepted) { "Accepted child" }
    end

    assert_equal [ "A long custom action label", "Accepted child" ],
      node.css("[data-slot='button-label']").map(&:text)
  end

  test "keeps root attributes explicit" do
    node = render_node(
      NitroKit::ButtonGroup.new(
        buttons: [ NitroKit::Button.new("Save") ],
        id: "record-actions",
        html: { title: "Record actions" },
        aria: { describedby: "actions-help" },
        data: { tracking_id: "actions-1" }
      )
    )

    assert_equal "record-actions", node["id"]
    assert_equal "Record actions", node["title"]
    assert_equal "actions-help", node["aria-describedby"]
    assert_equal "actions-1", node["data-tracking-id"]
  end

  test "rejects empty and untyped collections" do
    assert_raises(ArgumentError) { NitroKit::ButtonGroup.new.call }
    assert_raises(ArgumentError) { NitroKit::ButtonGroup.new(buttons: NitroKit::Button.new("One")) }
    assert_raises(ArgumentError) { NitroKit::ButtonGroup.new(buttons: [ Object.new ]) }
    assert_raises(ArgumentError) do
      NitroKit::ButtonGroup.new.call { |group| group.add(Object.new) }
    end
  end

  test "rejects duplicate children and invalid root semantics" do
    button = NitroKit::Button.new("Repeated")

    assert_raises(ArgumentError) { NitroKit::ButtonGroup.new(buttons: [ button, button ]) }
    assert_raises(ArgumentError) do
      NitroKit::ButtonGroup.new(buttons: [ button ]).call { |group| group.add(button) }
    end
    assert_raises(ArgumentError) { NitroKit::ButtonGroup.new(label: "") }
    assert_raises(ArgumentError) { NitroKit::ButtonGroup.new(label: :actions) }
    assert_raises(ArgumentError) { NitroKit::ButtonGroup.new(aria: "invalid") }
    assert_raises(ArgumentError) do
      NitroKit::ButtonGroup.new(
        buttons: [ NitroKit::Button.new("Save") ],
        html: { role: "toolbar" }
      )
    end
  end

  test "surfaces invalid Button contracts" do
    assert_raises(ArgumentError) do
      NitroKit::ButtonGroup.new.call { |group| group.button("Save", variant: :loud) }
    end
    assert_raises(ArgumentError) do
      NitroKit::ButtonGroup.new.call { |group| group.button }
    end
    assert_raises(ArgumentError) do
      NitroKit::ButtonGroup.new.call { |group| group.button("Save", class: "utility") }
    end
  end

  test "supports the class escape hatch without Nitro-authored classes" do
    node = render_node(
      NitroKit::ButtonGroup.new(
        buttons: [ NitroKit::Button.new("Save") ],
        desperately_need_a_class: "external-group"
      )
    )

    assert_equal "external-group", node["class"]
    assert_equal "class", node["data-nk-escape"]
    assert_empty node.css("[style]")
  end

  private

  def render_node(component, &block)
    Nokogiri::HTML.fragment(component.call(&block)).first_element_child
  end
end
