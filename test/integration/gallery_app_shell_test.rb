require "test_helper"

class GalleryAppShellTest < ActionDispatch::IntegrationTest
  test "catalog publishes focused navigation and shell surfaces" do
    navigation = Gallery::Catalog.fetch!(kind: :component, slug: "app-navigation")
    shell = Gallery::Catalog.fetch!(kind: :component, slug: "app-shell")

    assert_equal Gallery::Components::AppNavigationPage, navigation.page
    assert_equal Gallery::Components::AppShellPage, shell.page
    assert_equal "/gallery/components/app-navigation", Gallery::Catalog.path_for(
      navigation,
      routes: Rails.application.routes.url_helpers
    )
    assert_equal "/gallery/components/app-shell", Gallery::Catalog.path_for(
      shell,
      routes: Rails.application.routes.url_helpers
    )
  end

  test "navigation page covers complete minimal grouped dense and pressure compositions" do
    get gallery_component_path("app-navigation")

    assert_response :success
    assert_select "[data-gallery='example-canvas'] [data-nk='app-navigation']", count: 7 do |navigations|
      navigations.each do |navigation|
        assert_equal 1, navigation.xpath("./*[@data-slot='app-navigation-body']").count
        assert_operator navigation.css("[data-slot='app-navigation-item']").count, :>=, 1
        assert_operator navigation.css("[data-slot='app-navigation-item-link'][aria-current='page']").count, :<=, 1
      end
    end
    assert_select "#gallery-app-navigation-complete" do
      assert_select "> [data-slot='app-navigation-header']", count: 1
      assert_select "> [data-slot='app-navigation-footer']", count: 1
      assert_select "[data-slot='app-navigation-section']", count: 2
      assert_select "[data-slot='app-navigation-divider']", count: 1
      assert_select "[data-slot='app-navigation-spacer']", count: 1
      assert_select "[data-slot='app-navigation-item-icon'][data-nk='icon'][aria-hidden='true']", minimum: 1
      assert_select "[data-slot='app-navigation-item-badge'][data-nk='badge']", count: 2
    end
    assert_select "#gallery-app-navigation-minimal [data-slot='app-navigation-item']", count: 1
    assert_select "#gallery-app-navigation-inventory [data-slot='app-navigation-item']", count: 9
    assert_select "[data-gallery='example-canvas'] [class]", count: 0
    assert_select "[data-gallery='example-canvas'] [style]", count: 0
  end

  test "shell page renders every layout one tree and the complete responsive anatomy" do
    get gallery_component_path("app-shell")

    assert_response :success
    assert_select "[data-gallery='example-canvas'] [data-nk='app-shell']", count: 5 do |shells|
      shells.each do |shell|
        assert_equal "header", shell.at_css("[data-slot='app-shell-header']").name
        assert_equal "div", shell.at_css("[data-slot='app-shell-sidebar']").name
        assert_equal "dialog", shell.at_css("[data-slot='app-shell-dialog']").name
        assert_equal 1, shell.css("[data-nk='app-navigation']").count
        assert_equal 1, shell.css("[data-slot='app-shell-main']").count
        assert_equal 1, shell.css("[data-slot='app-shell-mobile-trigger']").count
        assert_equal 1, shell.css("[data-slot='app-shell-mobile-close']").count
        assert_nil shell["data-enhanced"]
        sidebar = shell.at_css("[data-slot='app-shell-sidebar']")
        dialog = shell.at_css("[data-slot='app-shell-dialog']")
        assert_nil sidebar["aria-hidden"]
        assert_nil dialog["open"]
        assert_equal "Workspace navigation", dialog["aria-label"]
        assert_equal 1, sidebar.css("> [data-slot='app-shell-navigation']").count
      end
    end
    %w[sidebar topbar hybrid].each do |layout|
      assert_select "#gallery-app-shell-#{layout}[data-layout='#{layout}']", count: 1
    end
    assert_select "#gallery-app-shell-minimal [data-slot='app-shell-brand']", count: 0
    assert_select "#gallery-app-shell-minimal [data-slot='app-shell-topbar']", count: 0
    assert_select "#gallery-app-shell-hybrid [data-slot='app-navigation-item']", minimum: 8
    assert_select "#gallery-app-shell-long [data-slot='app-navigation-item-label']", text: /Cross-regional capacity/
    assert_select "#gallery-app-shell-sidebar [data-nk='page-header']" do
      assert_select "h4[data-slot='page-header-title']", text: "Workspace overview"
    end
    assert_select "#gallery-app-shell-sidebar [data-nk='grid'][data-cols='1 sm:2 lg:3']" do
      assert_select "> [data-nk='card']", count: 3
    end
    assert_select "#example-app-shell-sidebar-code [data-gallery='code-source']", text: /NitroKit::AppShell\.new/
    assert_select "[data-gallery='example-canvas'] [class]", count: 0
    assert_select "[data-gallery='example-canvas'] [style]", count: 0
  end

  test "focused pages render in both explicit themes" do
    %w[app-navigation app-shell].each do |slug|
      %w[light dark].each do |theme|
        get gallery_component_path(slug, theme:)

        assert_response :success
        assert_select "html[data-theme='#{theme}']"
        assert_select "[data-gallery-page='#{slug}']"
      end
    end
  end
end
