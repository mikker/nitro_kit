require "test_helper"

load File.expand_path("../../lib/tasks/nitro_kit_tasks.rake", __dir__) unless defined?(NitroKit::CssBundle)

class LayoutTest < ActiveSupport::TestCase
  class ContentProbe < Phlex::HTML
    def view_template
      render NitroKit::Flex.new(dir: "col md:row", gap: "2 lg:4", id: "actions") do
        button { "Save" }
        button { "Cancel" }
      end

      render NitroKit::Flex.new(dir: :row, id: "one") { span { "One" } }
      render NitroKit::Grid.new(cols: "1 md:2 lg:3", id: "records") do
        4.times { |index| article { "Record #{index + 1}" } }
      end
      render NitroKit::Grid.new(cols: "1 sm:3", id: "many") do
        9.times { |index| span { index.to_s } }
      end

      render NitroKit::Container.new(size: :lg, id: "nested") do
        render NitroKit::Flex.new(dir: :col, gap: 6, align: :stretch) do
          render NitroKit::Grid.new(cols: "1 md:3") do
            3.times do |index|
              render NitroKit::Flex.new(dir: :row, gap: 2, align: :center, justify: :between) do
                span { "Label #{index + 1}" }
                strong { (index + 1).to_s }
              end
            end
          end
        end
      end
    end
  end

  test "flex defaults are explicit in self-describing markup" do
    node = render_node(NitroKit::Flex.new(dir: :row))

    assert_equal "div", node.name
    assert_equal "flex", node["data-nk"]
    assert_equal "row", node["data-dir"]
    assert_equal "4", node["data-gap"]
    assert_equal "start", node["data-align"]
    assert_equal "start", node["data-justify"]
    assert_equal "nowrap", node["data-wrap"]
    assert_empty node.children
    assert_empty node.css("[class], [style], [data-nk-escape]")
  end

  test "flex renders every scalar value in its closed vocabularies" do
    {
      dir: NitroKit::Flex::DIRECTIONS,
      gap: NitroKit::Flex::GAPS,
      align: NitroKit::Flex::ALIGNMENTS,
      justify: NitroKit::Flex::JUSTIFICATIONS,
      wrap: NitroKit::Flex::WRAPS
    }.each do |property, values|
      values.each do |value|
        options = { dir: :row, property => value }
        node = render_node(NitroKit::Flex.new(**options)) { "Content" }

        assert_equal value.to_s.tr("_", "-"), node["data-#{property}"]
        assert_equal "Content", node.text
      end
    end
  end

  test "reverse Ruby scalars render canonical hyphenated values" do
    node = render_node(NitroKit::Flex.new(dir: :row_reverse, wrap: :wrap_reverse))

    assert_equal "row-reverse", node["data-dir"]
    assert_equal "wrap-reverse", node["data-wrap"]
  end

  test "grid renders every scalar column and gap" do
    NitroKit::Grid::COLUMNS.each do |cols|
      node = render_node(NitroKit::Grid.new(cols:))
      assert_equal cols.to_s, node["data-cols"]
    end

    NitroKit::Grid::GAPS.each do |gap|
      node = render_node(NitroKit::Grid.new(cols: 1, gap:))
      assert_equal gap.to_s, node["data-gap"]
    end

    node = render_node(NitroKit::Grid.new(cols: "3", gap: "4")) { "Content" }
    assert_equal "grid", node["data-nk"]
    assert_equal "3", node["data-cols"]
    assert_equal "4", node["data-gap"]
    assert_equal "Content", node.text
  end

  test "responsive values normalize whitespace and Tailwind breakpoint order" do
    flex = render_node(
      NitroKit::Flex.new(
        dir: "row 2xl:col xl:row-reverse lg:col-reverse md:row sm:col",
        gap: "0 2xl:16 xl:12 lg:10 md:8 sm:6",
        align: "start 2xl:end xl:center lg:baseline md:stretch sm:center",
        justify: "start 2xl:evenly xl:around lg:between md:end sm:center",
        wrap: "nowrap 2xl:wrap-reverse xl:wrap lg:nowrap md:wrap-reverse sm:wrap"
      )
    )

    assert_equal "row sm:col md:row lg:col-reverse xl:row-reverse 2xl:col", flex["data-dir"]
    assert_equal "0 sm:6 md:8 lg:10 xl:12 2xl:16", flex["data-gap"]
    assert_equal "start sm:center md:stretch lg:baseline xl:center 2xl:end", flex["data-align"]
    assert_equal "start sm:center md:end lg:between xl:around 2xl:evenly", flex["data-justify"]
    assert_equal "nowrap sm:wrap md:wrap-reverse lg:nowrap xl:wrap 2xl:wrap-reverse", flex["data-wrap"]

    grid = render_node(
      NitroKit::Grid.new(
        cols: "1 2xl:12 xl:10 lg:8 md:4 sm:2",
        gap: "2 2xl:16 xl:12 lg:8 md:6 sm:4"
      )
    )
    assert_equal "1 sm:2 md:4 lg:8 xl:10 2xl:12", grid["data-cols"]
    assert_equal "2 sm:4 md:6 lg:8 xl:12 2xl:16", grid["data-gap"]
  end

  test "responsive values use the fixed Tailwind breakpoint vocabulary" do
    assert_equal(
      {
        "sm" => "40rem",
        "md" => "48rem",
        "lg" => "64rem",
        "xl" => "80rem",
        "2xl" => "96rem"
      },
      NitroKit::ResponsiveValue::BREAKPOINTS
    )
  end

  test "responsive values require one base value and unique breakpoints" do
    error = assert_raises(ArgumentError) { NitroKit::Grid.new(cols: "md:2") }
    assert_match(/cols must include an unprefixed base value/, error.message)

    error = assert_raises(ArgumentError) { NitroKit::Grid.new(cols: "1 2 md:3") }
    assert_match(/Duplicate cols base value/, error.message)

    error = assert_raises(ArgumentError) { NitroKit::Grid.new(cols: "1 md:2 md:3") }
    assert_match(/Duplicate cols breakpoint "md"/, error.message)
  end

  test "responsive values reject unknown breakpoints values and input types" do
    error = assert_raises(ArgumentError) { NitroKit::Grid.new(cols: "1 tablet:2") }
    assert_match(/Unknown cols breakpoint "tablet"/, error.message)
    assert_match(/sm, md, lg, xl, 2xl/, error.message)

    error = assert_raises(ArgumentError) { NitroKit::Grid.new(cols: "1 md:13") }
    assert_match(/Unknown cols value "13"/, error.message)
    assert_match(/1, 2, 3/, error.message)

    error = assert_raises(ArgumentError) { NitroKit::Flex.new(dir: "row md:sideways") }
    assert_match(/Unknown dir value "sideways"/, error.message)

    error = assert_raises(ArgumentError) { NitroKit::Flex.new(dir: "row", gap: "4 md:") }
    assert_match(/Unknown gap value ""/, error.message)

    error = assert_raises(ArgumentError) { NitroKit::Grid.new(cols: "  ") }
    assert_match(/cols cannot be blank/, error.message)

    [ nil, [], {}, 2.0 ].each do |value|
      error = assert_raises(ArgumentError) { NitroKit::Grid.new(cols: value) }
      assert_match(/cols must be an Integer, Symbol, or String/, error.message)
    end
  end

  test "every closed layout property rejects invalid scalar values immediately" do
    invalid_options = {
      dir: :sideways,
      gap: 7,
      align: :left,
      justify: :apart,
      wrap: :reverse
    }

    invalid_options.each do |property, value|
      error = assert_raises(ArgumentError) do
        NitroKit::Flex.new(dir: :row, **{ property => value })
      end
      assert_match(/Unknown #{property} value/, error.message)
    end

    error = assert_raises(ArgumentError) { NitroKit::Grid.new(cols: 13) }
    assert_match(/Unknown cols value/, error.message)

    error = assert_raises(ArgumentError) { NitroKit::Grid.new(cols: 1, gap: 7) }
    assert_match(/Unknown gap value/, error.message)
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
    probe = render_probe
    actions = probe.at_css("#actions")
    one = probe.at_css("#one")
    many = probe.at_css("#many")
    nested = probe.at_css("#nested")

    assert_equal %w[Save Cancel], actions.element_children.map(&:text)
    assert_equal "col md:row", actions["data-dir"]
    assert_equal 1, one.element_children.count
    assert_equal 9, many.element_children.count
    assert_equal "flex", nested.element_children.first["data-nk"]
    assert_equal "stretch", nested.element_children.first["data-align"]
    assert_equal 3, nested.css("[data-nk='grid'] > [data-nk='flex']").count
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

  test "static layout CSS maps every value at every mobile-first breakpoint" do
    css = NitroKit::CssBundle.compile
    responsive_css = %w[layout flex grid].map do |name|
      NitroKit::Engine.root.join("src/stylesheets/nitro_kit/components/#{name}.css").read
    end.join("\n")

    %w[flex grid container].each do |component|
      assert_includes css, %([data-nk="#{component}"])
    end

    flex_values = {
      dir: NitroKit::Flex::DIRECTIONS,
      align: NitroKit::Flex::ALIGNMENTS,
      justify: NitroKit::Flex::JUSTIFICATIONS,
      wrap: NitroKit::Flex::WRAPS
    }

    flex_values.each do |property, values|
      values.each do |value|
        value = value.to_s.tr("_", "-")
        assert_includes css, %([data-nk="flex"][data-#{property}~="#{value}"])
      end
    end

    NitroKit::ResponsiveValue::BREAKPOINTS.each do |breakpoint, width|
      assert_includes css, "@media (min-width: #{width})"

      NitroKit::Grid::COLUMNS.each do |cols|
        assert_includes css, %([data-nk="grid"][data-cols~="#{breakpoint}:#{cols}"])
      end

      flex_values.each do |property, values|
        values.each do |value|
          value = value.to_s.tr("_", "-")
          assert_includes css, %([data-nk="flex"][data-#{property}~="#{breakpoint}:#{value}"])
        end
      end

      NitroKit::LayoutOptions::GAPS.each do |gap|
        assert_includes css, %([data-nk="grid"][data-gap~="#{breakpoint}:#{gap}"])
        assert_includes css, %([data-nk="flex"][data-gap~="#{breakpoint}:#{gap}"])
      end
    end

    NitroKit::Grid::COLUMNS.each do |cols|
      assert_includes css, %([data-nk="grid"][data-cols~="#{cols}"])
    end

    NitroKit::LayoutOptions::GAPS.each do |gap|
      assert_includes css, %([data-nk="grid"][data-gap~="#{gap}"])
      assert_includes css, %([data-nk="flex"][data-gap~="#{gap}"])
    end

    assert_includes css, "grid-template-columns: repeat(var(--_nk-grid-columns), minmax(0, 1fr))"
    assert_includes css, "flex-direction: var(--_nk-flex-direction)"
    assert_includes css, "gap: var(--_nk-layout-gap)"
    assert_includes css, "--_nk-layout-gap: 0"
    assert_includes css, "--_nk-layout-gap: var(--nk-space)"
    assert_includes css, "--_nk-layout-gap: calc(var(--nk-space) * 16)"
    refute_includes responsive_css, "max-width"
    refute_includes css, "@tailwind"
    refute_includes css, "transition: all"
  end

  test "the engine package includes every layout implementation and stylesheet" do
    files = Gem::Specification.load(NitroKit::Engine.root.join("nitro_kit.gemspec").to_s).files

    %w[container flex grid layout_options responsive_value].each do |name|
      assert_includes files, "app/components/nitro_kit/#{name}.rb"
    end

    %w[container flex grid layout].each do |name|
      assert_includes files, "src/stylesheets/nitro_kit/components/#{name}.css"
    end
  end

  private

  def components
    [ NitroKit::Flex, NitroKit::Grid, NitroKit::Container ]
  end

  def required_options(component)
    {
      NitroKit::Flex => { dir: :row },
      NitroKit::Grid => { cols: 1 },
      NitroKit::Container => { size: :md }
    }.fetch(component)
  end

  def render_node(component, &block)
    Nokogiri::HTML.fragment(component.call(&block)).first_element_child
  end

  def render_probe
    Nokogiri::HTML.fragment(ContentProbe.new.call)
  end
end
