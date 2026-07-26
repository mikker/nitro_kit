require "test_helper"

class DropdownComponentTest < ActiveSupport::TestCase
  test "renders a native popover menu with deterministic relationships and typed entries" do
    node = render_dropdown do |dropdown|
      dropdown.trigger("Actions", data: { action: "click->analytics#track" })
      dropdown.title("Account")
      dropdown.item("Edit", href: "/edit")
      dropdown.item("Archive", variant: :destructive)
      dropdown.separator
      dropdown.item("Unavailable", disabled: true)
    end

    trigger = node.at_css("[data-slot='dropdown-trigger']")
    content = node.at_css("[data-slot='dropdown-content']")
    items = node.css("[data-slot='dropdown-item']")

    assert_equal "account-menu", node["id"]
    assert_equal "dropdown", node["data-nk"]
    assert_nil node["data-state"]
    assert_equal "bottom-start", node["data-placement"]
    assert_equal "nk--dropdown", node["data-controller"]

    assert_equal "account-menu-trigger", trigger["id"]
    assert_equal "account-menu-content", trigger["popovertarget"]
    assert_nil trigger["aria-controls"]
    assert_nil trigger["aria-expanded"]
    assert_equal "menu", trigger["aria-haspopup"]
    assert_includes trigger["data-action"], "keydown->nk--dropdown#openFromKeyboard"
    assert_includes trigger["data-action"], "click->analytics#track"

    assert_equal "account-menu-content", content["id"]
    assert_equal "menu", content["role"]
    assert_equal "auto", content["popover"]
    assert_equal "account-menu-trigger", content["aria-labelledby"]
    assert_equal "bottom-start", content["data-placement"]
    assert_includes content["data-action"], "toggle->nk--dropdown#focusOpened"
    title = content.at_css("[data-slot='dropdown-title']")
    assert_equal "Account", title.text
    assert_equal "presentation", title["role"]
    assert_equal "true", title["aria-hidden"]

    assert_equal "a", items[0].name
    assert_equal "/edit", items[0]["href"]
    assert_equal "button", items[1].name
    assert_equal "destructive", items[1]["data-variant"]
    assert items[2].key?("disabled")
    assert items.all? { |item| item["tabindex"] == "-1" }
    assert_equal 1, content.css("[data-slot='dropdown-separator']").size
    assert_empty node.css("[class], [style]")
  end

  test "supports all closed placements and preserves root attribute boundaries" do
    NitroKit::Dropdown::PLACEMENTS.each do |placement|
      node = render_dropdown(
        NitroKit::Dropdown.new(
          id: "menu-#{placement}",
          placement:,
          html: { title: "Menu" },
          aria: { label: "Account actions" },
          data: { controller: "application", tracking_id: "account" }
        )
      ) do |dropdown|
        dropdown.trigger("Open")
        dropdown.item("Profile", href: "/profile")
      end

      assert_equal placement.to_s.tr("_", "-"), node["data-placement"]
      assert_equal "Menu", node["title"]
      assert_equal "Account actions", node["aria-label"]
      assert_equal "nk--dropdown application", node["data-controller"]
      assert_equal "account", node["data-tracking-id"]
    end
  end

  test "generates an identity when none is supplied" do
    node = render_dropdown(NitroKit::Dropdown.new) do |menu|
      menu.trigger("Open")
      menu.item("Profile", href: "/profile")
    end

    assert_match(/\Ank-dropdown-[0-9a-f]{8}\z/, node["id"])
    assert_equal "#{node["id"]}-trigger", node.at_css("[data-slot='dropdown-trigger']")["id"]
    assert_equal "#{node["id"]}-content", node.at_css("[data-slot='dropdown-content']")["id"]
  end

  test "validates identity placement and required declarations" do
    [ "", "two words", "-leading", :menu ].each do |id|
      assert_match(/id must be/, assert_raises(ArgumentError) { NitroKit::Dropdown.new(id:) }.message)
    end

    assert_match(
      /Unknown placement/,
      assert_raises(ArgumentError) { NitroKit::Dropdown.new(id: "menu", placement: :center) }.message
    )
    assert_match(/declaration block/, assert_raises(ArgumentError) { NitroKit::Dropdown.new(id: "menu").call }.message)
    assert_match(/requires one trigger/, assert_raises(ArgumentError) do
      NitroKit::Dropdown.new(id: "menu").call { |dropdown| dropdown.item("One") }
    end.message)
    assert_match(/at least one item/, assert_raises(ArgumentError) do
      NitroKit::Dropdown.new(id: "menu").call { |dropdown| dropdown.trigger("Open") }
    end.message)
  end

  test "validates entry vocabulary and collection context" do
    dropdown = NitroKit::Dropdown.new(id: "menu")
    assert_match(/inside the render block/, assert_raises(ArgumentError) { dropdown.item("One") }.message)

    assert_raises(ArgumentError) do
      render_dropdown do |menu|
        menu.trigger("One")
        menu.trigger("Two")
        menu.item("Item")
      end
    end

    [
      ->(menu) { menu.item },
      ->(menu) { menu.item("One", variant: :loud) },
      ->(menu) { menu.item("One", type: :get) },
      ->(menu) { menu.item("One", type: nil) },
      ->(menu) { menu.item("One", disabled: :yes) },
      ->(menu) { menu.item("One", href: :edit) }
    ].each do |invalid_declaration|
      assert_raises(ArgumentError) do
        render_dropdown do |menu|
          menu.trigger("Open")
          invalid_declaration.call(menu)
        end
      end
    end
  end

  test "rejects classes and reserved state while keeping the class escape visible" do
    assert_raises(ArgumentError) { NitroKit::Dropdown.new(id: "menu", html: { class: "utility" }) }
    assert_raises(ArgumentError) { NitroKit::Dropdown.new(id: "menu", data: { state: "open" }) }
    assert_raises(ArgumentError) do
      render_dropdown do |menu|
        menu.trigger("Open")
        menu.item("Item", data: { variant: "destructive" })
      end
    end

    node = render_dropdown(NitroKit::Dropdown.new(id: "menu", desperately_need_a_class: "hook")) do |menu|
      menu.trigger("Open")
      menu.item("Item")
    end
    assert_equal "hook", node["class"]
    assert_equal "class", node["data-nk-escape"]

    assert_raises(ArgumentError) do
      render_dropdown do |menu|
        menu.trigger("Open")
        menu.title("Heading", aria: { hidden: false })
        menu.item("Item")
      end
    end
  end

  test "renders an icon-only trigger with square Button geometry and icon items" do
    node = render_dropdown(NitroKit::Dropdown.new(id: "record-menu")) do |menu|
      menu.trigger(icon: :ellipsis, label: "Record actions", variant: :ghost)
      menu.item("Rename", icon: :pencil)
      menu.item("Delete", icon: :trash_2, variant: :destructive)
    end
    trigger = node.at_css("[data-slot='dropdown-trigger']")
    items = node.css("[data-slot='dropdown-item']")

    assert_equal "Record actions", trigger["aria-label"]
    assert_equal "ghost", trigger["data-variant"]
    assert_nil trigger.at_css("[data-slot='button-label']")
    assert_equal "md", trigger.at_css("[data-slot='button-icon-start'] [data-nk='icon']")["data-size"]
    assert_equal %w[sm sm], items.map { |item| item.at_css("[data-slot='dropdown-item-icon'] [data-nk='icon']")["data-size"] }
    assert_equal %w[Rename Delete], items.map(&:text)
    assert_equal "destructive", items[1]["data-variant"]
  end

  test "supports a trailing trigger icon and validates trigger treatment against Button" do
    node = render_dropdown(NitroKit::Dropdown.new(id: "sort-menu")) do |menu|
      menu.trigger("Sort", icon_end: :chevron_down, size: :sm)
      menu.item("Newest")
    end
    trigger = node.at_css("[data-slot='dropdown-trigger']")

    assert_equal "sm", trigger["data-size"]
    assert trigger.at_css("[data-slot='button-icon-end'] [data-nk='icon']")

    [ [ :variant, :loud ], [ :size, :huge ] ].each do |option, value|
      error = assert_raises(ArgumentError) do
        render_dropdown(NitroKit::Dropdown.new(id: "menu")) do |menu|
          menu.trigger("Open", option => value)
          menu.item("One")
        end
      end

      assert_match(/Unknown Dropdown trigger #{option}/, error.message)
    end
  end

  test "restores focus to the trigger whenever the popover closes with focus inside" do
    source = NitroKit::Engine.root.join("app/javascript/controllers/nk/dropdown_controller.js").read
    node = render_dropdown do |menu|
      menu.trigger("Open")
      menu.item("One")
    end

    assert_includes node.at_css("[data-slot='dropdown-content']")["data-action"],
      "beforetoggle->nk--dropdown#rememberFocus"
    assert_includes source, "rememberFocus(event)"
    assert_includes source, "this.contentTarget.contains(document.activeElement)"
    assert_includes source, "restoreFocus()"
    assert_includes source, "this.hide({ restoreFocus: false })"
  end

  test "positions the popover from controller-owned coordinates" do
    source = NitroKit::Engine.root.join("src/stylesheets/nitro_kit/components/dropdown.css").read

    assert_includes source, "--_nk-overlay-top"
    assert_includes source, "--_nk-overlay-left"
    assert_includes source, "translate: none"
    refute_includes source, "anchor("
    assert_includes source, ":popover-open"
    assert_includes source, '> [data-slot="dropdown-item-icon"]'
    assert_includes source, '[data-slot="dropdown-item"][data-variant="destructive"]'
    refute_includes source, "[data-state=\"open\"]"
  end

  private

  def render_dropdown(component = NitroKit::Dropdown.new(id: "account-menu"), &block)
    Nokogiri::HTML.fragment(component.call(&block)).first_element_child
  end
end
