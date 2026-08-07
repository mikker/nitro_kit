require "test_helper"

load File.expand_path("../../lib/tasks/nitro_kit_tasks.rake", __dir__) unless defined?(NitroKit::CssBundle)

class RichTextAreaTest < ActiveSupport::TestCase
  EDITOR = %(<lexxy-editor input="project_brief"></lexxy-editor>)

  test "wraps trusted editor markup in the Nitro contract" do
    node = render_node(NitroKit::RichTextArea.new(editor))

    assert_equal "div", node.name
    assert_equal "rich-text-area", node["data-nk"]
    assert_equal "rich-text-area-editor", node.element_children.sole["data-slot"]
    assert_equal "project_brief", node.at_css("[data-slot='rich-text-area-editor'] > lexxy-editor")["input"]
    assert_empty node.css("[data-slot='rich-text-area-editor'] [class], [style]")
  end

  test "exposes the captured editor content" do
    component = NitroKit::RichTextArea.new(editor)

    assert_equal editor, component.content
    assert_predicate component.content, :html_safe?
  end

  test "requires trusted captured editor content" do
    assert_match(/content is required/, assert_raises(ArgumentError) { NitroKit::RichTextArea.new(nil) }.message)

    [ EDITOR, "", :editor, 1, [ EDITOR ] ].each do |content|
      assert_match(
        /must be an ActiveSupport::SafeBuffer/,
        assert_raises(ArgumentError) { NitroKit::RichTextArea.new(content) }.message
      )
    end
  end

  test "composes application attributes and rejects reserved Nitro data" do
    node = render_node(
      NitroKit::RichTextArea.new(
        editor,
        id: "project-brief",
        html: { title: "Project brief" },
        aria: { describedby: "brief-help" },
        data: { controller: "analytics", tracking_id: "brief" }
      )
    )

    assert_equal "project-brief", node["id"]
    assert_equal "Project brief", node["title"]
    assert_equal "brief-help", node["aria-describedby"]
    assert_equal "analytics", node["data-controller"]
    assert_equal "brief", node["data-tracking-id"]

    %i[nk slot variant size state].each do |reserved|
      assert_raises(ArgumentError) { NitroKit::RichTextArea.new(editor, data: { reserved => "replacement" }) }
    end
    assert_raises(ArgumentError) { NitroKit::RichTextArea.new(editor, html: { class: "utility" }) }
    assert_raises(ArgumentError) { NitroKit::RichTextArea.new(editor, html: { style: "display: none" }) }
  end

  test "emits the deliberate class escape and rejects blank values" do
    node = render_node(NitroKit::RichTextArea.new(editor, desperately_need_a_class: "external-editor-hook"))

    assert_equal "external-editor-hook", node["class"]
    assert_equal "class", node["data-nk-escape"]
    assert_nil node.at_css("[data-slot='rich-text-area-editor']")["data-nk-escape"]
    assert_raises(ArgumentError) { NitroKit::RichTextArea.new(editor, desperately_need_a_class: "") }
  end

  test "Field(as: :rich_text) is the expected composition path" do
    node = render_node(
      NitroKit::Field.new(
        nil,
        :brief,
        as: :rich_text,
        label: "Project brief",
        description: "Shared with the project team.",
        errors: [ "Brief is required" ],
        rich_text_content: editor
      )
    )
    control = node.at_css("[data-slot='field-control']")

    editor_element = control.at_css("[data-slot='rich-text-area-editor'] > lexxy-editor")

    assert_equal "rich-text-area", control["data-nk"]
    assert_equal "true", editor_element["aria-invalid"]
    assert_equal "brief-description brief-errors", editor_element["aria-describedby"]
    assert_includes NitroKit::Field::TYPES, :rich_text
  end

  test "Field(as: :rich_text) injects control ARIA into the lexxy editor element" do
    content = %(<input type="hidden" id="brief" name="brief"><lexxy-editor input="brief"></lexxy-editor>).html_safe
    node = render_node(
      NitroKit::Field.new(
        nil,
        :brief,
        as: :rich_text,
        label: "Project brief",
        errors: [ "Brief is required" ],
        rich_text_content: content
      )
    )
    control = node.at_css("[data-slot='field-control']")
    editor = control.at_css("[data-slot='rich-text-area-editor'] > lexxy-editor")

    assert_equal "true", editor["aria-invalid"]
    assert_equal "brief-errors", editor["aria-describedby"]
    assert_nil control["aria-invalid"]
    assert_nil control["aria-describedby"]
  end

  test "documents Field(as: :rich_text) as the expected path in the contract" do
    contracts = NitroKit::Engine.root.join("docs/component_contracts.md").read
    row = contracts.lines.find { |line| line.include?("`RichTextArea`") }

    assert row, "expected a RichTextArea contract row"
    assert_includes row, "Field(as: :rich_text)"
  end

  test "ships owner-scoped static CSS and packaged sources" do
    source = NitroKit::Engine.root.join("src/stylesheets/nitro_kit/components/rich_text_area.css").read
    files = Gem::Specification.load(NitroKit::Engine.root.join("nitro_kit.gemspec").to_s).files

    assert_includes NitroKit::CssBundle.compile, %([data-nk="rich-text-area"])
    assert_includes source, '[data-slot="rich-text-area-editor"]'
    refute_includes source, "transition: all"
    refute_match(/(?:\:where\(\s*|,\s*)\[data-slot=/m, source)
    assert_includes files, "app/components/nitro_kit/rich_text_area.rb"
    assert_includes files, "src/stylesheets/nitro_kit/components/rich_text_area.css"
  end

  test "is reachable through the gallery catalog" do
    entry = Gallery::Catalog.fetch!(kind: :component, slug: "rich-text-area")

    assert_equal Gallery::Components::RichTextAreaPage, entry.page
    assert_includes entry.expected_roots, "rich-text-area"
  end

  private

  def editor
    ActiveSupport::SafeBuffer.new(EDITOR)
  end

  def render_node(component)
    Nokogiri::HTML.fragment(component.call).first_element_child
  end
end
