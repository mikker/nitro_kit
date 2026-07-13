require "test_helper"

class DialogTest < ActiveSupport::TestCase
  test "renders a stable native dialog contract and accessible controls" do
    node = render_node(NitroKit::Dialog.new(id: "delete-account")) do |dialog|
      dialog.trigger("Delete", data: { action: "click->analytics#track" })
      dialog.dialog(title: "Delete account", description: "This cannot be undone") do
        dialog.close_button(data: { action: "click->analytics#track" })
      end
    end
    panel = node.at_css("[data-slot='dialog-panel']")
    trigger = node.at_css("[data-slot='dialog-trigger']")
    close = node.at_css("[data-slot='dialog-close']")

    assert_equal "delete-account", node["id"]
    assert_equal "dialog", node["data-nk"]
    assert_equal "nk--dialog", node["data-controller"]
    assert_equal "dialog", panel.name
    assert_equal "closed", panel["data-state"]
    assert_equal "delete-account-title", panel["aria-labelledby"]
    assert_equal "delete-account-description", panel["aria-describedby"]
    assert_includes trigger["data-action"], "click->nk--dialog#open"
    assert_includes trigger["data-action"], "click->analytics#track"
    assert_includes close["data-action"], "click->nk--dialog#close"
    assert_includes close["data-action"], "click->analytics#track"
    assert_equal "Close dialog", close["aria-label"]
    assert_empty node.css("[class], [style]")
  end

  test "omits description relationship when no description is declared" do
    node = render_node(NitroKit::Dialog.new(id: "notice")) do |dialog|
      dialog.dialog(title: "Notice")
    end

    assert_nil node.at_css("dialog")["aria-describedby"]
    assert_nil node.at_css("[data-slot='dialog-description']")
  end

  test "requires a stable explicit id and protects owned ARIA" do
    assert_raises(ArgumentError) { NitroKit::Dialog.new }
    [ nil, "", "two words", :dialog ].each do |id|
      assert_raises(ArgumentError) { NitroKit::Dialog.new(id:) }
    end

    node = render_node(NitroKit::Dialog.new(id: "notice")) do |dialog|
      dialog.dialog(title: "Notice", aria: { labelledby: "wrong" })
    end
    assert_equal "notice-title", node.at_css("dialog")["aria-labelledby"]

    assert_raises(ArgumentError) do
      NitroKit::Dialog.new(id: "notice").call { |dialog| dialog.dialog(title: " ") }
    end
    assert_raises(ArgumentError) do
      NitroKit::Dialog.new(id: "notice").call { |dialog| dialog.dialog(title: "Notice", open: "false") }
    end
    [ false, " " ].each do |description|
      assert_raises(ArgumentError) do
        NitroKit::Dialog.new(id: "notice").call { |dialog| dialog.dialog(title: "Notice", description:) }
      end
    end
  end

  private

  def render_node(component, &block)
    Nokogiri::HTML.fragment(component.call(&block)).first_element_child
  end
end
