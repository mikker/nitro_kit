require "test_helper"

require "base64"
require "digest"

load File.expand_path("../../lib/tasks/nitro_kit_tasks.rake", __dir__) unless defined?(NitroKit::CssBundle)

class AppearanceTest < ActiveSupport::TestCase
  test "bootstrap renders a fixed pre-paint script with its default in data" do
    system = render_node(NitroKit::AppearanceBootstrap.new)
    dark = render_node(NitroKit::AppearanceBootstrap.new(default: :dark, nonce: "request-nonce"))

    assert_equal "script", system.name
    assert_equal "system", system["data-nk-appearance-default"]
    refute system.key?("nonce")
    assert_equal "dark", dark["data-nk-appearance-default"]
    assert_equal "request-nonce", dark["nonce"]
    assert_equal NitroKit::AppearanceBootstrap::SCRIPT, system.text
    assert_equal system.text, dark.text
  end

  test "bootstrap publishes the stable CSP hash for its exact script body" do
    digest = Base64.strict_encode64(Digest::SHA256.digest(NitroKit::AppearanceBootstrap::SCRIPT))
    integration_docs = NitroKit::Engine.root.join("docs/rails_integration.md").read

    assert_equal "sha256-#{digest}", NitroKit::AppearanceBootstrap::CSP_HASH
    assert_includes integration_docs, NitroKit::AppearanceBootstrap::CSP_HASH
  end

  test "bootstrap validates the closed default and optional nonce" do
    [ nil, "system", :automatic, 1 ].each do |default|
      assert_raises(ArgumentError) { NitroKit::AppearanceBootstrap.new(default:) }
    end

    [ "", "   ", :nonce, 1 ].each do |nonce|
      assert_raises(ArgumentError) { NitroKit::AppearanceBootstrap.new(nonce:) }
    end
  end

  test "picker renders one labelled native radio for each appearance preference" do
    node = render_node(NitroKit::AppearancePicker.new(id: "account-appearance"))
    controls = node.css("input[type='radio']")

    assert_equal "fieldset", node.name
    assert_equal "appearance-picker", node["data-nk"]
    assert_equal "account-appearance", node["id"]
    assert_equal I18n.t("nitro_kit.appearance_picker.label"), node.at_css("legend").text
    assert_equal %w[light dark system], controls.map { |control| control["value"] }
    assert_equal [ "account-appearance-preference" ], controls.map { |control| control["name"] }.uniq
    assert_equal [ "system" ], controls.select { |control| control.key?("checked") }.map { |control| control["value"] }

    controls.each do |control|
      label = node.at_css("label[for='#{control['id']}']")

      assert label
      assert_equal "appearance-picker-control", control["data-slot"]
      assert_equal "input", control["data-nk--appearance-target"]
    end

    assert_empty node.css("[class], [style], [data-nk-escape]")
  end

  test "picker exposes Nitro behavior while composing application attributes" do
    node = render_node(
      NitroKit::AppearancePicker.new(
        id: "workspace-appearance",
        label: "Color appearance",
        html: { title: "Choose an appearance" },
        aria: { describedby: "appearance-help" },
        data: {
          controller: "analytics",
          action: "focusin->analytics#track",
          tracking_id: "appearance"
        }
      )
    )

    assert_equal "Color appearance", node.at_css("[data-slot='appearance-picker-legend']").text
    assert_equal "Choose an appearance", node["title"]
    assert_equal "appearance-help", node["aria-describedby"]
    assert_equal "nk--appearance analytics", node["data-controller"]
    assert_equal "system", node["data-state"]
    assert_includes node["data-action"], "change->nk--appearance#select"
    assert_includes node["data-action"], "nitro-kit:appearance-change@window->nk--appearance#synchronize"
    assert_includes node["data-action"], "focusin->analytics#track"
    assert_equal "appearance", node["data-tracking-id"]
  end

  test "picker renders a server-persisted preference without a client flash" do
    segmented = render_node(NitroKit::AppearancePicker.new(id: "account", preference: :dark))
    select = render_node(
      NitroKit::AppearancePicker.new(id: "account-select", presentation: :select, preference: :light)
    )
    menu = render_node(
      NitroKit::AppearancePicker.new(id: "account-menu", presentation: :dropdown, preference: :dark)
    )

    assert_equal "dark", segmented["data-state"]
    assert_equal [ "dark" ], segmented.css("input[checked]").map { _1["value"] }
    assert_equal [ "light" ], select.css("option[selected]").map { _1["value"] }
    light_menu = render_node(
      NitroKit::AppearancePicker.new(id: "account-menu-light", presentation: :dropdown, preference: :light)
    )

    assert_equal "dark", menu["data-state"]
    refute_equal(
      light_menu.at_css("[data-slot='button-icon-start']").to_html,
      menu.at_css("[data-slot='button-icon-start']").to_html
    )
    assert_raises(ArgumentError) { NitroKit::AppearancePicker.new(id: "account", preference: :automatic) }
  end

  test "picker validates its required identity and label" do
    [ nil, "", "   ", "two words", "-leading", :appearance ].each do |id|
      assert_raises(ArgumentError) { NitroKit::AppearancePicker.new(id:) }
    end

    [ nil, "", "   ", :appearance ].each do |label|
      assert_raises(ArgumentError) { NitroKit::AppearancePicker.new(id: "appearance", label:) }
    end


    assert_raises(ArgumentError) do
      NitroKit::AppearancePicker.new(
        id: "appearance",
        presentation: :buttons
      )
    end
  end

  test "picker hides the label visually while keeping the group name" do
    node = render_node(
      NitroKit::AppearancePicker.new(id: "footer-appearance", label_visible: false)
    )

    assert_nil node.at_css("[data-slot='appearance-picker-legend']"),
      "browsers give legends special layout, so a hidden label renders none"
    assert_equal I18n.t("nitro_kit.appearance_picker.label"), node["aria-label"]

    visible = render_node(NitroKit::AppearancePicker.new(id: "visible-appearance"))
    assert_equal "legend", visible.at_css("[data-slot='appearance-picker-legend']").name
    refute visible.key?("aria-label")

    assert_raises(ArgumentError) do
      NitroKit::AppearancePicker.new(id: "appearance", label_visible: :no)
    end
    assert_raises(ArgumentError, match: /segmented/) do
      NitroKit::AppearancePicker.new(
        id: "appearance",
        label_visible: false,
        presentation: :select
      )
    end
  end

  test "picker renders radio and select presentations" do
    radios = render_node(
      NitroKit::AppearancePicker.new(
        id: "radios",
        presentation: :radios
      )
    )
    select = render_node(
      NitroKit::AppearancePicker.new(
        id: "select",
        presentation: :select
      )
    )

    assert_equal "radios", radios["data-presentation"]
    assert_equal "select", select["data-presentation"]
    assert_equal %w[light dark system], select.css("option").map { |option| option["value"] }
    assert_equal "input", select.at_css("select")["data-nk--appearance-target"]
  end

  test "picker renders an icon-only dropdown trigger and labelled preference buttons" do
    node = render_node(
      NitroKit::AppearancePicker.new(
        id: "navigation-appearance",
        presentation: :dropdown
      )
    )
    trigger = node.at_css("[data-nk='dropdown'] > [data-nk='button']")
    items = node.css("[data-slot='dropdown-item']")

    assert_equal "div", node.name
    assert_equal "dropdown", node["data-presentation"]
    assert_equal I18n.t("nitro_kit.appearance_picker.label"), trigger["aria-label"]
    assert_nil trigger.at_css("[data-slot='button-label']")
    assert trigger.at_css("[data-slot='button-icon-start'] [data-nk='icon']")
    assert_equal 3, items.css("[data-slot='dropdown-item-icon']").size
    assert_equal %w[Light Dark System], items.map { _1.text }
    assert_equal %w[light dark system], items.map { _1["data-appearance-preference"] }
    assert items.all? { _1.name == "button" }
    assert items.all? { _1["data-nk--appearance-target"] == "input" }
    assert items.all? { _1["data-action"].include?("click->nk--appearance#select") }
  end

  test "picker wires the dropdown trigger glyph for client-side preference changes" do
    node = render_node(
      NitroKit::AppearancePicker.new(id: "navigation-appearance", presentation: :dropdown)
    )
    trigger = node.at_css("[data-nk='dropdown'] > [data-nk='button']")
    items = node.css("[data-slot='dropdown-item']")

    assert_equal "trigger", trigger["data-nk--appearance-target"]
    assert trigger.at_css("[data-slot='button-icon-start'] [data-nk='icon']")
    assert items.all? { |item| item.at_css("[data-slot='dropdown-item-icon'] [data-nk='icon']") }

    source = NitroKit::Engine.root.join("app/javascript/controllers/nk/appearance_controller.js").read

    assert_includes source, '"trigger"'
    assert_includes source, "hasTriggerTarget"
    assert_includes source, "replaceChildren"
    refute_includes source, "<svg"
    refute_includes source, "innerHTML"
  end

  test "gallery covers every picker presentation" do
    page = NitroKit::Engine.root.join(
      "test/dummy/app/components/gallery/components/appearance_picker_page.rb"
    ).read

    NitroKit::AppearancePicker::PRESENTATIONS.each do |presentation|
      assert_includes page, "presentation: :#{presentation}" unless presentation == :segmented
    end
    assert_includes page, "AppearancePicker.new(id: \"gallery-appearance-default\")"
  end

  test "picker preserves the shared class and reserved attribute boundaries" do
    node = render_node(
      NitroKit::AppearancePicker.new(
        id: "appearance",
        desperately_need_a_class: "external-appearance-hook"
      )
    )

    assert_equal "external-appearance-hook", node["class"]
    assert_equal "class", node["data-nk-escape"]
    assert_raises(ArgumentError) { NitroKit::AppearancePicker.new(id: "appearance", html: { class: "utility" }) }
    assert_raises(ArgumentError) { NitroKit::AppearancePicker.new(id: "appearance", html: { style: "display:none" }) }
    assert_raises(ArgumentError) { NitroKit::AppearancePicker.new(id: "appearance", data: { state: "dark" }) }
  end

  test "picker ships owner-scoped static CSS" do
    source = NitroKit::Engine.root.join("src/stylesheets/nitro_kit/components/appearance_picker.css").read
    css = NitroKit::CssBundle.compile

    assert_includes css, "Source: src/stylesheets/nitro_kit/components/appearance_picker.css"
    assert_includes source, ':where([data-nk="appearance-picker"])'
    assert_includes source, '[data-slot="appearance-picker-control"]:focus-visible'
    refute_match(/(?:\:where\(\s*|,\s*)\[data-slot=/m, source)
    refute_includes source, "transition: all"
  end

  test "picker controller only requests and subscribes to document-owned appearance" do
    source = NitroKit::Engine.root.join("app/javascript/controllers/nk/appearance_controller.js").read

    assert_includes source, 'new CustomEvent("nitro-kit:appearance-request"'
    assert_includes source, "document.documentElement.dataset.themePreference"
    assert_includes source, "this.inputTargets.forEach"
    assert_includes source, "inputTargetConnected()"
    assert_includes source, "event.currentTarget"
    assert_includes source, "input.dataset.appearancePreference"
    assert_includes source, 'input.localName === "select"'
    refute_includes source, "localStorage"
    refute_includes source, "matchMedia"
    refute_includes source, "addEventListener"
  end

  test "picker component controller and CSS source are packaged" do
    files = Gem::Specification.load(NitroKit::Engine.root.join("nitro_kit.gemspec").to_s).files

    assert_includes files, "app/components/nitro_kit/appearance_bootstrap.rb"
    assert_includes files, "app/components/nitro_kit/appearance_picker.rb"
    assert_includes files, "src/stylesheets/nitro_kit/components/appearance_picker.css"
    assert_includes files, "app/javascript/controllers/nk/appearance_controller.js"
  end

  private

  def render_node(component)
    Nokogiri::HTML.fragment(component.call).first_element_child
  end
end
