require "test_helper"

class TooltipComponentTest < ActiveSupport::TestCase
  class CustomTriggerTooltip < Phlex::HTML
    def view_template
      render NitroKit::Tooltip.new(id: "delete-help", content: "Deletes this record permanently") do |tooltip|
        tooltip.trigger(as: :custom) do |attributes|
          render NitroKit::ButtonTo.new(
            nil,
            href: "/records/1",
            method: :delete,
            icon: :trash,
            label: "Delete record",
            button_html: attributes.html,
            button_aria: attributes.aria,
            button_data: attributes.data
          )
        end
      end
    end
  end

  test "puts the tooltip relationship on the actual focusable trigger" do
    node = render_tooltip do |tooltip|
      tooltip.trigger("Explain", data: { action: "click->analytics#track" })
    end
    trigger = node.at_css("[data-slot='tooltip-trigger']")
    content = node.at_css("[data-slot='tooltip-content']")

    assert_equal "help", node["id"]
    assert_equal "tooltip", node["data-nk"]
    assert_equal "top", node["data-placement"]
    assert_nil node["data-state"]
    assert_equal "nk--tooltip", node["data-controller"]
    assert_includes node["data-action"], "pointerleave->nk--tooltip#resetIfUninterested"
    assert_includes node["data-action"], "focusout->nk--tooltip#resetIfUninterested"

    assert_equal "button", trigger.name
    assert_equal "help-trigger", trigger["id"]
    assert_equal "help-content", trigger["aria-describedby"]
    assert_includes trigger["data-action"], "keydown.esc->nk--tooltip#dismiss"
    assert_includes trigger["data-action"], "click->analytics#track"

    assert_equal "help-content", content["id"]
    assert_equal "tooltip", content["role"]
    assert_nil content["data-state"]
    refute content.key?("hidden")
    assert_equal "Helpful context", content.text
    assert_empty node.css("[class], [style]")
  end

  test "supports every placement and an owned button block" do
    NitroKit::Tooltip::PLACEMENTS.each do |placement|
      node = render_tooltip(NitroKit::Tooltip.new(id: "tip-#{placement}", content: "Context", placement:)) do |tip|
        tip.trigger { "Details" }
      end

      assert_equal placement.to_s, node["data-placement"]
      assert_equal "Details", node.at_css("[data-slot='button-label']").text
    end
  end

  test "supports an accessible icon-only trigger" do
    node = render_tooltip do |tooltip|
      tooltip.trigger(icon: :copy, aria: { label: "Copy" })
    end

    trigger = node.at_css("[data-slot='tooltip-trigger']")
    assert_equal "Copy", trigger["aria-label"]
    assert trigger.at_css("svg[data-nk='icon'] path")
    refute_includes trigger.text, "NitroKit::Button"
  end

  test "supports linked Button triggers" do
    node = render_tooltip do |tooltip|
      tooltip.trigger("Documentation", href: "/docs", target: "_blank", rel: "noopener")
    end
    trigger = node.at_css("[data-slot='tooltip-trigger']")

    assert_equal "a", trigger.name
    assert_equal "/docs", trigger["href"]
    assert_equal "_blank", trigger["target"]
    assert_equal "help-content", trigger["aria-describedby"]
  end

  test "yields owned attributes to a custom focusable trigger" do
    html = ApplicationController.renderer.render(CustomTriggerTooltip.new)
    node = Nokogiri::HTML.fragment(html).first_element_child
    trigger = node.at_css("button")

    assert_equal "delete-help-trigger", trigger["id"]
    assert_equal "delete-help-content", trigger["aria-describedby"]
    assert_includes trigger["data-action"], "keydown.esc->nk--tooltip#dismiss"
    assert_equal "Delete record", trigger["aria-label"]
    assert_equal "tooltip-trigger", trigger.ancestors.find { |ancestor| ancestor["data-slot"] }["data-slot"]
  end

  test "supports an explicit focusable HTML trigger without pretending it is a Button" do
    node = render_tooltip do |tooltip|
      tooltip.trigger("Build status", as: :div)
    end
    trigger = node.at_css("[data-slot='tooltip-trigger']")

    assert_equal "div", trigger.name
    assert_equal "0", trigger["tabindex"]
    assert_equal "help-content", trigger["aria-describedby"]
  end

  test "appends its content to existing trigger descriptions" do
    node = render_tooltip do |tooltip|
      tooltip.trigger("Explain", aria: { describedby: "account-help status-help" })
    end

    assert_equal "account-help status-help help-content",
      node.at_css("[data-slot='tooltip-trigger']")["aria-describedby"]
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
    assert_raises(ArgumentError) do
      NitroKit::Tooltip.new(id: "tip", content: "Context").call do |tooltip|
        tooltip.trigger("Open", as: NitroKit::Card)
      end
    end
    assert_raises(ArgumentError) do
      NitroKit::Tooltip.new(id: "tip", content: "Context").call do |tooltip|
        tooltip.trigger(as: :custom) { "No attributes" }
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
    assert_raises(ArgumentError) { NitroKit::Tooltip.new(id: "tip", content: "Context", data: { dismissed: true }) }
  end

  test "uses CSS for hover and focus while JavaScript only owns Escape dismissal" do
    source = NitroKit::Engine.root.join("src/stylesheets/nitro_kit/components/tooltip.css").read
    controller = NitroKit::Engine.root.join("app/javascript/controllers/nk/tooltip_controller.js").read

    assert_includes source, ":focus-within"
    assert_includes source, "@media (hover: hover)"
    assert_includes source, ":not([data-dismissed])"
    assert_includes source, "visibility: hidden"
    assert_includes source, "color: var(--nk-color-foreground)"
    assert_includes source, "background: var(--nk-color-elevated)"
    assert_includes source, "border: var(--nk-border-width) solid var(--nk-color-border)"
    refute_includes source, "background: var(--nk-color-primary)"
    assert_equal 5, source.scan("::before").size
    assert_includes source, "inset-block-start: 100%"
    assert_includes source, "inset-inline-end: 100%"
    assert_includes source, "inset-block-end: 100%"
    assert_includes source, "inset-inline-start: 100%"
    assert_includes controller, "dismiss(event)"
    assert_includes controller, "event.preventDefault()"
    refute_includes controller, "hidden ="
    refute_includes controller, "openValue"
  end

  private

  def render_tooltip(component = NitroKit::Tooltip.new(id: "help", content: "Helpful context"), &block)
    Nokogiri::HTML.fragment(component.call(&block)).first_element_child
  end
end
