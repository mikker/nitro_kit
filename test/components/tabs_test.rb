require "test_helper"

class TabsComponentTest < ActiveSupport::TestCase
  test "renders paired tabs with deterministic ARIA relationships and a readable server fallback" do
    node = render_tabs(default: :billing_details) do |tabs|
      tabs.tab(:general, "General") { "General content" }
      tabs.tab(:billing_details, "Billing") { "Billing content" }
    end

    list = node.at_css("[data-slot='tabs-list']")
    tab_nodes = list.css("[data-slot='tabs-tab']")
    panels = node.css("[data-slot='tabs-panel']")

    assert_equal "settings", node["id"]
    assert_equal "tabs", node["data-nk"]
    assert_equal "nk--tabs", node["data-controller"]
    assert_equal "horizontal", node["data-orientation"]
    assert_equal "automatic", node["data-activation"]
    assert_equal "billing-details", node["data-nk--tabs-active-value"]

    assert_equal "tablist", list["role"]
    assert_equal "Tabs", list["aria-label"]
    assert_equal "horizontal", list["aria-orientation"]
    assert_equal "general", tab_nodes.first["data-key"]
    assert_equal "settings-general-tab", tab_nodes.first["id"]
    assert_equal "settings-general-panel", tab_nodes.first["aria-controls"]
    assert_equal "false", tab_nodes.first["aria-selected"]
    assert_equal "0", tab_nodes.first["tabindex"]

    assert_equal "billing-details", tab_nodes.last["data-key"]
    assert_equal "true", tab_nodes.last["aria-selected"]
    assert_equal "0", tab_nodes.last["tabindex"]
    assert_equal "settings-billing-details-panel", panels.last["id"]
    assert_equal "settings-billing-details-tab", panels.last["aria-labelledby"]
    assert_nil panels.last["aria-hidden"]
    refute panels.last.key?("hidden")
    assert_nil panels.last["tabindex"]
    assert_equal "active", panels.last["data-state"]
    assert_equal "Billing content", panels.last.text

    refute panels.first.key?("hidden")
    assert_nil panels.first["aria-hidden"]
    assert_nil panels.first["tabindex"]
    assert_equal "inactive", panels.first["data-state"]
    assert_equal [ "General content", "Billing content" ], panels.map(&:text)
    assert_empty node.css("[class], [style]")
  end

  test "defaults to the first enabled tab" do
    node = render_tabs do |tabs|
      tabs.tab(:disabled, "Disabled", disabled: true) { "Disabled content" }
      tabs.tab(:available, "Available") { "Available content" }
    end

    tab_nodes = node.css("[data-slot='tabs-tab']")

    assert tab_nodes.first.key?("disabled")
    assert_equal "false", tab_nodes.first["aria-selected"]
    assert_equal "true", tab_nodes.last["aria-selected"]
    assert_equal "available", node["data-nk--tabs-active-value"]
  end

  test "renders vertical manual tabs and keeps public attributes inside their boundaries" do
    component = NitroKit::Tabs.new(
      id: "profile",
      label: "Profile settings",
      orientation: :vertical,
      activation: :manual,
      html: { title: "Profile" },
      aria: { describedby: "profile-help" },
      data: { controller: "application", tracking_id: "profile" }
    )
    node = render_component(component) do |tabs|
      tabs.tab(:account, "Account") { "Account content" }
    end

    list = node.at_css("[data-slot='tabs-list']")

    assert_equal "vertical", node["data-orientation"]
    assert_equal "manual", node["data-activation"]
    assert_equal "vertical", node["data-nk--tabs-orientation-value"]
    assert_equal "manual", node["data-nk--tabs-activation-value"]
    assert_equal "Profile", node["title"]
    assert_equal "profile-help", node["aria-describedby"]
    assert_equal "nk--tabs application", node["data-controller"]
    assert_equal "profile", node["data-tracking-id"]
    assert_equal "Profile settings", list["aria-label"]
    assert_equal "vertical", list["aria-orientation"]
  end

  test "keeps reserved attributes owned and makes the class escape observable" do
    assert_raises(ArgumentError) { NitroKit::Tabs.new(id: "settings", data: { state: "active" }) }
    assert_raises(ArgumentError) { NitroKit::Tabs.new(id: "settings", html: { class: "utility" }) }
    assert_raises(ArgumentError) { NitroKit::Tabs.new(id: "settings", html: { style: "display:none" }) }

    component = NitroKit::Tabs.new(id: "settings", desperately_need_a_class: "external-tabs")
    node = render_component(component) do |tabs|
      tabs.tab(:one, "One") { "Content" }
    end

    assert_equal "external-tabs", node["class"]
    assert_equal "class", node["data-nk-escape"]
  end

  test "requires an explicit stable id" do
    assert_raises(ArgumentError) { NitroKit::Tabs.new }

    [ nil, "", "   ", "two words", :tabs, 123 ].each do |id|
      error = assert_raises(ArgumentError) { NitroKit::Tabs.new(id:) }
      assert_match(/id must be a non-blank String without whitespace/, error.message)
    end
  end

  test "validates closed options immediately" do
    orientation = assert_raises(ArgumentError) do
      NitroKit::Tabs.new(id: "settings", orientation: :diagonal)
    end
    activation = assert_raises(ArgumentError) do
      NitroKit::Tabs.new(id: "settings", activation: :hover)
    end

    assert_match(/Unknown orientation :diagonal/, orientation.message)
    assert_match(/:horizontal, :vertical/, orientation.message)
    assert_match(/Unknown activation :hover/, activation.message)
    assert_match(/:automatic, :manual/, activation.message)

    [ nil, "", "   ", :tabs ].each do |label|
      error = assert_raises(ArgumentError) { NitroKit::Tabs.new(id: "settings", label:) }
      assert_match(/labels must be non-blank Strings/, error.message)
    end
  end

  test "requires a non-empty declaration block" do
    missing = NitroKit::Tabs.new(id: "settings")
    empty = NitroKit::Tabs.new(id: "settings")

    assert_match(/tab declaration block/, assert_raises(ArgumentError) { missing.call }.message)
    assert_match(/at least one tab/, assert_raises(ArgumentError) { empty.call { } }.message)
  end

  test "validates tab keys labels booleans and panel content" do
    [ "", "Uppercase", "two words", "with/slash" ].each do |key|
      assert_raises(ArgumentError) do
        render_tabs { |tabs| tabs.tab(key, "Label") { "Content" } }
      end
    end

    [ nil, "", "   ", :label ].each do |label|
      assert_raises(ArgumentError) do
        render_tabs { |tabs| tabs.tab(:one, label) { "Content" } }
      end
    end

    error = assert_raises(ArgumentError) do
      render_tabs { |tabs| tabs.tab(:one, "One", disabled: :yes) { "Content" } }
    end
    assert_match(/disabled must be true or false/, error.message)

    missing = assert_raises(ArgumentError) do
      render_tabs { |tabs| tabs.tab(:one, "One") }
    end
    assert_match(/requires panel content/, missing.message)
  end

  test "rejects duplicate keys" do
    duplicate = assert_raises(ArgumentError) do
      render_tabs do |tabs|
        tabs.tab(:one, "One") { "First" }
        tabs.tab("one", "Duplicate") { "Second" }
      end
    end

    assert_match(/Duplicate tab key/, duplicate.message)
  end

  test "validates defaults and requires an enabled tab" do
    missing = assert_raises(ArgumentError) do
      render_tabs(default: :missing) { |tabs| tabs.tab(:one, "One") { "Content" } }
    end
    disabled = assert_raises(ArgumentError) do
      render_tabs(default: :one) do |tabs|
        tabs.tab(:one, "One", disabled: true) { "Content" }
        tabs.tab(:two, "Two") { "Content" }
      end
    end
    all_disabled = assert_raises(ArgumentError) do
      render_tabs { |tabs| tabs.tab(:one, "One", disabled: true) { "Content" } }
    end

    assert_match(/is not declared/, missing.message)
    assert_match(/cannot be disabled/, disabled.message)
    assert_match(/at least one enabled tab/, all_disabled.message)
  end

  test "tabs cannot be declared outside rendering" do
    component = NitroKit::Tabs.new(id: "settings")

    tab_error = assert_raises(ArgumentError) { component.tab(:one, "One") { "Content" } }

    assert_match(/inside the render block/, tab_error.message)
  end

  private

  def render_tabs(default: nil, &block)
    render_component(NitroKit::Tabs.new(id: "settings", default:), &block)
  end

  def render_component(component, &block)
    Nokogiri::HTML.fragment(component.call(&block)).first_element_child
  end
end
