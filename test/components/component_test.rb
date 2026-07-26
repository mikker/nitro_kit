require "test_helper"

class ComponentTest < ActiveSupport::TestCase
  class Probe < NitroKit::Component
    VARIANTS = %i[default primary].freeze
    SIZES = %i[sm md].freeze

    def initialize(
      variant: :default,
      size: :md,
      id: nil,
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil
    )
      validate_choice!(:variant, variant, VARIANTS)
      validate_choice!(:size, size, SIZES)

      super(
        component: :probe,
        attributes: { id: },
        html:,
        aria:,
        data:,
        variant:,
        size:,
        desperately_need_a_class:
      )
    end

    def view_template
      div(**root_attributes)
    end
  end

  class BehaviorProbe < NitroKit::Component
    def initialize(data: {})
      super(
        component: :behavior_probe,
        attributes: {
          data: {
            controller: "nk--probe",
            action: "click->nk--probe#open",
            state: "closed"
          }
        },
        data:
      )
    end

    def view_template
      div(**root_attributes)
    end
  end

  class InternalDataProbe < NitroKit::Component
    def initialize(key)
      super(component: :internal_data_probe, attributes: { data: { key => "override" } })
    end

    def view_template
      div(**root_attributes)
    end
  end

  class SlotProbe < NitroKit::Component
    def initialize(slot_html: {}, slot_aria: {}, slot_data: {}, slot_class: nil, slot_variant: nil)
      @slot_html = slot_html
      @slot_aria = slot_aria
      @slot_data = slot_data
      @slot_class = slot_class
      @slot_variant = slot_variant

      super(component: :slot_probe)
    end

    def view_template
      section(**root_attributes) do
        span(
          **slot_attributes(
            :label,
            html: @slot_html,
            aria: @slot_aria,
            data: @slot_data,
            variant: @slot_variant,
            desperately_need_a_class: @slot_class
          )
        ) { "Label" }

        div(**slot_attributes(:slot_probe_content)) { "Content" }
      end
    end
  end

  class NestedChild < NitroKit::Component
    def initialize
      super(component: :nested_child, variant: :quiet, size: :sm, data: { tracking_id: "child" })
    end

    def view_template
      article(**root_attributes) { yield if block_given? }
    end
  end

  class NestedParent < NitroKit::Component
    def initialize(child: NestedChild.new, duplicate: false)
      @child = child
      @duplicate = duplicate

      super(component: :nested_parent)
    end

    def view_template
      section(**root_attributes) do
        render_in_slot(@child, :content) { span { "Forwarded content" } }
        render_in_slot(@child, :other) if @duplicate
      end
    end
  end

  test "renders component identity, variant, and size" do
    node = render_node(Probe.new(variant: :primary, size: :sm))

    assert_equal "probe", node["data-nk"]
    assert_equal "primary", node["data-variant"]
    assert_equal "sm", node["data-size"]
    refute node.key?("class")
    refute node.key?("style")
  end

  test "does not expose mutable owned attributes" do
    refute_respond_to Probe.new, :attrs
  end

  test "keeps HTML, ARIA, and data attributes in explicit boundaries" do
    node = render_node(
      Probe.new(
        id: "example",
        html: { title: "Example", tabindex: 0, hidden: true },
        aria: { label: "Example probe" },
        data: { tracking_id: "abc123" }
      )
    )

    assert_equal "example", node["id"]
    assert_equal "Example", node["title"]
    assert_equal "0", node["tabindex"]
    assert node.key?("hidden")
    assert_equal "Example probe", node["aria-label"]
    assert_equal "abc123", node["data-tracking-id"]
  end

  test "rejects unknown component options" do
    error = assert_raises(ArgumentError) { Probe.new(typoed_variant: :primary) }

    assert_match(/unknown keyword/, error.message)
  end

  test "rejects direct and nested classes and styles" do
    assert_raises(ArgumentError) { Probe.new(class: "utility") }
    assert_raises(ArgumentError) { Probe.new(style: "display: none") }

    %i[class style].each do |attribute|
      error = assert_raises(ArgumentError) { Probe.new(html: { attribute => "value" }) }
      assert_match(/#{attribute}: is not allowed/, error.message)
    end

    assert_raises(ArgumentError) do
      NitroKit::Component.new(component: :probe, attributes: { class: "internal-utility" })
    end
  end

  test "rejects every normalized spelling of reserved data attributes" do
    reserved_data_keys = [
      :nk,
      "data-nk",
      :data_nk,
      :slot,
      "data-slot",
      :data_variant,
      "variant",
      :size,
      "data_size",
      :state,
      "data-state",
      :nk_escape,
      "data-nk-escape",
      :enhanced,
      :disabled,
      :required,
      :orientation,
      :presentation,
      :placement,
      :layout,
      :field_type,
      "data-field-type"
    ]

    reserved_data_keys.each do |key|
      error = assert_raises(ArgumentError) { Probe.new(data: { key => "override" }) }
      assert_match(/is reserved by Nitro Kit/, error.message, "Expected #{key.inspect} to be reserved")
    end
  end

  test "separates component-owned data from base-owned identity" do
    owned = NitroKit::Component::COMPONENT_OWNED_DATA_ATTRIBUTES
    reserved = NitroKit::Component::RESERVED_DATA_ATTRIBUTES

    assert_equal owned, owned & reserved
    assert_equal "closed", render_node(BehaviorProbe.new)["data-state"]

    (reserved - owned).each do |key|
      error = assert_raises(ArgumentError) { InternalDataProbe.new(key).call }
      assert_match(/Use the component or slot API for data-#{key}/, error.message)
    end
  end

  test "rejects reserved data attributes through the HTML boundary" do
    %w[data-nk data_slot data-variant data_size data-nk-escape].each do |key|
      error = assert_raises(ArgumentError) { Probe.new(html: { key => "override" }) }
      assert_match(/through data:/, error.message)
    end

    assert_raises(ArgumentError) { Probe.new(html: { data: { nk: "override" } }) }
    assert_raises(ArgumentError) { Probe.new(html: { aria: { label: "override" } }) }
  end

  test "adds application controllers and actions after Nitro behavior" do
    node = render_node(
      BehaviorProbe.new(
        data: {
          controller: "application",
          action: "keydown->application#handle",
          tracking_id: "behavior"
        }
      )
    )

    assert_equal "nk--probe application", node["data-controller"]
    assert_equal "click->nk--probe#open keydown->application#handle", node["data-action"]
    assert_equal "closed", node["data-state"]
    assert_equal "behavior", node["data-tracking-id"]
  end

  test "rejects application overrides of component-owned data" do
    error = assert_raises(ArgumentError) { BehaviorProbe.new(data: { state: "open" }) }

    assert_match(/data-state is reserved by Nitro Kit/, error.message)
  end

  test "renders the observable class escape hatch" do
    node = render_node(Probe.new(desperately_need_a_class: "third-party-trigger"))

    assert_equal "third-party-trigger", node["class"]
    assert_equal "class", node["data-nk-escape"]
  end

  test "validates the class escape hatch" do
    [ "", "   ", false, :utility, [ "utility" ] ].each do |value|
      error = assert_raises(ArgumentError) { Probe.new(desperately_need_a_class: value) }
      assert_match(/must be a non-blank String/, error.message)
    end
  end

  test "qualifies slots and applies the same attribute boundaries" do
    node = render_node(
      SlotProbe.new(
        slot_html: { title: "Field label" },
        slot_aria: { hidden: true },
        slot_data: { condition: "ready" }
      )
    )
    label = node.at_css("[data-slot='slot-probe-label']")
    content = node.at_css("[data-slot='slot-probe-content']")

    assert_equal "slot-probe", node["data-nk"]
    assert_equal "Field label", label["title"]
    assert_equal "true", label["aria-hidden"]
    assert_equal "ready", label["data-condition"]
    assert content
  end

  test "supports the class escape on an owned slot" do
    node = render_node(SlotProbe.new(slot_class: "external-label"))
    label = node.at_css("[data-slot='slot-probe-label']")

    assert_equal "external-label", label["class"]
    assert_equal "class", label["data-nk-escape"]
  end

  test "rejects reserved slot data" do
    error = assert_raises(ArgumentError) { SlotProbe.new(slot_data: { slot: "other" }).call }

    assert_match(/data-slot is reserved/, error.message)
    assert_match(/data-variant is reserved/, assert_raises(ArgumentError) do
      SlotProbe.new(slot_data: { variant: "destructive" }).call
    end.message)
  end

  test "emits an owned variant on a slot without a nested component" do
    node = render_node(SlotProbe.new(slot_variant: :destructive, slot_data: { condition: "ready" }))
    label = node.at_css("[data-slot='slot-probe-label']")

    assert_equal "destructive", label["data-variant"]
    assert_equal "ready", label["data-condition"]
    assert_nil node.at_css("[data-slot='slot-probe-content']")["data-variant"]
    assert_raises(ArgumentError) { SlotProbe.new(slot_variant: "  ").call }
    assert_raises(ArgumentError) { SlotProbe.new(slot_variant: "Not Valid").call }
  end

  test "validates closed choices immediately" do
    variant_error = assert_raises(ArgumentError) { Probe.new(variant: :loud) }
    size_error = assert_raises(ArgumentError) { Probe.new(size: :xl) }

    assert_match(/Unknown variant :loud/, variant_error.message)
    assert_match(/:default, :primary/, variant_error.message)
    assert_match(/Unknown size :xl/, size_error.message)
    assert_match(/:sm, :md/, size_error.message)
  end

  test "normalizes underscored identities" do
    node = render_node(BehaviorProbe.new)

    assert_equal "behavior-probe", node["data-nk"]
  end

  test "rejects unstable component identities" do
    [ "Uppercase", "two words", "with/slash", "with.dot", "snowman-☃" ].each do |identity|
      error = assert_raises(ArgumentError) { NitroKit::Component.new(component: identity) }
      assert_match(/only lowercase letters, numbers, and hyphens/, error.message)
    end

    error = assert_raises(ArgumentError) { NitroKit::Component.new(component: "   ") }
    assert_match(/cannot be blank/, error.message)
  end

  test "requires hash attribute boundaries" do
    %i[html aria data].each do |boundary|
      error = assert_raises(ArgumentError) { Probe.new(**{ boundary => "invalid" }) }
      assert_match(/#{boundary} must be a Hash/, error.message)
    end
  end

  test "places a nested component without replacing its identity or state" do
    node = render_node(NestedParent.new)
    child = node.at_css("[data-slot='nested-parent-content']")

    assert_equal "nested-child", child["data-nk"]
    assert_equal "quiet", child["data-variant"]
    assert_equal "sm", child["data-size"]
    assert_equal "child", child["data-tracking-id"]
  end

  test "forwards blocks through nested component slots" do
    node = render_node(NestedParent.new)

    assert_equal "Forwarded content", node.at_css("[data-slot='nested-parent-content'] span").text
  end

  test "rejects attaching a nested component more than once" do
    error = assert_raises(ArgumentError) { NestedParent.new(duplicate: true).call }

    assert_match(/already attached to a slot/, error.message)
  end

  private

  def render_node(component)
    Nokogiri::HTML.fragment(component.call).first_element_child
  end
end
