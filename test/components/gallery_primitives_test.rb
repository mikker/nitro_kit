require "test_helper"

class GalleryPrimitivesTest < ActiveSupport::TestCase
  Entry = ::Data.define(:slug, :title, :description)

  class ProbePage < Gallery::ComponentPage
    private

    def source_note
      "app/components/nitro_kit/button.rb"
    end

    def api_note
      "NitroKit::Button.new(text, variant:, size:)"
    end

    def component_template
      example_section(
        "Variants",
        slug: :button_variants,
        description: "The public variants across representative content."
      ) do
        example(
          "Variant matrix",
          slug: "button-variant-matrix",
          description: "Compact coverage for visual comparison.",
          mode: :full_width,
          layout: :matrix,
          density: :compact,
          source: "NitroKit::Button",
          api: "variant: :default | :primary"
        ) do
          sample("Default", slug: "default", description: "Neutral action") do
            button(type: "button", data: { example_control: "default" }) { "Default" }
          end

          sample("Primary", slug: "primary") do
            button(type: "button", data: { example_control: "primary" }) { "Primary" }
          end
        end

        example("Single example", slug: "button-single") do
          button(type: "button") { "Button" }
        end
      end
    end
  end

  test "component page renders accessible named sections and examples" do
    fragment = render_fragment(page)
    page_node = fragment.at_css("[data-gallery='page'][data-gallery-page='button']")
    section = fragment.at_css("[data-gallery='section'][data-gallery-section='button-variants']")
    matrix = fragment.at_css("[data-gallery='example'][data-gallery-example='button-variant-matrix']")

    assert page_node
    assert_equal "Actions and links with typed variants and sizes.", page_node.at_css("[data-gallery='component-header'] > p").text
    assert_equal "section-button-variants", section["id"]
    assert_equal "section-button-variants-title", section["aria-labelledby"]
    assert_equal "section-button-variants-description", section["aria-describedby"]
    assert_equal "example-button-variant-matrix", matrix["id"]
    assert_equal "example-button-variant-matrix-title", matrix["aria-labelledby"]
    assert_equal "example-button-variant-matrix-description", matrix["aria-describedby"]

    assert_equal "Button", fragment.at_css("h1").text
    assert_equal "Variants", fragment.at_css("h2").text
    assert_equal "Variant matrix", fragment.at_css("h3").text
    assert_equal 1, fragment.css("h1").count
    assert_equal 1, fragment.css("h2").count
    assert_equal 2, fragment.css("h3").count

    tabs = matrix.at_css("[data-gallery='example-tabs'][data-nk='tabs']")
    assert_equal "Variant matrix example", tabs.at_css("[role='tablist']")["aria-label"]
    assert_equal [ "Preview", "Code" ], tabs.css("[role='tab']").map(&:text)
    assert tabs.at_css("[data-key='preview'][data-state='active']:not([hidden])")
    assert tabs.at_css("[data-key='code'][data-state='inactive'][hidden]")
  end

  test "example modes layouts and densities are closed visible data" do
    fragment = render_fragment(page)
    matrix = fragment.at_css("[data-gallery-example='button-variant-matrix']")
    single = fragment.at_css("[data-gallery-example='button-single']")

    assert_equal "full-width", matrix["data-gallery-mode"]
    assert_equal "matrix", matrix["data-gallery-layout"]
    assert_equal "compact", matrix["data-gallery-density"]
    assert_equal "constrained", single["data-gallery-mode"]
    assert_equal "stack", single["data-gallery-layout"]
    assert_equal "comfortable", single["data-gallery-density"]
  end

  test "matrix samples have stable identities and captions" do
    fragment = render_fragment(page)
    default_sample = fragment.at_css("[data-gallery='sample'][data-gallery-sample='default']")
    primary_sample = fragment.at_css("[data-gallery='sample'][data-gallery-sample='primary']")

    assert_equal "DefaultNeutral action", default_sample.at_css("figcaption").text
    assert_equal "default", default_sample.at_css("button")["data-example-control"]
    assert_equal "Primary", primary_sample.at_css("figcaption").text
    assert_equal "primary", primary_sample.at_css("button")["data-example-control"]
  end

  test "page and example notes remain plain semantic text" do
    fragment = render_fragment(page)
    notes = fragment.css("[data-gallery='notes']")

    assert_equal 2, notes.count
    assert_equal [ "Source", "API" ], notes.first.css("dt").map(&:text)
    assert_equal(
      [ "app/components/nitro_kit/button.rb", "NitroKit::Button.new(text, variant:, size:)" ],
      notes.first.css("dd code").map(&:text)
    )
    assert_equal [ "NitroKit::Button", "variant: :default | :primary" ], notes.last.css("dd code").map(&:text)
  end

  test "code samples use the exact Ruby block that renders the preview" do
    fragment = render_fragment(page)
    matrix = fragment.at_css("[data-gallery-example='button-variant-matrix']")
    code_sample = matrix.at_css("[data-gallery='code-sample']")

    assert_equal(
      "test/components/gallery_primitives_test.rb",
      code_sample.at_css("[data-gallery='code-path']").text
    )
    assert_equal(<<~RUBY.strip, code_sample.at_css("[data-gallery='code-source']").text)
      sample("Default", slug: "default", description: "Neutral action") do
        button(type: "button", data: { example_control: "default" }) { "Default" }
      end

      sample("Primary", slug: "primary") do
        button(type: "button", data: { example_control: "primary" }) { "Primary" }
      end
    RUBY
  end

  test "flow code can use the exact concrete rendering method" do
    source = Gallery::SourceCode.from_method(ProbePage.instance_method(:component_template))

    assert_equal "test/components/gallery_primitives_test.rb", source.path
    assert_includes source.content, "example_section("
    assert_includes source.content, 'example("Single example", slug: "button-single")'
    refute_includes source.content, "def component_template"
  end

  test "source extraction rejects multiple blocks beginning on one line" do
    ambiguous = proc { 2.times { nil } }

    error = assert_raises(ArgumentError) { Gallery::SourceCode.from_block(ambiguous) }

    assert_match(/multiple blocks on one line/, error.message)
  end

  test "code samples highlight and escape source without classes or inline styles" do
    source = Gallery::SourceCode.new(
      content: "render Widget.new(variant: :primary) { \"<script>unsafe()</script>\" } # note",
      path: "test/example.rb"
    )
    fragment = render_fragment(Gallery::CodeSample.new(id: "unsafe-source", source:))

    assert_equal source.content, fragment.at_css("[data-gallery='code-source']").text
    assert_empty fragment.css("script")
    assert fragment.at_css("[data-gallery-token='constant']"), "expected highlighted constant"
    assert fragment.at_css("[data-gallery-token='symbol']"), "expected highlighted symbol"
    assert fragment.at_css("[data-gallery-token='string']"), "expected highlighted string"
    assert fragment.at_css("[data-gallery-token='comment']"), "expected highlighted comment"
    assert_empty fragment.css("[class]")
    assert_empty fragment.css("[style]")
  end

  test "code samples expose an accessible copy control and live result" do
    source = Gallery::SourceCode.new(content: "render NitroKit::Button.new(\"Save\")", path: "example.rb")
    fragment = render_fragment(Gallery::CodeSample.new(id: "copy-source", source:))
    button = fragment.at_css("#copy-source-copy")
    status = fragment.at_css("#copy-source-copy-status")

    assert_equal "button", button.name
    assert_equal "button", button["type"]
    assert_equal "copy-source-copy-status", button["aria-describedby"]
    assert_equal "status", status["role"]
    assert_equal "polite", status["aria-live"]
    assert_equal "gallery--code-sample", fragment.first_element_child["data-controller"]
  end

  test "gallery primitives never add classes or inline styles" do
    fragment = render_fragment(page)

    assert_empty fragment.css("[class]")
    assert_empty fragment.css("[style]")
  end

  test "optional descriptions and notes do not leave empty semantics" do
    example = Gallery::Example.new(
      slug: "minimal",
      title: "Minimal",
      code: Gallery::SourceCode.new(content: "plain(\"Minimal\")", path: "example.rb")
    )
    node = render_fragment(example) { }.first_element_child
    empty_notes = render_fragment(Gallery::Notes.new)

    assert_nil node["aria-describedby"]
    assert_empty node.css("[data-gallery='example-header'] p")
    assert_empty node.css("[data-gallery='notes']")
    assert_empty empty_notes.children
  end

  test "slugs normalize underscores and reject unstable identities" do
    assert_equal "button-variants", Gallery::Section.new(slug: :button_variants, title: "Variants").slug

    [ "", "Uppercase", "two words", "with/slash", "with.dot" ].each do |slug|
      error = assert_raises(ArgumentError) do
        Gallery::Example.new(slug:, title: "Example", code: example_source)
      end
      assert_match(/only lowercase letters, numbers, and hyphens/, error.message)
    end
  end

  test "examples reject unknown closed presentation values" do
    {
      mode: :wide,
      layout: :columns,
      density: :dense
    }.each do |option, value|
      error = assert_raises(ArgumentError) do
        Gallery::Example.new(slug: "example", title: "Example", code: example_source, **{ option => value })
      end
      assert_match(/Unknown #{option}/, error.message)
    end
  end

  test "titles descriptions and notes reject blank values" do
    assert_raises(ArgumentError) { Gallery::Section.new(slug: "section", title: "") }
    assert_raises(ArgumentError) { Gallery::Sample.new(slug: "sample", label: " ") }
    assert_raises(ArgumentError) { Gallery::Notes.new(source: "") }
    assert_raises(ArgumentError) do
      Gallery::Example.new(slug: "example", title: "Example", description: false, code: example_source)
    end
    assert_raises(ArgumentError) { Gallery::Example.new(slug: "example", title: "Example", code: nil) }
    assert_raises(ArgumentError) { Gallery::SourceCode.new(content: "", path: "example.rb") }
    assert_raises(ArgumentError) { Gallery::SourceCode.new(content: "plain(\"Example\")", path: " ") }
    assert_raises(ArgumentError) { Gallery::CodeSample.new(id: "example", source: "plain(\"Example\")") }
  end

  private

  def page
    ProbePage.new(
      entry: Entry.new(
        slug: "button",
        title: "Button",
        description: "Actions and links with typed variants and sizes."
      )
    )
  end

  def example_source
    @example_source ||= Gallery::SourceCode.new(content: 'plain("Example")', path: "example.rb")
  end

  def render_fragment(component, &block)
    Nokogiri::HTML.fragment(component.call(&block))
  end
end
