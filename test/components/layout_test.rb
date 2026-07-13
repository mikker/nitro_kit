require "test_helper"

load File.expand_path("../../lib/tasks/nitro_kit_tasks.rake", __dir__) unless defined?(NitroKit::CssBundle)

class LayoutTest < ActiveSupport::TestCase
  class ContentProbe < Phlex::HTML
    def view_template
      render NitroKit::VStack.new(id: "actions") do
        button { "Save" }
        button { "Cancel" }
      end

      render NitroKit::HStack.new(id: "one") { span { "One" } }
      render NitroKit::Grid.new(cols: 3, id: "records") do
        4.times { |index| article { "Record #{index + 1}" } }
      end
      render NitroKit::Grid.new(cols: 3, id: "many") do
        9.times { |index| span { index.to_s } }
      end

      render NitroKit::Container.new(size: :lg, id: "nested") do
        render NitroKit::VStack.new(gap: :lg, align: :stretch) do
          render NitroKit::Grid.new(cols: 3) do
            3.times do |index|
              render NitroKit::HStack.new(gap: :sm, justify: :between) do
                span { "Label #{index + 1}" }
                strong { (index + 1).to_s }
              end
            end
          end
        end
      end
    end
  end

  test "vertical stack defaults preserve intrinsic children" do
    node = render_probe.at_css("#actions")

    assert_equal "div", node.name
    assert_equal "v-stack", node["data-nk"]
    assert_equal "md", node["data-gap"]
    assert_equal "start", node["data-align"]
    assert_equal %w[Save Cancel], node.element_children.select { |child| child.name == "button" }.map(&:text)
    assert_empty node.css("[class], [style], [data-nk-escape]")
  end

  test "vertical stack renders every closed gap and alignment" do
    NitroKit::VStack::GAPS.product(NitroKit::VStack::ALIGNMENTS).each do |gap, align|
      node = render_node(NitroKit::VStack.new(gap:, align:)) { "Content" }

      assert_equal gap.to_s, node["data-gap"]
      assert_equal align.to_s, node["data-align"]
      assert_equal "Content", node.text
    end
  end

  test "horizontal stack renders the complete option product" do
    options = NitroKit::HStack::GAPS.product(
      NitroKit::HStack::ALIGNMENTS,
      NitroKit::HStack::JUSTIFICATIONS,
      [ false, true ]
    )

    options.each do |gap, align, justify, wrap|
      node = render_node(NitroKit::HStack.new(gap:, align:, justify:, wrap:)) { "Content" }

      assert_equal gap.to_s, node["data-gap"]
      assert_equal align.to_s, node["data-align"]
      assert_equal justify.to_s, node["data-justify"]
      assert_equal wrap.to_s, node["data-wrap"]
    end
  end

  test "horizontal stack defaults center intrinsic content without wrapping" do
    node = render_node(NitroKit::HStack.new)

    assert_equal "h-stack", node["data-nk"]
    assert_equal "md", node["data-gap"]
    assert_equal "center", node["data-align"]
    assert_equal "start", node["data-justify"]
    assert_equal "false", node["data-wrap"]
    assert_empty node.children
  end

  test "grid requires the single evidence-backed column count" do
    node = render_probe.at_css("#records")

    assert_equal "grid", node["data-nk"]
    assert_equal "3", node["data-cols"]
    assert_equal 4, node.element_children.count { |child| child.name == "article" }

    [ 1, 2, 4, :auto, "3" ].each do |cols|
      error = assert_raises(ArgumentError) { NitroKit::Grid.new(cols:) }
      assert_match(/Unknown cols/, error.message)
      assert_match(/3/, error.message)
    end
  end

  test "container renders every content width and deliberately has no full option" do
    NitroKit::Container::SIZES.each do |size|
      node = render_node(NitroKit::Container.new(size:)) { "#{size} content" }

      assert_equal "container", node["data-nk"]
      assert_equal size.to_s, node["data-size"]
      assert_equal "#{size} content", node.text
    end

    [ :full, :xs, :xxl, "md" ].each do |size|
      error = assert_raises(ArgumentError) { NitroKit::Container.new(size:) }
      assert_match(/Unknown size/, error.message)
    end
  end

  test "layouts support empty one many and nested direct Phlex content" do
    empty = render_node(NitroKit::VStack.new)
    probe = render_probe
    one = probe.at_css("#one")
    many = probe.at_css("#many")
    nested = probe.at_css("#nested")

    assert_empty empty.children
    assert_equal 1, one.element_children.count
    assert_equal 9, many.element_children.count
    assert_equal "v-stack", nested.element_children.first["data-nk"]
    assert_equal "stretch", nested.element_children.first["data-align"]
    assert_equal 3, nested.css("[data-nk='grid'] > [data-nk='h-stack']").count
  end

  test "every layout preserves the shared attribute and escape boundaries" do
    components.each_with_index do |component, index|
      node = render_node(
        component.new(
          **required_options(component),
          id: "layout-#{index}",
          html: { title: "Layout #{index}" },
          aria: { label: "Layout #{index}" },
          data: { application_state: "ready" }
        )
      )

      assert_equal "layout-#{index}", node["id"]
      assert_equal "Layout #{index}", node["title"]
      assert_equal "Layout #{index}", node["aria-label"]
      assert_equal "ready", node["data-application-state"]
      assert_nil node["class"]
      assert_nil node["style"]

      escaped = render_node(
        component.new(**required_options(component), desperately_need_a_class: "external-layout")
      )
      assert_equal "external-layout", escaped["class"]
      assert_equal "class", escaped["data-nk-escape"]

      assert_raises(ArgumentError) { component.new(**required_options(component), html: { class: "utility" }) }
      assert_raises(ArgumentError) { component.new(**required_options(component), html: { style: "display: grid" }) }
      assert_raises(ArgumentError) { component.new(**required_options(component), data: { nk: "replacement" }) }
    end
  end

  test "invalid closed stack options and booleans fail immediately" do
    assert_raises(ArgumentError) { NitroKit::VStack.new(gap: :huge) }
    assert_raises(ArgumentError) { NitroKit::VStack.new(align: :end) }
    assert_raises(ArgumentError) { NitroKit::HStack.new(gap: 4) }
    assert_raises(ArgumentError) { NitroKit::HStack.new(align: :baseline) }
    assert_raises(ArgumentError) { NitroKit::HStack.new(justify: :around) }

    [ nil, :wrap, 1, "true" ].each do |wrap|
      error = assert_raises(ArgumentError) { NitroKit::HStack.new(wrap:) }
      assert_match(/wrap must be true or false/, error.message)
    end
  end

  test "static layout CSS owns gaps sizing and the single narrow grid collapse" do
    css = NitroKit::CssBundle.compile

    %w[v-stack h-stack grid container].each do |component|
      assert_includes css, %([data-nk="#{component}"])
    end

    NitroKit::LayoutOptions::GAPS.each do |gap|
      assert_includes css, %([data-nk="v-stack"][data-gap="#{gap}"])
      assert_includes css, %([data-nk="h-stack"][data-gap="#{gap}"])
    end

    assert_includes css, %([data-nk="grid"][data-cols="3"])
    assert_includes css, "grid-template-columns: repeat(3, minmax(0, 1fr))"
    assert_includes css, "@media (max-width: 48rem)"
    assert_includes css, "grid-template-columns: minmax(0, 1fr)"
    assert_includes css, "max-width: var(--nk-content-xl)"
    refute_includes css, "transition: all"
  end

  test "the engine package includes every layout implementation and stylesheet" do
    files = Gem::Specification.load(NitroKit::Engine.root.join("nitro_kit.gemspec").to_s).files

    %w[container grid h_stack v_stack].each do |name|
      assert_includes files, "app/components/nitro_kit/#{name}.rb"
      assert_includes files, "src/stylesheets/nitro_kit/components/#{name}.css"
    end

    assert_includes files, "app/components/nitro_kit/layout_options.rb"
    assert_includes files, "src/stylesheets/nitro_kit/components/stack.css"
  end

  private

  def components
    [ NitroKit::VStack, NitroKit::HStack, NitroKit::Grid, NitroKit::Container ]
  end

  def required_options(component)
    {
      NitroKit::Grid => { cols: 3 },
      NitroKit::Container => { size: :md }
    }.fetch(component, {})
  end

  def render_node(component, &block)
    Nokogiri::HTML.fragment(component.call(&block)).first_element_child
  end

  def render_probe
    Nokogiri::HTML.fragment(ContentProbe.new.call)
  end
end
