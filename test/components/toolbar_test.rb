require "test_helper"

load File.expand_path("../../lib/tasks/nitro_kit_tasks.rake", __dir__) unless defined?(NitroKit::CssBundle)

class ToolbarTest < ActiveSupport::TestCase
  class CompositionProbe < Phlex::HTML
    def view_template
      render NitroKit::Toolbar.new(id: "leading-only") do |toolbar|
        toolbar.leading { render NitroKit::Badge.new("12 records") }
      end
      render NitroKit::Toolbar.new(id: "trailing-only") do |toolbar|
        toolbar.trailing { render NitroKit::Button.new("Save") }
      end
      render NitroKit::Toolbar.new(id: "split") do |toolbar|
        toolbar.leading { h2 { "Members" } }
        toolbar.trailing do
          render NitroKit::ButtonGroup.new(label: "Member actions") do |group|
            group.button("Invite")
            group.button("Export")
          end
        end
      end
    end
  end

  test "renders owned regions in semantic order regardless of declaration order" do
    node = render_node(NitroKit::Toolbar.new) do |bar|
      bar.trailing { "Trailing" }
      bar.leading { "Leading" }
    end

    assert_equal "div", node.name
    assert_equal "toolbar", node["data-nk"]
    assert_equal %w[toolbar-leading toolbar-trailing], node.element_children.map { |child| child["data-slot"] }
    assert_equal "Leading", node.at_css("[data-slot='toolbar-leading']").text
    assert_equal "Trailing", node.at_css("[data-slot='toolbar-trailing']").text
  end

  test "covers leading trailing and split compositions without widget semantics" do
    probe = composition_probe
    leading = probe.at_css("#leading-only")
    trailing = probe.at_css("#trailing-only")
    split = probe.at_css("#split")

    [ leading, trailing, split ].each do |node|
      assert_equal "toolbar", node["data-nk"]
      assert_nil node["role"]
      assert_empty node.css("[class], [style]")
    end
    assert_equal 1, leading.xpath("./*[@data-slot='toolbar-leading']").count
    assert_empty leading.xpath("./*[@data-slot='toolbar-trailing']")
    assert_equal 1, trailing.xpath("./*[@data-slot='toolbar-trailing']").count
    assert_empty trailing.xpath("./*[@data-slot='toolbar-leading']")
    assert_equal %w[toolbar-leading toolbar-trailing], split.element_children.map { |child| child["data-slot"] }
    assert_equal 2, split.css("[data-nk='button-group'] [data-nk='button']").count
  end

  test "rejects empty and duplicate region declarations" do
    assert_match(/requires a leading or trailing region/, assert_raises(ArgumentError) do
      NitroKit::Toolbar.new.call
    end.message)
    assert_match(/at most one leading region/, assert_raises(ArgumentError) do
      NitroKit::Toolbar.new.call do |toolbar|
        toolbar.leading
        toolbar.leading
      end
    end.message)
    assert_match(/at most one trailing region/, assert_raises(ArgumentError) do
      NitroKit::Toolbar.new.call do |toolbar|
        toolbar.trailing
        toolbar.trailing
      end
    end.message)
  end

  test "composes application attributes on the root and on each region" do
    node = render_node(
      NitroKit::Toolbar.new(
        id: "toolbar-attrs",
        html: { title: "Member actions" },
        aria: { label: "Member actions" },
        data: { application_state: "ready" }
      )
    ) do |bar|
      bar.leading(html: { id: "leading-attrs" }, aria: { label: "Counts" }, data: { region: "leading" })
      bar.trailing(html: { id: "trailing-attrs" }, data: { region: "trailing" })
    end

    assert_equal "toolbar-attrs", node["id"]
    assert_equal "Member actions", node["title"]
    assert_equal "Member actions", node["aria-label"]
    assert_equal "ready", node["data-application-state"]
    assert_equal "Counts", node.at_css("#leading-attrs")["aria-label"]
    assert_equal "leading", node.at_css("#leading-attrs")["data-region"]
    assert_equal "trailing", node.at_css("#trailing-attrs")["data-region"]
    assert_empty node.css("[class], [style], [data-nk-escape]")
  end

  test "rejects reserved Nitro data and emits the deliberate class escape" do
    node = render_node(
      NitroKit::Toolbar.new(desperately_need_a_class: "external-toolbar")
    ) do |bar|
      bar.leading(desperately_need_a_class: "external-leading", html: { id: "leading-escape" })
      bar.trailing(desperately_need_a_class: "external-trailing", html: { id: "trailing-escape" })
    end

    assert_equal "external-toolbar", node["class"]
    assert_equal "class", node["data-nk-escape"]
    assert_equal "class", node.at_css("#leading-escape")["data-nk-escape"]
    assert_equal "class", node.at_css("#trailing-escape")["data-nk-escape"]

    assert_raises(ArgumentError) { NitroKit::Toolbar.new(html: { class: "utility" }) }
    assert_raises(ArgumentError) { NitroKit::Toolbar.new(html: { style: "display: none" }) }
    %i[nk slot variant size state].each do |reserved|
      assert_raises(ArgumentError) { NitroKit::Toolbar.new(data: { reserved => "replacement" }) }
    end
    assert_raises(ArgumentError) do
      NitroKit::Toolbar.new.call { |bar| bar.leading(data: { slot: "replacement" }) }
    end
  end

  test "owns wide placement and narrow stacking in static CSS" do
    source = NitroKit::Engine.root.join("src/stylesheets/nitro_kit/components/toolbar.css").read

    assert_includes NitroKit::CssBundle.compile, %([data-nk="toolbar"])
    assert_includes source, "@media (max-width: 48rem)"
    refute_includes source, "transition: all"
    refute_match(/(?:\:where\(\s*|,\s*)\[data-slot=/m, source)
  end

  test "is reachable through the gallery catalog" do
    entry = Gallery::Catalog.fetch!(kind: :component, slug: "toolbar")

    assert_equal Gallery::Components::ToolbarPage, entry.page
    assert_includes entry.expected_roots, "toolbar"
  end

  private

  def render_node(component, &block)
    Nokogiri::HTML.fragment(component.call(&block)).first_element_child
  end

  def composition_probe
    Nokogiri::HTML.fragment(CompositionProbe.new.call)
  end
end
