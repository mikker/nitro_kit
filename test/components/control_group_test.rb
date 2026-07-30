require "test_helper"

class ControlGroupTest < ActiveSupport::TestCase
  class CopyField < Phlex::HTML
    def view_template
      render NitroKit::ControlGroup.new(label: "Copy API URL", id: "copy-api-url") do
        render NitroKit::Input.new(value: "https://example.test/api", readonly: true)
        render NitroKit::Button.new("Copy", type: :button, size: :sm)
      end
    end
  end

  test "groups mixed controls without taking ownership of their behavior" do
    node = Nokogiri::HTML.fragment(CopyField.new.call).first_element_child

    assert_equal "control-group", node["data-nk"]
    assert_equal "group", node["role"]
    assert_equal "Copy API URL", node["aria-label"]
    assert_equal %w[input button], node.element_children.map { |child| child["data-nk"] }
    assert node.at_css("input[readonly]")
    assert_equal "button", node.at_css("button")["type"]
    assert_equal "sm", node.at_css("button")["data-size"]
  end

  test "allows a layout-only group and requires direct content" do
    node = Nokogiri::HTML.fragment(
      NitroKit::ControlGroup.new.call { NitroKit::Button.new("Copy").call }
    ).first_element_child

    assert_nil node["role"]
    assert_raises(ArgumentError) { NitroKit::ControlGroup.new.call }
    assert_raises(ArgumentError) { NitroKit::ControlGroup.new(label: "") }
  end

  test "renders textual addons as owned group regions" do
    html = NitroKit::ControlGroup.new.call do |group|
      group.addon("https://")
      NitroKit::Input.new(value: "example.test").call
      group.addon { ".com" }
    end
    node = Nokogiri::HTML.fragment(html).first_element_child

    assert_equal [ "https://", ".com" ], node.css("[data-slot='control-group-addon']").map(&:text)
    assert_raises(ArgumentError) { NitroKit::ControlGroup.new.addon("Prefix") }
  end

  test "owns joined Input and Button geometry in static CSS" do
    source = source_css

    assert_includes source, '[data-nk="control-group"]'
    assert_includes source, '[data-nk="input"]'
    assert_includes source, '[data-nk="button"]'
    assert_includes source, "--_nk-control-group-height: var(--nk-control-height-md)"
    assert_includes source, "min-block-size: var(--_nk-control-group-height)"
    assert_includes source, "var(--_nk-button-height)"
    assert_includes source, "block-size: auto"
    assert_includes source, "box-shadow: none"
    assert_includes source, "margin-inline-start"
    refute_includes source, "transition: all"
  end

  test "lets a direct date Input stretch without changing its standalone Safari fix" do
    [ source_css, bundle_css ].each do |css|
      group_rule = css[/:where\(\s*\[data-nk="control-group"\] > \[data-nk="input"\]\[type="date"\]\s*\)\s*\{[^}]+\}/m]

      assert group_rule, "ControlGroup CSS must scope the date override to a direct Input"
      assert_includes group_rule, "block-size: auto"
      assert_includes group_rule, "line-height: normal"
    end

    standalone = input_css[/:where\(\[data-nk="input"\]\[type="date"\]\) \{[^}]+\}/m]
    assert_includes standalone, "block-size: var(--nk-control-height-md)"
    assert_includes standalone, "line-height: calc("
  end

  private

  def source_css
    @source_css ||= NitroKit::Engine.root.join(
      "src/stylesheets/nitro_kit/components/control_group.css"
    ).read
  end

  def input_css
    @input_css ||= NitroKit::Engine.root.join(
      "src/stylesheets/nitro_kit/components/input.css"
    ).read
  end

  def bundle_css
    @bundle_css ||= NitroKit::Engine.root.join(
      "app/assets/stylesheets/nitro_kit.css"
    ).read
  end
end
