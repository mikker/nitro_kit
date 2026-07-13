require "test_helper"

class TooltipComponentTest < ActiveSupport::TestCase
  test "puts the tooltip relationship on the actual focusable trigger" do
    node = render_tooltip do |tooltip|
      tooltip.trigger("Explain", data: { action: "click->analytics#track" })
    end
    trigger = node.at_css("[data-slot='tooltip-trigger']")
    content = node.at_css("[data-slot='tooltip-content']")

    assert_equal "help", node["id"]
    assert_equal "tooltip", node["data-nk"]
    assert_equal "top", node["data-placement"]
    assert_equal "closed", node["data-state"]
    assert_equal "nk--tooltip", node["data-controller"]
    assert_equal "false", node["data-nk--tooltip-open-value"]

    assert_equal "button", trigger.name
    assert_equal "help-trigger", trigger["id"]
    assert_equal "help-content", trigger["aria-describedby"]
    assert_includes trigger["data-action"], "focusin->nk--tooltip#open"
    assert_includes trigger["data-action"], "pointerenter->nk--tooltip#open"
    assert_includes trigger["data-action"], "click->analytics#track"

    assert_equal "help-content", content["id"]
    assert_equal "tooltip", content["role"]
    assert_equal "closed", content["data-state"]
    assert content.key?("hidden")
    assert_equal "Helpful context", content.text
    assert_empty node.css("[class], [style]")
  end

  test "supports every placement and an owned button block" do
    NitroKit::Tooltip::PLACEMENTS.each do |placement|
      node = render_tooltip(NitroKit::Tooltip.new(id: "tip-#{placement}", content: "Context", placement:)) do |tip|
        tip.trigger(variant: :ghost) { "Details" }
      end

      assert_equal placement.to_s, node["data-placement"]
      assert_equal "Details", node.at_css("[data-slot='button-label']").text
    end
  end

  test "requires valid identity content and exactly one supported trigger" do
    assert_raises(ArgumentError) { NitroKit::Tooltip.new }

    [ nil, "", "two words", :tip ].each do |id|
      assert_raises(ArgumentError) { NitroKit::Tooltip.new(id:, content: "Context") }
    end
    [ nil, "", " ", :content ].each do |content|
      assert_raises(ArgumentError) { NitroKit::Tooltip.new(id: "tip", content:) }
    end
    assert_raises(ArgumentError) { NitroKit::Tooltip.new(id: "tip", content: "Context", placement: :center) }
    assert_match(/trigger declaration block/, assert_raises(ArgumentError) do
      NitroKit::Tooltip.new(id: "tip", content: "Context").call
    end.message)
    assert_match(/requires one trigger/, assert_raises(ArgumentError) do
      NitroKit::Tooltip.new(id: "tip", content: "Context").call { }
    end.message)

    component = NitroKit::Tooltip.new(id: "tip", content: "Context")
    assert_match(/inside the render block/, assert_raises(ArgumentError) { component.trigger("Open") }.message)
    assert_raises(ArgumentError) do
      component.call do |tooltip|
        tooltip.trigger("One")
        tooltip.trigger("Two")
      end
    end
    assert_raises(ArgumentError) do
      NitroKit::Tooltip.new(id: "tip", content: "Context").call do |tooltip|
        tooltip.trigger("Open", disabled: true)
      end
    end
  end

  test "keeps root attributes bounded and rejects arbitrary classes" do
    component = NitroKit::Tooltip.new(
      id: "tip",
      content: "Context",
      html: { title: "More" },
      aria: { label: "Explanation" },
      data: { controller: "application" },
      desperately_need_a_class: "tooltip-hook"
    )
    node = render_tooltip(component) { |tooltip| tooltip.trigger("Explain") }

    assert_equal "More", node["title"]
    assert_equal "Explanation", node["aria-label"]
    assert_equal "nk--tooltip application", node["data-controller"]
    assert_equal "tooltip-hook", node["class"]
    assert_equal "class", node["data-nk-escape"]
    assert_raises(ArgumentError) { NitroKit::Tooltip.new(id: "tip", content: "Context", html: { style: "x" }) }
  end

  private

  def render_tooltip(component = NitroKit::Tooltip.new(id: "help", content: "Helpful context"), &block)
    Nokogiri::HTML.fragment(component.call(&block)).first_element_child
  end
end
