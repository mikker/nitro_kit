require "test_helper"

class SheetTest < ActiveSupport::TestCase
  test "renders a native side panel with stable relationships" do
    node = render_sheet do |sheet|
      sheet.trigger("Prompts", icon: :list, data: { action: "click->analytics#track" })
      sheet.panel(title: "Transcript prompts", description: "Jump to a prompt") do
        "Navigation"
      end
    end
    trigger = node.at_css("[data-slot='sheet-trigger']")
    panel = node.at_css("dialog[data-slot='sheet-panel']")

    assert_equal "sheet", node["data-nk"]
    assert_equal "right", node["data-side"]
    assert_equal "md", node["data-size"]
    assert_equal "show-modal", trigger["command"]
    assert_equal "#{node['id']}-panel", trigger["commandfor"]
    assert_equal "dialog", trigger["aria-haspopup"]
    assert_equal "any", panel["closedby"]
    assert_equal "Transcript prompts", panel.at_css("[data-slot='sheet-title']").text
    assert_equal "Jump to a prompt", panel.at_css("[data-slot='sheet-description']").text
    assert_equal "Navigation", panel.at_css("[data-slot='sheet-body']").text
    assert_equal "close", panel.at_css("[data-slot='sheet-close']")["command"]
  end

  test "covers both sides and every width" do
    NitroKit::Sheet::SIDES.product(NitroKit::Sheet::SIZES).each do |side, size|
      node = render_sheet(NitroKit::Sheet.new(id: "sheet-#{side}-#{size}", side:, size:)) do |sheet|
        sheet.trigger("Open")
        sheet.panel(title: "Panel")
      end

      assert_equal side.to_s, node["data-side"]
      assert_equal size.to_s, node["data-size"]
    end
  end

  test "requires one trigger one panel and valid closed options" do
    assert_raises(ArgumentError) { NitroKit::Sheet.new(id: "") }
    assert_raises(ArgumentError) { NitroKit::Sheet.new(id: "sheet", side: :top) }
    assert_raises(ArgumentError) { NitroKit::Sheet.new(id: "sheet", size: :xl) }
    assert_raises(ArgumentError) { NitroKit::Sheet.new(id: "sheet", close_label: "") }
    assert_raises(ArgumentError) { NitroKit::Sheet.new(id: "sheet").call }
    assert_raises(ArgumentError) do
      NitroKit::Sheet.new(id: "sheet").call { |sheet| sheet.panel(title: "Panel") }
    end
    assert_raises(ArgumentError) do
      NitroKit::Sheet.new(id: "sheet").call { |sheet| sheet.trigger("Open") }
    end
  end

  test "ships side-aware static CSS and reuses the focused dialog controller" do
    source = NitroKit::Engine.root.join("src/stylesheets/nitro_kit/components/sheet.css").read
    node = render_sheet do |sheet|
      sheet.trigger("Open")
      sheet.panel(title: "Panel")
    end

    assert_includes source, ':where([data-nk="sheet"])'
    assert_includes source, "display: contents"
    assert_includes source, 'data-side="left"'
    assert_includes source, 'data-side="right"'
    assert_includes source, "prefers-reduced-motion"
    assert_equal "nk--dialog", node["data-controller"]
  end

  private

  def render_sheet(component = NitroKit::Sheet.new(id: "transcript-prompts"), &block)
    Nokogiri::HTML.fragment(component.call(&block)).first_element_child
  end
end
