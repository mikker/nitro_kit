require "test_helper"

load File.expand_path("../../lib/tasks/nitro_kit_tasks.rake", __dir__) unless defined?(NitroKit::CssBundle)

class AuthShellTest < ActiveSupport::TestCase
  class LandmarkProbe < Phlex::HTML
    def view_template
      render NitroKit::AuthShell.new(
        id: "session",
        aria: { label: "Account access" },
        data: { turbo_permanent: true }
      ) do
        article(id: "credentials") { "Credentials" }
      end
    end
  end

  class OwnershipProbe < Phlex::HTML
    def view_template
      render NitroKit::AuthShell.new do
        header { "Application-owned brand" }
        section { "Application-owned form surface" }
        footer { "Application-owned navigation" }
      end
    end
  end

  test "renders the semantic auth landmark through the accepted narrow layout composition" do
    node = render_probe(LandmarkProbe)

    assert_equal "main", node.name
    assert_equal "auth-shell", node["data-nk"]
    assert_equal "session", node["id"]
    assert_equal "Account access", node["aria-label"]
    assert node.key?("data-turbo-permanent")

    assert_equal 1, node.element_children.count
    container = node.element_children.first
    assert_equal "container", container["data-nk"]
    assert_equal "md", container["data-size"]

    assert_equal 1, container.element_children.count
    stack = container.element_children.first
    assert_equal "flex", stack["data-nk"]
    assert_equal "col", stack["data-dir"]
    assert_equal "6", stack["data-gap"]
    assert_equal "stretch", stack["data-align"]

    assert_equal 1, stack.element_children.count
    assert_equal "credentials", stack.element_children.first["id"]
    assert_empty node.css("[class], [style], [data-slot], [data-nk-escape]")
  end

  test "requires direct content without inventing shell regions or variants" do
    error = assert_raises(ArgumentError) { NitroKit::AuthShell.new.call }

    assert_match(/requires a content block/, error.message)
    assert_raises(ArgumentError) { NitroKit::AuthShell.new(variant: :centered) }
    assert_raises(ArgumentError) { NitroKit::AuthShell.new(branding: "Nitro") }

    node = render_probe(OwnershipProbe)

    assert_equal %w[header section footer], node.css("[data-nk='flex'][data-dir='col'] > *").map(&:name)
    assert_empty node.css("[data-nk='card'], [data-slot], turbo-frame")
  end

  test "preserves the shared native attribute and class escape boundaries" do
    node = render_node(
      NitroKit::AuthShell.new(
        html: { title: "Account access" },
        aria: { describedby: "access-help" },
        data: { application_state: "ready" },
        desperately_need_a_class: "external-auth-root"
      )
    ) { "Content" }

    assert_equal "Account access", node["title"]
    assert_equal "access-help", node["aria-describedby"]
    assert_equal "ready", node["data-application-state"]
    assert_equal "external-auth-root", node["class"]
    assert_equal "class", node["data-nk-escape"]

    assert_raises(ArgumentError) { NitroKit::AuthShell.new(html: { class: "utility" }) }
    assert_raises(ArgumentError) { NitroKit::AuthShell.new(html: { style: "padding: 1rem" }) }
    assert_raises(ArgumentError) { NitroKit::AuthShell.new(data: { nk: "replacement" }) }
  end

  test "keeps unsupported public and authentication panel shells explicitly absent" do
    assert NitroKit.const_defined?(:AppShell, false)
    refute NitroKit.const_defined?(:MarketingShell, false)
    refute NitroKit.const_defined?(:AuthenticationPanel, false)
  end

  test "owns only root gutters and delegates constraint and rhythm to layouts" do
    css = NitroKit::CssBundle.compile
    source = Rails.root.join("../../src/stylesheets/nitro_kit/components/auth_shell.css").cleanpath.read

    assert_includes css, "Source: src/stylesheets/nitro_kit/components/auth_shell.css"
    assert_includes source, ':where([data-nk="auth-shell"])'
    assert_includes source, "width: 100%"
    assert_includes source, "min-width: 0"
    assert_includes source, "padding-block: calc(var(--nk-space) * 8)"
    assert_includes source, "padding-inline: calc(var(--nk-space) * 4)"
    refute_includes source, "max-width"
    refute_match(/\[data-nk="auth-shell"\]\s+\[/, source)
  end

  test "ships the component and its source stylesheet in the engine package" do
    files = Gem::Specification.load(NitroKit::Engine.root.join("nitro_kit.gemspec").to_s).files

    assert_includes files, "app/components/nitro_kit/auth_shell.rb"
    assert_includes files, "src/stylesheets/nitro_kit/components/auth_shell.css"
  end

  private

  def render_node(component, &block)
    Nokogiri::HTML.fragment(component.call(&block)).first_element_child
  end

  def render_probe(probe)
    Nokogiri::HTML.fragment(probe.new.call).first_element_child
  end
end
