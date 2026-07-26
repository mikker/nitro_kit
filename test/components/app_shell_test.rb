require "test_helper"

class AppShellTest < ActiveSupport::TestCase
  test "renders every layout with one canonical navigation tree and accessible shell controls" do
    NitroKit::AppShell::LAYOUTS.each do |layout|
      node = render_shell(NitroKit::AppShell.new(id: "workspace-#{layout}", layout:)) do |shell|
        shell.main { "Dashboard" }
        shell.topbar { "Account" }
        shell.navigation { |view| render_navigation(view) }
        shell.brand { "Acme" }
      end

      assert_equal "div", node.name
      assert_equal "app-shell", node["data-nk"]
      assert_equal layout.to_s, node["data-layout"]
      assert_nil node["data-variant"]
      assert_equal "closed", node["data-state"]
      assert_equal "nk--app-shell", node["data-controller"]
      assert_includes node["data-action"], "turbo:before-visit@document->nk--app-shell#closeForNavigation"
      assert_includes node["data-action"], "turbo:morph@document->nk--app-shell#syncViewport"
      assert_equal %w[
        app-shell-skip-link
        app-shell-header
        app-shell-sidebar
        app-shell-dialog
        app-shell-main
      ], node.element_children.map { |child| child["data-slot"] }
      header = node.at_css("[data-slot='app-shell-header']")
      assert_equal "header", header.name
      assert_equal %w[app-shell-brand app-shell-mobile-trigger app-shell-topbar],
        header.element_children.map { |child| child["data-slot"] }
      assert_equal 1, node.css("[data-nk='app-navigation']").size
      assert_empty node.css("[class], [style], [data-nk-escape]")
    end
  end

  test "owns deterministic drawer main and skip-link relationships" do
    node = render_shell do |shell|
      shell.navigation { |view| render_navigation(view) }
      shell.main { "Dashboard" }
    end

    skip_link = node.at_css("[data-slot='app-shell-skip-link']")
    trigger = node.at_css("[data-slot='app-shell-mobile-trigger']")
    sidebar = node.at_css("[data-slot='app-shell-sidebar']")
    dialog = node.at_css("[data-slot='app-shell-dialog']")
    main = node.at_css("[data-slot='app-shell-main']")
    close = dialog.at_css("[data-slot='app-shell-mobile-close']")

    assert_equal "#workspace-main", skip_link["href"]
    assert_equal "workspace-navigation-drawer", dialog["id"]
    assert_equal "workspace-navigation-drawer", trigger["aria-controls"]
    assert_equal "false", trigger["aria-expanded"]
    assert_equal I18n.t("nitro_kit.app_shell.open_navigation"), trigger["aria-label"]
    assert_equal "trigger", trigger["data-nk--app-shell-target"]
    assert_equal "div", sidebar.name
    assert_equal "sidebar", sidebar["data-nk--app-shell-target"]
    assert_equal "navigation", sidebar.at_css("[data-slot='app-shell-navigation']")["data-nk--app-shell-target"]
    assert_equal "dialog", dialog.name
    assert_equal "dialog", dialog["data-nk--app-shell-target"]
    assert_equal I18n.t("nitro_kit.app_shell.navigation_dialog"), dialog["aria-label"]
    assert_nil dialog["open"]
    assert_nil node["data-enhanced"]
    assert_equal "button", close.name
    assert_equal I18n.t("nitro_kit.app_shell.close_navigation"), close["aria-label"]
    assert_equal "click->nk--app-shell#close", close["data-action"]
    assert_equal "workspace-main", main["id"]
    assert_equal "main", main.name
    assert_empty node.css("[data-slot='app-shell-backdrop']")
  end

  test "accepts configurable non-blank labels" do
    node = render_shell(
      NitroKit::AppShell.new(
        id: "workspace",
        skip_link_label: "Spring til indhold",
        open_navigation_label: "Åbn navigation",
        close_navigation_label: "Luk navigation",
        navigation_dialog_label: "Programnavigation"
      )
    ) do |shell|
      shell.navigation { |view| render_navigation(view) }
      shell.main { "Dashboard" }
    end

    assert_equal "Spring til indhold", node.at_css("[data-slot='app-shell-skip-link']").text
    assert_equal "Åbn navigation", node.at_css("[data-slot='app-shell-mobile-trigger']")["aria-label"]
    assert_equal "Luk navigation", node.at_css("[data-slot='app-shell-mobile-close']")["aria-label"]
    assert_equal "Programnavigation", node.at_css("[data-slot='app-shell-dialog']")["aria-label"]
    assert_equal "Åbn navigation", node["data-nk--app-shell-open-label-value"]
    assert_equal "Luk navigation", node["data-nk--app-shell-close-label-value"]

    %i[skip_link_label open_navigation_label close_navigation_label navigation_dialog_label].each do |label|
      assert_match(/#{label} must be a non-blank String/, assert_raises(ArgumentError) do
        NitroKit::AppShell.new(id: "workspace", **{ label => "  " })
      end.message)
    end
  end

  test "requires exactly one navigation and main and limits optional regions" do
    assert_match(/declaration block/, assert_raises(ArgumentError) do
      NitroKit::AppShell.new(id: "workspace").call
    end.message)
    assert_match(/navigation region/, assert_raises(ArgumentError) do
      render_shell { |shell| shell.main { "Main" } }
    end.message)
    assert_match(/main region/, assert_raises(ArgumentError) do
      render_shell { |shell| shell.navigation { |view| render_navigation(view) } }
    end.message)

    %i[brand navigation topbar main].each do |region|
      assert_raises(ArgumentError) do
        render_shell do |shell|
          shell.navigation { |view| render_navigation(view) }
          shell.main { "Main" }
          shell.public_send(region) { "One" }
          shell.public_send(region) { "Two" }
        end
      end
    end

    %i[brand navigation topbar main].each do |region|
      assert_match(/requires a block/, assert_raises(ArgumentError) do
        render_shell do |shell|
          shell.public_send(region)
        end
      end.message)
    end
  end

  test "validates identity and layout as a closed vocabulary" do
    assert_predicate NitroKit::AppShell::LAYOUTS, :frozen?
    assert_equal %i[sidebar topbar hybrid], NitroKit::AppShell::LAYOUTS
    assert_predicate NitroKit::AppShell::REGIONS, :frozen?
    assert_equal %i[brand navigation topbar main], NitroKit::AppShell::REGIONS
    assert_raises(ArgumentError) { NitroKit::AppShell.new }

    [ nil, "", "  ", "two words", "workspace#main", "workspace%20main", :workspace ].each do |id|
      assert_match(/id must be/, assert_raises(ArgumentError) { NitroKit::AppShell.new(id:) }.message)
    end
    assert_match(/Unknown layout/, assert_raises(ArgumentError) do
      NitroKit::AppShell.new(id: "workspace", layout: :drawer)
    end.message)
  end

  test "rejects region declarations outside collection and arbitrary render-block output" do
    shell = NitroKit::AppShell.new(id: "workspace")
    %i[brand navigation topbar main].each do |region|
      assert_match(/directly inside the render block/, assert_raises(ArgumentError) do
        shell.public_send(region) { "Content" }
      end.message)
    end

    assert_match(/accepts region declarations/, assert_raises(ArgumentError) do
      render_shell do |component|
        component.navigation { |view| render_navigation(view) }
        component.main { "Main" }
        "Unexpected"
      end
    end.message)
  end

  test "preserves bounded root attributes and the explicit class escape" do
    node = render_shell(
      NitroKit::AppShell.new(
        id: "workspace",
        html: { title: "Workspace" },
        aria: { label: "Workspace shell" },
        data: { controller: "analytics", tracking_id: "shell" },
        desperately_need_a_class: "external-shell"
      )
    ) do |shell|
      shell.navigation { |view| render_navigation(view) }
      shell.main { "Dashboard" }
    end

    assert_equal "Workspace", node["title"]
    assert_equal "Workspace shell", node["aria-label"]
    assert_equal "nk--app-shell analytics", node["data-controller"]
    assert_equal "shell", node["data-tracking-id"]
    assert_equal "external-shell", node["class"]
    assert_equal "class", node["data-nk-escape"]

    assert_raises(ArgumentError) { NitroKit::AppShell.new(id: "workspace", html: { class: "utility" }) }
    assert_raises(ArgumentError) { NitroKit::AppShell.new(id: "workspace", data: { state: "open" }) }
    assert_raises(ArgumentError) { NitroKit::AppShell.new(id: "workspace", data: { variant: "topbar" }) }
    assert_raises(ArgumentError) { NitroKit::AppShell.new(id: "workspace", data: { layout: "topbar" }) }
    assert_includes NitroKit::Component::RESERVED_DATA_ATTRIBUTES, "enhanced"
    refute_includes NitroKit::Component::COMPONENT_OWNED_DATA_ATTRIBUTES, "enhanced"
  end

  private

  def render_shell(component = NitroKit::AppShell.new(id: "workspace"), &block)
    Nokogiri::HTML.fragment(component.call(&block)).first_element_child
  end

  def render_navigation(view)
    view.render NitroKit::AppNavigation.new(label: "Primary") do |navigation|
      navigation.body { navigation.item("Dashboard", href: "/dashboard", current: true) }
    end
  end
end
