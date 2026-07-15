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
    assert_nil node["data-controller"]
    assert_equal "dialog", panel.name
    assert_equal "delete-account-panel", panel["id"]
    refute panel.key?("open")
    assert_equal "delete-account-title", panel["aria-labelledby"]
    assert_equal "delete-account-description", panel["aria-describedby"]
    assert_equal "show-modal", trigger["command"]
    assert_equal "delete-account-panel", trigger["commandfor"]
    assert_equal "dialog", trigger["aria-haspopup"]
    assert_equal "click->analytics#track", trigger["data-action"]
    assert_equal "close", close["command"]
    assert_equal "delete-account-panel", close["commandfor"]
    assert_equal "click->analytics#track", close["data-action"]
    assert_equal "Close dialog", close["aria-label"]
    assert_equal "ghost", close["data-variant"]
    assert_equal "sm", close["data-size"]
    assert_empty node.css("[class], [style]")
  end

  test "supports an explicitly non-modal open panel and omits an absent description" do
    node = render_node(NitroKit::Dialog.new(id: "notice")) do |dialog|
      dialog.dialog(title: "Notice", nonmodal: true)
    end

    assert node.at_css("dialog").key?("open")
    assert_nil node.at_css("dialog")["aria-describedby"]
    assert_nil node.at_css("[data-slot='dialog-description']")
  end

  test "collects one panel and at most one trigger into fixed root order" do
    node = render_node(NitroKit::Dialog.new(id: "ordered")) do |dialog|
      dialog.dialog(title: "Panel") { dialog.close_button }
      dialog.trigger("Open")
    end

    assert_equal %w[dialog-trigger dialog-panel], node.element_children.map { |child| child["data-slot"] }
    assert_equal 1, node.css("#ordered-title").size
    assert_equal 1, node.css("#ordered-panel").size

    assert_match(/declaration block/, assert_raises(ArgumentError) do
      NitroKit::Dialog.new(id: "missing").call
    end.message)
    assert_match(/requires exactly one panel/, assert_raises(ArgumentError) do
      NitroKit::Dialog.new(id: "missing").call { |dialog| dialog.trigger("Open") }
    end.message)
    assert_match(/at most one trigger/, assert_raises(ArgumentError) do
      NitroKit::Dialog.new(id: "duplicate-trigger").call do |dialog|
        dialog.trigger("One")
        dialog.trigger("Two")
        dialog.dialog(title: "Panel")
      end
    end.message)
    assert_match(/exactly one panel/, assert_raises(ArgumentError) do
      NitroKit::Dialog.new(id: "duplicate-panel").call do |dialog|
        dialog.dialog(title: "One")
        dialog.dialog(title: "Two")
      end
    end.message)
    assert_match(/inside the panel block/, assert_raises(ArgumentError) do
      NitroKit::Dialog.new(id: "leaked-close").call do |dialog|
        dialog.close_button
        dialog.dialog(title: "Panel")
      end
    end.message)
    assert_match(/at most one close button/, assert_raises(ArgumentError) do
      NitroKit::Dialog.new(id: "duplicate-close").call do |dialog|
        dialog.dialog(title: "Panel") do
          dialog.close_button
          dialog.close_button
        end
      end
    end.message)
  end

  test "requires a stable explicit id and rejects collisions with owned relationships" do
    assert_raises(ArgumentError) { NitroKit::Dialog.new }
    [ nil, "", "two words", :dialog ].each do |id|
      assert_raises(ArgumentError) { NitroKit::Dialog.new(id:) }
    end

    assert_raises(ArgumentError) do
      render_node(NitroKit::Dialog.new(id: "notice")) do |dialog|
        dialog.dialog(title: "Notice", aria: { labelledby: "wrong" })
      end
    end

    assert_raises(ArgumentError) do
      NitroKit::Dialog.new(id: "notice").call { |dialog| dialog.dialog(title: " ") }
    end
    assert_raises(ArgumentError) do
      NitroKit::Dialog.new(id: "notice").call { |dialog| dialog.dialog(title: "Notice", nonmodal: "false") }
    end
    [ false, " " ].each do |description|
      assert_raises(ArgumentError) do
        NitroKit::Dialog.new(id: "notice").call { |dialog| dialog.dialog(title: "Notice", description:) }
      end
    end

    assert_raises(ArgumentError) do
      NitroKit::Dialog.new(id: "notice").call do |dialog|
        dialog.trigger("Open", html: { command: "close" })
      end
    end
    assert_raises(ArgumentError) do
      NitroKit::Dialog.new(id: "notice").call do |dialog|
        dialog.dialog(title: "Notice") do
          dialog.close_button(html: { commandfor: "somewhere-else" })
        end
      end
    end
  end

  private

  def render_node(component, &block)
    Nokogiri::HTML.fragment(component.call(&block)).first_element_child
  end
end
