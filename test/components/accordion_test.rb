require "test_helper"

class AccordionTest < ActiveSupport::TestCase
  test "renders keyed items with deterministic ARIA relationships and visible state" do
    node = render_accordion do |accordion|
      accordion.item(:general, title: "General", expanded: true) { "General content" }
      accordion.item(:billing_details, title: "Billing", disabled: true) { "Billing content" }
    end

    items = node.css("[data-slot='accordion-item']")
    general_trigger = items.first.at_css("[data-slot='accordion-trigger']")
    general_content = items.first.at_css("[data-slot='accordion-content']")
    billing_trigger = items.last.at_css("[data-slot='accordion-trigger']")
    billing_content = items.last.at_css("[data-slot='accordion-content']")

    assert_equal "faq", node["id"]
    assert_equal "accordion", node["data-nk"]
    assert_equal "nk--accordion", node["data-controller"]
    assert_equal "multiple", node["data-mode"]
    assert_equal "multiple", node["data-nk--accordion-mode-value"]

    assert_equal "general", items.first["data-key"]
    assert_equal "open", items.first["data-state"]
    assert_equal "faq-general-trigger", general_trigger["id"]
    assert_equal "faq-general-content", general_trigger["aria-controls"]
    assert_equal "true", general_trigger["aria-expanded"]
    assert_equal "faq-general-content", general_content["id"]
    assert_equal "faq-general-trigger", general_content["aria-labelledby"]
    assert_equal "false", general_content["aria-hidden"]
    refute general_content.key?("hidden")
    assert_equal "General content", general_content.text

    assert_equal "billing-details", items.last["data-key"]
    assert billing_trigger.key?("disabled")
    assert_equal "false", billing_trigger["aria-expanded"]
    assert_equal "true", billing_content["aria-hidden"]
    assert billing_content.key?("hidden")
    assert_equal "closed", billing_content["data-state"]
    assert_empty node.css("[class], [style]")
  end

  test "renders single mode and keeps public attributes inside their boundaries" do
    component = NitroKit::Accordion.new(
      id: "preferences",
      mode: :single,
      html: { title: "Preferences" },
      aria: { label: "Preference sections" },
      data: { controller: "application", tracking_id: "prefs" }
    )
    node = render_accordion(component) do |accordion|
      accordion.item(:account, title: "Account") { "Account content" }
    end

    assert_equal "single", node["data-mode"]
    assert_equal "single", node["data-nk--accordion-mode-value"]
    assert_equal "Preferences", node["title"]
    assert_equal "Preference sections", node["aria-label"]
    assert_equal "nk--accordion application", node["data-controller"]
    assert_equal "prefs", node["data-tracking-id"]
  end

  test "keeps reserved attributes owned and makes the class escape observable" do
    assert_raises(ArgumentError) { NitroKit::Accordion.new(id: "faq", data: { state: "open" }) }
    assert_raises(ArgumentError) { NitroKit::Accordion.new(id: "faq", html: { class: "utility" }) }
    assert_raises(ArgumentError) { NitroKit::Accordion.new(id: "faq", html: { style: "display:none" }) }

    component = NitroKit::Accordion.new(id: "faq", desperately_need_a_class: "external-accordion")
    node = render_accordion(component) do |accordion|
      accordion.item(:one, title: "One") { "Content" }
    end

    assert_equal "external-accordion", node["class"]
    assert_equal "class", node["data-nk-escape"]
  end

  test "requires an explicit stable id" do
    assert_raises(ArgumentError) { NitroKit::Accordion.new }

    [ nil, "", "   ", "two words", :faq, 123 ].each do |id|
      error = assert_raises(ArgumentError) { NitroKit::Accordion.new(id:) }
      assert_match(/id must be a non-blank String without whitespace/, error.message)
    end
  end

  test "validates the closed mode immediately" do
    error = assert_raises(ArgumentError) { NitroKit::Accordion.new(id: "faq", mode: :exclusive) }

    assert_match(/Unknown mode :exclusive/, error.message)
    assert_match(/:multiple, :single/, error.message)
  end

  test "requires a non-empty declaration block" do
    missing = NitroKit::Accordion.new(id: "faq")
    empty = NitroKit::Accordion.new(id: "faq")

    assert_match(/item declaration block/, assert_raises(ArgumentError) { missing.call }.message)
    assert_match(/at least one item/, assert_raises(ArgumentError) { empty.call { } }.message)
  end

  test "validates item keys titles booleans and content" do
    invalid_keys = [ "", "Uppercase", "two words", "with/slash" ]

    invalid_keys.each do |key|
      assert_raises(ArgumentError) do
        render_accordion { |accordion| accordion.item(key, title: "Title") { "Content" } }
      end
    end

    [ nil, "", "   ", :title ].each do |title|
      assert_raises(ArgumentError) do
        render_accordion { |accordion| accordion.item(:one, title:) { "Content" } }
      end
    end

    %i[expanded disabled].each do |option|
      error = assert_raises(ArgumentError) do
        render_accordion do |accordion|
          accordion.item(:one, title: "One", **{ option => :yes }) { "Content" }
        end
      end
      assert_match(/#{option} must be true or false/, error.message)
    end

    error = assert_raises(ArgumentError) do
      render_accordion { |accordion| accordion.item(:one, title: "One") }
    end
    assert_match(/requires content/, error.message)
  end

  test "rejects duplicate keys and multiple expanded items in single mode" do
    duplicate = assert_raises(ArgumentError) do
      render_accordion do |accordion|
        accordion.item(:one, title: "One") { "First" }
        accordion.item("one", title: "Duplicate") { "Second" }
      end
    end

    expanded = assert_raises(ArgumentError) do
      render_accordion(NitroKit::Accordion.new(id: "faq", mode: :single)) do |accordion|
        accordion.item(:one, title: "One", expanded: true) { "First" }
        accordion.item(:two, title: "Two", expanded: true) { "Second" }
      end
    end

    assert_match(/Duplicate accordion item key/, duplicate.message)
    assert_match(/only one expanded item/, expanded.message)
  end

  test "items cannot be declared outside rendering" do
    component = NitroKit::Accordion.new(id: "faq")

    error = assert_raises(ArgumentError) do
      component.item(:one, title: "One") { "Content" }
    end

    assert_match(/inside the render block/, error.message)
  end

  private

  def render_accordion(component = NitroKit::Accordion.new(id: "faq"), &block)
    Nokogiri::HTML.fragment(component.call(&block)).first_element_child
  end
end
