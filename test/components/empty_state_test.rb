require "test_helper"

load File.expand_path("../../lib/tasks/nitro_kit_tasks.rake", __dir__) unless defined?(NitroKit::CssBundle)

class EmptyStateTest < ActiveSupport::TestCase
  class DeferredContentProbe < Phlex::HTML
    def view_template
      render NitroKit::EmptyState.new(level: 4, id: "deferred-empty-state") do |empty|
        empty.description { plain "Try a "; strong { "broader" }; plain " query." }
        empty.title { plain "No "; em { "records" } }
      end
    end
  end

  test "renders zero one and two action cardinalities" do
    minimal = render_node(NitroKit::EmptyState.new(title: "Nothing here"))
    assert_equal "section", minimal.name
    assert_equal "empty-state", minimal["data-nk"]
    assert_equal [ "h2" ], minimal.element_children.map(&:name)

    complete = render_node(
      NitroKit::EmptyState.new(
        title: "No teammates yet",
        description: "Invite collaborators when you are ready.",
        level: 4,
        id: "empty-team"
      )
    ) do |empty|
      empty.icon NitroKit::Icon.new(:users)
      empty.action NitroKit::Button.new("Invite teammate", href: "/invite", variant: :primary)
      empty.action NitroKit::Button.new("Read access guide", href: "/guide")
    end

    assert_equal "empty-state-icon", complete.at_css("[data-nk='icon']")["data-slot"]
    assert complete.at_css("h4[data-slot='empty-state-title']")
    assert_equal "Invite collaborators when you are ready.",
      complete.at_css("[data-slot='empty-state-description']").text
    assert_equal 2, complete.css("[data-slot='empty-state-actions'] > [data-slot='empty-state-action'][data-nk='button']").count
    assert_empty complete.css("[class], [style], [data-nk-escape]")
  end

  test "renders every heading level and validates the closed vocabulary" do
    assert_equal (2..6), NitroKit::EmptyState::TITLE_LEVELS
    assert_equal 2, NitroKit::EmptyState.new(title: "Empty").level

    NitroKit::EmptyState::TITLE_LEVELS.each do |level|
      node = render_node(NitroKit::EmptyState.new(title: "Empty", level:))

      assert_equal "h#{level}", node.at_css("[data-slot='empty-state-title']").name
    end

    [ 1, 7, :three, "3", nil ].each do |level|
      assert_raises(ArgumentError) { NitroKit::EmptyState.new(title: "Empty", level:) }
    end
  end

  test "renders every variant and validates the closed vocabulary" do
    assert_equal %i[default borderless], NitroKit::EmptyState::VARIANTS
    assert_equal :default, NitroKit::EmptyState.new(title: "Empty").variant

    NitroKit::EmptyState::VARIANTS.each do |variant|
      node = render_node(NitroKit::EmptyState.new(title: "Empty", variant:))

      assert_equal variant.to_s, node["data-variant"]
    end

    [ :ghost, "borderless", nil, 1 ].each do |variant|
      error = assert_raises(ArgumentError) { NitroKit::EmptyState.new(title: "Empty", variant:) }

      assert_match(/variant/, error.message)
    end
  end

  test "accepts deferred text and rich Phlex content" do
    node = Nokogiri::HTML.fragment(DeferredContentProbe.new.call).first_element_child

    assert_equal "records", node.at_css("[data-slot='empty-state-title'] em").text
    assert_equal "broader", node.at_css("[data-slot='empty-state-description'] strong").text
    assert_equal %w[h4 p], node.element_children.map(&:name)
  end

  test "rejects missing mixed and repeated content declarations" do
    assert_match(/requires title/, assert_raises(ArgumentError) { render_node(NitroKit::EmptyState.new) }.message)
    assert_raises(ArgumentError) do
      render_node(NitroKit::EmptyState.new(title: "Keyword title")) { |empty| empty.title("Nested title") }
    end
    assert_raises(ArgumentError) do
      render_node(NitroKit::EmptyState.new) do |empty|
        empty.title("First")
        empty.title("Second")
      end
    end
    assert_raises(ArgumentError) do
      render_node(NitroKit::EmptyState.new) { |empty| empty.title("Text") { "Block" } }
    end
    assert_raises(ArgumentError) { render_node(NitroKit::EmptyState.new) { |empty| empty.title("") } }
    assert_raises(ArgumentError) { NitroKit::EmptyState.new(title: "Empty", description: " ") }
    assert_raises(ArgumentError) do
      render_node(NitroKit::EmptyState.new(title: "Empty", description: "First")) do |empty|
        empty.description("Second")
      end
    end
  end

  test "enforces typed unique bounded children" do
    assert_raises(ArgumentError) do
      render_node(NitroKit::EmptyState.new(title: "Empty")) { |empty| empty.icon NitroKit::Button.new("No") }
    end
    assert_raises(ArgumentError) do
      render_node(NitroKit::EmptyState.new(title: "Empty")) do |empty|
        empty.icon NitroKit::Icon.new(:users)
        empty.icon NitroKit::Icon.new(:circle_user)
      end
    end
    assert_raises(ArgumentError) do
      render_node(NitroKit::EmptyState.new(title: "Empty")) { |empty| empty.action NitroKit::Alert.new }
    end
    assert_raises(ArgumentError) do
      render_node(NitroKit::EmptyState.new(title: "Empty")) do |empty|
        3.times { |index| empty.action NitroKit::Button.new("Action #{index}") }
      end
    end

    repeated = NitroKit::Button.new("Repeated")
    assert_raises(ArgumentError) do
      render_node(NitroKit::EmptyState.new(title: "Empty")) do |empty|
        empty.action repeated
        empty.action repeated
      end
    end
  end

  test "composes application attributes and rejects reserved Nitro data" do
    node = render_node(
      NitroKit::EmptyState.new(
        title: "Empty",
        id: "empty-attrs",
        html: { title: "Nothing to show" },
        aria: { label: "Empty results" },
        data: { application_state: "ready" }
      )
    )

    assert_equal "empty-attrs", node["id"]
    assert_equal "Nothing to show", node["title"]
    assert_equal "Empty results", node["aria-label"]
    assert_equal "ready", node["data-application-state"]
    assert_nil node["class"]
    assert_nil node["style"]

    assert_raises(ArgumentError) { NitroKit::EmptyState.new(title: "Empty", html: { class: "utility" }) }
    assert_raises(ArgumentError) { NitroKit::EmptyState.new(title: "Empty", html: { style: "display: grid" }) }
    %i[nk slot variant size state].each do |reserved|
      assert_raises(ArgumentError) { NitroKit::EmptyState.new(title: "Empty", data: { reserved => "replacement" }) }
    end
  end

  test "emits the deliberate class escape and rejects blank values" do
    node = render_node(NitroKit::EmptyState.new(title: "Empty", desperately_need_a_class: "external-empty-state"))

    assert_equal "external-empty-state", node["class"]
    assert_equal "class", node["data-nk-escape"]
    assert_raises(ArgumentError) { NitroKit::EmptyState.new(title: "Empty", desperately_need_a_class: "") }
  end

  test "ships owner-scoped static CSS" do
    source = NitroKit::Engine.root.join("src/stylesheets/nitro_kit/components/empty_state.css").read

    assert_includes NitroKit::CssBundle.compile, %([data-nk="empty-state"])
    refute_includes source, "transition: all"
    refute_match(/(?:\:where\(\s*|,\s*)\[data-slot=/m, source)
  end

  test "is reachable through the gallery catalog" do
    entry = Gallery::Catalog.fetch!(kind: :component, slug: "empty-state")

    assert_equal Gallery::Components::EmptyStatePage, entry.page
    assert_includes entry.expected_roots, "empty-state"
  end

  private

  def render_node(component, &block)
    Nokogiri::HTML.fragment(component.call(&block)).first_element_child
  end
end
