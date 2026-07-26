require "test_helper"

load File.expand_path("../../lib/tasks/nitro_kit_tasks.rake", __dir__) unless defined?(NitroKit::CssBundle)

class NavigationBlocksTest < ActiveSupport::TestCase
  test "compound blocks render their owned regions in semantic order" do
    settings = render_node(NitroKit::SettingsLayout.new) do |layout|
      layout.content { "Content" }
      layout.navigation(label: "Settings") { layout.item("Profile", href: "/settings/profile") }
    end
    assert_equal %w[settings-layout-navigation settings-layout-content], settings.element_children.map { |node| node["data-slot"] }

    toolbar = render_node(NitroKit::Toolbar.new) do |bar|
      bar.trailing { "Trailing" }
      bar.leading { "Leading" }
    end
    assert_equal %w[toolbar-leading toolbar-trailing], toolbar.element_children.map { |node| node["data-slot"] }

    pagination_bar = render_node(NitroKit::PaginationBar.new) do |bar|
      bar.pagination(NitroKit::Pagination.new) { |pagination| pagination.page(1, current: true) }
      bar.summary("1 result")
    end
    assert_equal %w[pagination-bar-summary pagination-bar-pagination], pagination_bar.element_children.map { |node| node["data-slot"] }
  end

  class CompositionProbe < Phlex::HTML
    def view_template
      render NitroKit::SettingsLayout.new(id: "settings") do |layout|
        layout.navigation(label: "Account settings") do
          layout.item("Profile", href: "/settings/profile", current: true)
          layout.item("Security", href: "/settings/security")
        end
        layout.content do
          render NitroKit::Card.new { |card| card.body("Profile form") }
        end
      end

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

  test "settings layout renders one semantic navigation list and one neutral content region" do
    node = composition_probe.at_css("#settings")
    navigation = node.at_xpath("./*[@data-slot='settings-layout-navigation']")
    content = node.at_xpath("./*[@data-slot='settings-layout-content']")
    items = navigation.at_css("[data-slot='settings-layout-items']")
    profile, security = items.css("[data-slot='settings-layout-item-link']")

    assert_equal "div", node.name
    assert_equal "settings-layout", node["data-nk"]
    assert_equal "nav", navigation.name
    assert_equal "Account settings", navigation["aria-label"]
    assert_equal "ul", items.name
    assert_equal %w[li li], items.element_children.map(&:name)
    assert_equal %w[settings-layout-item settings-layout-item],
      items.element_children.map { |child| child["data-slot"] }
    assert_equal "a", profile.name
    assert_equal "/settings/profile", profile["href"]
    assert_equal "page", profile["aria-current"]
    assert_equal "current", profile["data-state"]
    assert_equal "Profile", profile.text
    assert_nil security["aria-current"]
    assert_equal "default", security["data-state"]
    assert_equal "div", content.name
    assert_nil content["role"]
    assert_equal "card", content.element_children.first["data-nk"]
    assert_empty node.css("[class], [style], [data-nk-escape]")
  end

  test "settings layout requires each region exactly once with items a label and blocks" do
    assert_match(/declaration block/, assert_raises(ArgumentError) { NitroKit::SettingsLayout.new.call }.message)
    assert_match(/one content region/, assert_raises(ArgumentError) do
      settings_layout { |layout| layout.navigation(label: "Settings") { layout.item("One", href: "/one") } }
    end.message)
    assert_match(/one navigation region/, assert_raises(ArgumentError) do
      settings_layout { |layout| layout.content { "Content" } }
    end.message)
    assert_match(/navigation requires a block/, assert_raises(ArgumentError) do
      settings_layout { |layout| layout.navigation(label: "Settings") }
    end.message)
    assert_match(/content requires a block/, assert_raises(ArgumentError) do
      settings_layout do |layout|
        layout.navigation(label: "Settings") { layout.item("One", href: "/one") }
        layout.content
      end
    end.message)
    assert_match(/at least one item/, assert_raises(ArgumentError) do
      settings_layout { |layout| layout.navigation(label: "Settings") { } }
    end.message)
    assert_match(/exactly one navigation region/, assert_raises(ArgumentError) do
      settings_layout do |layout|
        layout.navigation(label: "Settings") { layout.item("One", href: "/one") }
        layout.navigation(label: "Duplicate") { layout.item("Two", href: "/two") }
      end
    end.message)
    assert_match(/exactly one content region/, assert_raises(ArgumentError) do
      settings_layout do |layout|
        layout.navigation(label: "Settings") { layout.item("One", href: "/one") }
        layout.content { "First" }
        layout.content { "Second" }
      end
    end.message)

    [ nil, :settings, "", "  " ].each do |label|
      assert_raises(ArgumentError) do
        settings_layout { |layout| layout.navigation(label:) { layout.item("One", href: "/one") } }
      end
    end
  end

  test "settings layout validates its item vocabulary and rejects out-of-phase declarations" do
    invalid_items = [
      ->(layout) { layout.item(nil, href: "/one") },
      ->(layout) { layout.item("One", href: " ") },
      ->(layout) { layout.item("One", href: "/one", current: :yes) }
    ]
    invalid_items.each do |declaration|
      assert_raises(ArgumentError) do
        settings_layout { |layout| layout.navigation(label: "Settings") { declaration.call(layout) } }
      end
    end

    assert_match(/at most one current item/, assert_raises(ArgumentError) do
      settings_layout do |layout|
        layout.navigation(label: "Settings") do
          layout.item("One", href: "/one", current: true)
          layout.item("Two", href: "/two", current: true)
        end
      end
    end.message)

    layout = NitroKit::SettingsLayout.new
    assert_match(/directly inside the render block/, assert_raises(ArgumentError) do
      layout.navigation(label: "Settings") { }
    end.message)
    assert_match(/directly inside the render block/, assert_raises(ArgumentError) { layout.content { "Content" } }.message)
    assert_match(/directly inside the navigation block/, assert_raises(ArgumentError) do
      layout.item("One", href: "/one")
    end.message)
    assert_match(/directly inside the navigation block/, assert_raises(ArgumentError) do
      settings_layout do |component|
        component.navigation(label: "Settings") { component.item("One", href: "/one") }
        component.content { component.item("Nested", href: "/nested") }
      end
    end.message)
    assert_match(/structure accepts declarations/, assert_raises(ArgumentError) do
      settings_layout do |component|
        component.navigation(label: "Settings") { component.item("One", href: "/one") }
        component.content { "Content" }
        "Unexpected"
      end
    end.message)
    assert_match(/navigation accepts declarations/, assert_raises(ArgumentError) do
      settings_layout do |component|
        component.navigation(label: "Settings") do
          component.item("One", href: "/one")
          "Unexpected"
        end
        component.content { "Content" }
      end
    end.message)
  end

  test "toolbar covers leading trailing and split compositions without widget semantics" do
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

  test "toolbar rejects empty and duplicate region declarations" do
    assert_raises(ArgumentError) { NitroKit::Toolbar.new.call }
    assert_raises(ArgumentError) do
      NitroKit::Toolbar.new.call do |toolbar|
        toolbar.leading
        toolbar.leading
      end
    end
    assert_raises(ArgumentError) do
      NitroKit::Toolbar.new.call do |toolbar|
        toolbar.trailing
        toolbar.trailing
      end
    end
  end

  test "pagination bar composes caller summary with exactly one typed Pagination" do
    node = render_pagination_bar
    summary = node.at_xpath("./*[@data-slot='pagination-bar-summary']")
    pagination = node.at_xpath("./*[@data-slot='pagination-bar-pagination']")

    assert_equal "pagination-bar", node["data-nk"]
    assert_equal "p", summary.name
    assert_equal "Showing 26–50 of 121 members", summary.text
    assert_equal "polite", summary["aria-live"]
    assert_equal "nav", pagination.name
    assert_equal "pagination", pagination["data-nk"]
    assert_equal "Member pages", pagination["aria-label"]
    assert_equal "page", pagination.at_css("[data-slot='pagination-current'][aria-current]")["aria-current"]
    assert_empty node.css("[class], [style], [data-nk-escape]")
  end

  test "pagination bar announces summary changes politely by default" do
    node = render_node(NitroKit::PaginationBar.new) do |bar|
      bar.summary("Showing 1–25 of 121 members")
      bar.pagination(NitroKit::Pagination.new) { |pagination| pagination.page(1, current: true) }
    end
    assertive = render_node(NitroKit::PaginationBar.new) do |bar|
      bar.summary("Showing 1–25 of 121 members", aria: { live: "assertive" })
      bar.pagination(NitroKit::Pagination.new) { |pagination| pagination.page(1, current: true) }
    end

    assert_equal "polite", node.at_css("[data-slot='pagination-bar-summary']")["aria-live"]
    assert_equal "assertive", assertive.at_css("[data-slot='pagination-bar-summary']")["aria-live"]
  end

  test "pagination bar allows an omitted summary but rejects missing wrong and duplicate Pagination" do
    without_summary = render_node(NitroKit::PaginationBar.new) do |bar|
      bar.pagination(NitroKit::Pagination.new) { |pagination| pagination.page(1, current: true) }
    end

    assert_empty without_summary.xpath("./*[@data-slot='pagination-bar-summary']")
    assert_equal 1, without_summary.xpath("./*[@data-slot='pagination-bar-pagination']").count
    assert_raises(ArgumentError) { NitroKit::PaginationBar.new.call }
    assert_raises(ArgumentError) do
      NitroKit::PaginationBar.new.call { |bar| bar.summary("No navigation") }
    end
    [ nil, :summary, "", "  " ].each do |summary|
      assert_raises(ArgumentError) do
        NitroKit::PaginationBar.new.call { |bar| bar.summary(summary) }
      end
    end
    assert_raises(ArgumentError) do
      NitroKit::PaginationBar.new.call { |bar| bar.pagination(NitroKit::Button.new("Wrong")) }
    end
    assert_raises(ArgumentError) do
      NitroKit::PaginationBar.new.call do |bar|
        bar.pagination(NitroKit::Pagination.new) { |pagination| pagination.page(1, current: true) }
        bar.pagination(NitroKit::Pagination.new) { |pagination| pagination.page(2, current: true) }
      end
    end
    assert_raises(ArgumentError) do
      NitroKit::PaginationBar.new.call do |bar|
        bar.summary("First")
        bar.summary("Second")
      end
    end
  end

  test "all blocks preserve bounded root slot and class escape attributes" do
    settings = render_node(
      NitroKit::SettingsLayout.new(
        id: "settings-attrs",
        html: { title: "Settings boundary" },
        aria: { describedby: "settings-help" },
        data: { application_state: "ready" },
        desperately_need_a_class: "external-settings"
      )
    ) do |layout|
      layout.navigation(label: "Settings") { layout.item("Profile", href: "/profile") }
      layout.content { "Content" }
    end
    toolbar = render_node(
      NitroKit::Toolbar.new(
        id: "toolbar-attrs",
        data: { application_state: "ready" },
        desperately_need_a_class: "external-toolbar"
      )
    ) do |bar|
      bar.leading(
        html: { id: "leading-attrs" },
        desperately_need_a_class: "external-leading"
      )
    end
    pagination_bar = render_node(
      NitroKit::PaginationBar.new(
        id: "pagination-bar-attrs",
        desperately_need_a_class: "external-pagination-bar"
      )
    ) do |bar|
      bar.summary(
        "Summary",
        html: { id: "summary-attrs" },
        desperately_need_a_class: "external-summary"
      )
      bar.pagination(
        NitroKit::Pagination.new(
          desperately_need_a_class: "external-pagination"
        )
      ) { |pagination| pagination.page(1, current: true) }
    end

    assert_equal "Settings boundary", settings["title"]
    assert_equal "settings-help", settings["aria-describedby"]
    assert_equal "ready", settings["data-application-state"]
    assert_equal "external-settings", settings["class"]
    assert_equal "class", settings["data-nk-escape"]
    assert_empty settings.css("[data-nk-escape]")
    assert_equal "ready", toolbar["data-application-state"]
    assert_equal "class", toolbar["data-nk-escape"]
    assert_equal "class", toolbar.at_css("#leading-attrs")["data-nk-escape"]
    assert_equal "class", pagination_bar["data-nk-escape"]
    assert_equal "class", pagination_bar.at_css("#summary-attrs")["data-nk-escape"]
    assert_equal "pagination-bar-pagination", pagination_bar.at_css("[data-nk='pagination']")["data-slot"]
    assert_equal "class", pagination_bar.at_css("[data-nk='pagination']")["data-nk-escape"]

    [ NitroKit::SettingsLayout, NitroKit::Toolbar, NitroKit::PaginationBar ].each do |component|
      assert_raises(ArgumentError) { component.new(html: { class: "utility" }) }
      assert_raises(ArgumentError) { component.new(html: { style: "display: none" }) }
      assert_raises(ArgumentError) { component.new(data: { nk: "replacement" }) }
    end
  end

  test "owned CSS fixes wide placement and narrow stacking without public layout options" do
    css = NitroKit::CssBundle.compile

    %w[settings-layout toolbar pagination-bar].each do |name|
      assert_includes css, %([data-nk="#{name}"])
    end
    assert_includes css, "grid-template-columns: minmax(10rem, 14rem) minmax(0, 1fr)"
    assert_includes css, "flex-wrap: wrap"
    assert_includes css, "justify-content: space-between"
    block_css = %w[settings_layout toolbar pagination_bar].to_h do |name|
      path = NitroKit::Engine.root.join("src/stylesheets/nitro_kit/components/#{name}.css")
      [ name, File.read(path) ]
    end
    block_css.each_value { |source| assert_includes source, "@media (max-width: 48rem)" }
    block_css.each_value { |source| refute_includes source, "max-width: 40rem" }
    assert_includes css, "flex-direction: column"
    assert_includes css, %([data-nk="pagination"][data-slot="pagination-bar-pagination"])
    refute_includes css, "transition: all"
    block_css.each_value do |source|
      refute_match(/(?:\:where\(\s*|,\s*)\[data-slot=/m, source)
    end
  end

  test "the engine package includes the three blocks and deliberately omits ProgressSteps" do
    files = Gem::Specification.load(NitroKit::Engine.root.join("nitro_kit.gemspec").to_s).files

    %w[pagination_bar settings_layout toolbar].each do |name|
      assert_includes files, "app/components/nitro_kit/#{name}.rb"
      assert_includes files, "src/stylesheets/nitro_kit/components/#{name}.css"
    end

    refute_includes files, "app/components/nitro_kit/progress_steps.rb"
    refute_includes files, "src/stylesheets/nitro_kit/components/progress_steps.css"
  end

  private

  def render_pagination_bar
    render_node(NitroKit::PaginationBar.new(id: "member-pages")) do |bar|
      bar.summary(
        "Showing 26–50 of 121 members",
        html: { id: "member-summary" },
        aria: { live: "polite" }
      )
      bar.pagination(NitroKit::Pagination.new(label: "Member pages")) do |pagination|
        pagination.prev(href: "/members?page=1")
        pagination.page(1, href: "/members?page=1")
        pagination.page(2, current: true)
        pagination.next(href: "/members?page=3")
      end
    end
  end

  def render_node(component, &block)
    Nokogiri::HTML.fragment(component.call(&block)).first_element_child
  end

  def settings_layout(&block)
    render_node(NitroKit::SettingsLayout.new, &block)
  end

  def composition_probe
    Nokogiri::HTML.fragment(CompositionProbe.new.call)
  end
end
