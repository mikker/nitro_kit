require "test_helper"

class CommandPaletteTest < ActiveSupport::TestCase
  test "renders a native dialog of destination links with an enhanced search" do
    node = render_palette
    trigger = node.at_css("[data-slot='command-palette-trigger']")
    panel = node.at_css("[data-slot='command-palette-panel']")
    search = node.at_css("[data-slot='command-palette-search']")
    input = node.at_css("[data-slot='command-palette-input']")
    frame = node.at_css("[data-nk='command-palette-results']")
    destinations = node.css("[data-slot='command-palette-destination']")

    assert_equal "workspace-search", node["id"]
    assert_equal "command-palette", node["data-nk"]
    assert_equal "nk--dialog nk--command-palette", node["data-controller"]
    assert_includes node["data-action"], "keydown@document->nk--command-palette#shortcut"
    assert_includes node["data-action"], "turbo:before-cache@document->nk--command-palette#closeForVisit"
    assert_includes node["data-action"], "click->nk--dialog#invoke"
    assert_includes node["data-action"], "turbo:before-cache@document->nk--dialog#closeForCache"
    assert_equal I18n.t("nitro_kit.command_palette.empty"),
      node["data-nk--command-palette-empty-value"]
    assert_equal I18n.t("nitro_kit.command_palette.results.one"),
      node["data-nk--command-palette-results-one-value"]
    assert_equal I18n.t("nitro_kit.command_palette.results.other"),
      node["data-nk--command-palette-results-other-value"]

    assert_equal "button", trigger.name
    assert_equal "button", trigger["data-nk"]
    assert_equal "show-modal", trigger["command"]
    assert_equal "workspace-search-panel", trigger["commandfor"]
    assert_equal "show-modal", trigger["data-nk--dialog-command"]
    assert_equal "dialog", trigger["aria-haspopup"]
    assert_equal "Meta+K Control+K", trigger["aria-keyshortcuts"]
    assert_equal "Search workspace", trigger.at_css("[data-slot='command-palette-trigger-label']").text
    assert_equal I18n.t("nitro_kit.command_palette.shortcut"),
      trigger.at_css("[data-slot='command-palette-shortcut']").text

    assert_equal "dialog", panel.name
    assert_equal "workspace-search-panel", panel["id"]
    assert_equal "any", panel["closedby"]
    assert_equal "close", node.at_css("[data-slot='command-palette-close']")["data-nk--dialog-command"]
    assert_equal "workspace-search-title", panel["aria-labelledby"]
    assert_equal "Search workspace", panel.at_css("[data-slot='command-palette-title']").text
    assert search.key?("hidden")
    assert_equal "search", input["type"]
    assert_equal "Search destinations", input["placeholder"]
    assert_equal "Search workspace", input["aria-label"]
    assert_equal "workspace-search-results", input["aria-controls"]
    assert_equal "turbo-frame", frame.name
    assert_equal "workspace-search-results-frame", frame["id"]
    assert_equal "_top", frame["target"]
    assert_equal "command-palette-results", frame["data-nk"]

    assert_equal [ "/dashboard", "/projects" ], destinations.map { _1["href"] }
    assert_equal [ "Dashboard", "Projects" ],
      destinations.map { _1.at_css("[data-slot='command-palette-destination-label']").text }
    assert_equal "Workspace overview",
      destinations.first.at_css("[data-slot='command-palette-destination-description']").text
    assert_nil destinations.last.at_css("[data-slot='command-palette-destination-description']")
    assert_equal "nav", panel.at_css("[data-slot='command-palette-results']").name
    assert_equal "status", panel.at_css("[data-slot='command-palette-status']")["role"]
    assert_equal I18n.t("nitro_kit.command_palette.empty"),
      panel.at_css("[data-slot='command-palette-empty']").text
    assert_empty node.css("[class], [style]")
  end

  test "keeps native links and the full destination list usable without JavaScript" do
    node = render_palette

    assert node.at_css("[data-slot='command-palette-search']").key?("hidden")
    assert node.css("[data-slot='command-palette-destination']").none? { _1.key?("hidden") }
    assert node.css("[data-slot='command-palette-destination']").all? { _1.name == "a" }
    assert_equal "close", node.at_css("[data-slot='command-palette-close']")["command"]
  end

  test "can omit the global shortcut without weakening the native trigger" do
    node = render_palette(shortcut: false)

    refute_includes node["data-action"], "keydown@document"
    assert_nil node.at_css("[data-slot='command-palette-shortcut']")
    assert_nil node.at_css("[data-slot='command-palette-trigger']")["aria-keyshortcuts"]
    assert_equal "show-modal", node.at_css("[data-slot='command-palette-trigger']")["command"]
  end

  test "submits remote searches into the results frame" do
    node = render_palette(search_url: "/destinations/search")
    search = node.at_css("[data-slot='command-palette-search']")
    input = node.at_css("[data-slot='command-palette-input']")
    frame = node.at_css("[data-nk='command-palette-results']")

    assert_equal "form", search.name
    assert_equal "/destinations/search", search["action"]
    assert_equal "get", search["method"]
    assert_equal "workspace-search-results-frame", search["data-turbo-frame"]
    assert_includes search["data-nk--command-palette-target"], "form"
    assert_equal "query", input["name"]
    assert_includes input["data-action"], "input->nk--command-palette#search"
    assert_includes frame["data-action"], "turbo:before-fetch-request->nk--command-palette#loading"
    assert_includes frame["data-action"], "turbo:frame-load->nk--command-palette#loaded"
  end

  test "renders standalone Turbo Frame results including an empty response" do
    results = NitroKit::CommandPalette::Results.new(
      id: "workspace-search",
      html: { title: "Filtered destinations" },
      data: { tracking_id: "results" },
      desperately_need_a_class: "external-results"
    )
    node = Nokogiri::HTML.fragment(results.call do |list|
      list.destination(
        "Dashboard",
        href: "/dashboard",
        description: "Workspace overview",
        data: { tracking_id: "dashboard" }
      )
    end).first_element_child

    assert_equal "turbo-frame", node.name
    assert_equal "workspace-search-results-frame", node["id"]
    assert_equal "_top", node["target"]
    assert_equal "Filtered destinations", node["title"]
    assert_equal "results", node["data-tracking-id"]
    assert_equal "external-results", node["class"]
    assert_equal "Dashboard", node.at_css("[data-slot='command-palette-destination-label']").text
    assert_equal "dashboard", node.at_css("[data-slot='command-palette-destination']")["data-tracking-id"]

    empty = Nokogiri::HTML.fragment(
      NitroKit::CommandPalette::Results.new(id: "workspace-search").call
    ).first_element_child
    assert_empty empty.css("[data-slot='command-palette-destination']")
  end

  test "forwards explicit root and destination attribute boundaries" do
    node = render_palette(
      html: { title: "Quick search" },
      aria: { label: "Command search" },
      data: { controller: "application", tracking_id: "commands" },
      desperately_need_a_class: "external-palette"
    ) do |palette|
      palette.destination(
        "Dashboard",
        href: "/dashboard",
        html: { target: "_top" },
        aria: { label: "Open dashboard" },
        data: { tracking_id: "dashboard" },
        desperately_need_a_class: "external-destination"
      )
    end
    destination = node.at_css("[data-slot='command-palette-destination']")

    assert_equal "Quick search", node["title"]
    assert_equal "Command search", node["aria-label"]
    assert_equal "nk--dialog nk--command-palette application", node["data-controller"]
    assert_equal "commands", node["data-tracking-id"]
    assert_equal "external-palette", node["class"]
    assert_equal "class", node["data-nk-escape"]
    assert_equal "_top", destination["target"]
    assert_equal "Open dashboard", destination["aria-label"]
    assert_equal "dashboard", destination["data-tracking-id"]
    assert_equal "external-destination", destination["class"]
    assert_equal "class", destination["data-nk-escape"]
  end

  test "validates identity copy shortcut and destination declarations" do
    assert_raises(ArgumentError) { NitroKit::CommandPalette.new }
    [ nil, "", "two words", :search ].each do |id|
      assert_raises(ArgumentError) { render_palette(id:) }
    end
    %i[label placeholder empty_text close_label shortcut_label].each do |keyword|
      assert_raises(ArgumentError) { render_palette(**{ keyword => " " }) }
    end
    assert_raises(ArgumentError) { render_palette(shortcut: :yes) }
    assert_raises(ArgumentError) { render_palette(search_url: " ") }
    assert_raises(ArgumentError) { render_palette(html: { class: "utility" }) }
    assert_raises(ArgumentError) { render_palette(data: { state: "open" }) }
    assert_raises(ArgumentError) { render_palette { nil } }
    assert_raises(ArgumentError) { render_palette { _1.destination(" ", href: "/") } }
    assert_raises(ArgumentError) { render_palette { _1.destination("Home", href: " ") } }
    assert_raises(ArgumentError) do
      render_palette { _1.destination("Home", href: "/", description: " ") }
    end

    component = NitroKit::CommandPalette.new(id: "outside")
    assert_raises(ArgumentError) { component.destination("Home", href: "/") }
    assert_raises(ArgumentError) { NitroKit::CommandPalette::Results.new(id: "two words") }
    assert_raises(ArgumentError) do
      NitroKit::CommandPalette::Results.new(id: "outside").destination("Home", href: "/")
    end
  end

  private

  def render_palette(
    id: "workspace-search",
    label: "Search workspace",
    placeholder: "Search destinations",
    **attributes,
    &block
  )
    component = NitroKit::CommandPalette.new(id:, label:, placeholder:, **attributes)
    content = block || proc do |palette|
      palette.destination("Dashboard", href: "/dashboard", description: "Workspace overview")
      palette.destination("Projects", href: "/projects")
    end

    Nokogiri::HTML.fragment(component.call(&content)).first_element_child
  end
end
