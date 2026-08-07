require "test_helper"

load File.expand_path("../../lib/tasks/nitro_kit_tasks.rake", __dir__) unless defined?(NitroKit::CssBundle)

class AppShellCssTest < ActiveSupport::TestCase
  SHELL = NitroKit::Engine.root.join("src/stylesheets/nitro_kit/components/app_shell.css")
  NAVIGATION = NitroKit::Engine.root.join("src/stylesheets/nitro_kit/components/app_navigation.css")
  TOOLBAR = NitroKit::Engine.root.join("src/stylesheets/nitro_kit/components/toolbar.css")
  CONTROLLER = NitroKit::Engine.root.join("app/javascript/controllers/nk/app_shell_controller.js")

  test "owns semantic shell tokens and layout-specific placement" do
    tokens = NitroKit::Engine.root.join("src/stylesheets/nitro_kit/tokens.css").read
    shell = SHELL.read

    %w[
      sidebar-width topbar-height background sidebar-background sidebar-foreground
      sidebar-accent sidebar-accent-foreground border
    ].each do |token|
      assert_includes tokens, "--nk-app-shell-#{token}:"
    end
    %w[sidebar topbar].each do |layout|
      assert_includes shell, %(data-layout="#{layout}")
    end
    refute_includes shell, "data-variant"
    assert_includes shell, "min-block-size: 100dvh"
    assert_includes shell, "display: contents"
    assert_includes shell, '> [data-slot="app-shell-header"] > [data-slot="app-shell-brand"]'
    assert_includes shell, "grid-row: 1 / 3"
  end

  test "uses one fixed breakpoint and gates the native drawer on enhancement" do
    shell = SHELL.read
    controller = CONTROLLER.read

    assert_includes shell, "@media (width < 48rem)"
    assert_includes controller, 'const narrowViewport = "(width < 48rem)"'
    assert_includes shell, '[data-nk="app-shell"][data-enhanced]'
    assert_includes shell, '> [data-slot="app-shell-dialog"][open]'
    assert_includes shell, '[data-slot="app-shell-dialog"])::backdrop'
    assert_includes shell, "animation: nk-app-shell-dialog-enter"
    refute_includes shell, '[data-slot="app-shell-backdrop"]'

    unenhanced_mobile = shell.match(/@media \(width < 48rem\)(?<body>.*)@media \(prefers-reduced-motion/m)[:body]
    assert_includes unenhanced_mobile, '[data-nk="app-shell"] > [data-slot="app-shell-sidebar"]'
    assert_includes unenhanced_mobile, "position: static"
    assert_includes unenhanced_mobile, "display: none"
  end

  test "lets a toolbar own the full topbar and stack its narrow regions" do
    shell = SHELL.read
    toolbar = TOOLBAR.read

    assert_includes shell, '[data-slot="app-shell-topbar"]:has(> [data-nk="toolbar"])'
    assert_includes shell, "> [data-nk=\"toolbar\"]"
    assert_includes toolbar, "@media (width < 48rem)"
    assert_includes toolbar, "flex-direction: column"
    assert_includes toolbar, "align-items: stretch"
    refute_includes toolbar, '> [data-slot="app-shell-header"]'
  end

  test "styles the complete navigation anatomy without utility classes" do
    navigation = NAVIGATION.read

    %w[header body footer section section-label item item-icon item-label item-badge divider spacer].each do |slot|
      assert_includes navigation, %(app-navigation-#{slot})
    end
    assert_includes navigation, "[aria-current]"
    assert_includes navigation, "min-block-size: var(--nk-app-shell-topbar-height)"
    assert_includes navigation, "padding-inline: calc(var(--nk-space) * 6)"
    assert_includes navigation, "font-variant-numeric: tabular-nums"
    assert_includes navigation, ":focus-visible"
    assert_includes SHELL.read, "scale: 0.96"
    refute_includes navigation, "transition: all"
    refute_includes SHELL.read, "transition: all"
  end

  test "packages the Ruby CSS and controller sources" do
    files = Gem::Specification.load(NitroKit::Engine.root.join("nitro_kit.gemspec").to_s).files

    %w[
      app/components/nitro_kit/app_navigation.rb
      app/components/nitro_kit/app_shell.rb
      app/javascript/controllers/nk/app_shell_controller.js
      src/stylesheets/nitro_kit/components/app_navigation.css
      src/stylesheets/nitro_kit/components/app_shell.css
    ].each { |path| assert_includes files, path }
  end
end
