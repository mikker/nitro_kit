require "test_helper"

class AppNavigationTest < ActiveSupport::TestCase
  test "renders canonical regions and ordered body entries from buffered declarations" do
    node = render_navigation do |navigation|
      navigation.footer { "Signed in" }
      navigation.body do
        navigation.item("Dashboard", href: "/dashboard", icon: :house, current: true)
        navigation.divider
        navigation.section(label: "Manage") do
          navigation.item("Projects", href: "/projects", badge: 12)
          navigation.item("Members", href: "/members")
        end
        navigation.spacer
        navigation.item("Help", href: "/help")
      end
      navigation.header { "Acme" }
    end

    assert_equal "nav", node.name
    assert_equal "app-navigation", node["data-nk"]
    assert_equal "Primary", node["aria-label"]
    assert_equal %w[app-navigation-header app-navigation-body app-navigation-footer],
      node.element_children.map { |child| child["data-slot"] }

    body = node.at_css("[data-slot='app-navigation-body']")
    assert_equal "ul", body.name
    assert_equal %w[app-navigation-item app-navigation-divider app-navigation-section app-navigation-spacer app-navigation-item],
      body.element_children.map { |child| child["data-slot"] }
    assert_equal %w[li li li li li], body.element_children.map(&:name)
    assert_equal "Manage", body.at_css("[data-slot='app-navigation-section-label']").text
    assert_equal 4, body.css("[data-slot='app-navigation-item']").size
    assert_empty node.css("[class], [style], [data-nk-escape]")
  end

  test "wraps every entry in list semantics and names each section list" do
    node = render_navigation do |navigation|
      navigation.body do
        navigation.item("Dashboard", href: "/dashboard", current: true)
        navigation.section(label: "Manage") do
          navigation.item("Projects", href: "/projects")
          navigation.divider
        end
      end
    end

    body = node.at_css("[data-slot='app-navigation-body']")
    section = body.at_css("[data-slot='app-navigation-section']")
    section_list = section.at_css("[data-slot='app-navigation-section-list']")
    label = section.at_css("[data-slot='app-navigation-section-label']")
    dashboard = body.at_css("[data-slot='app-navigation-item'] > [data-slot='app-navigation-item-link']")

    assert_equal "li", section.name
    assert_equal "span", label.name
    assert_equal "ul", section_list.name
    assert_equal "Manage", section_list["aria-label"]
    assert_equal %w[app-navigation-item app-navigation-divider],
      section_list.element_children.map { |child| child["data-slot"] }
    divider = section_list.at_css("[data-slot='app-navigation-divider']")
    assert_equal "true", divider["aria-hidden"]
    assert_nil divider["role"]
    assert_equal "a", dashboard.name
    assert_equal "page", dashboard["aria-current"]
    assert_nil dashboard["data-state"]
    assert_empty node.css("h1, h2, h3, h4, h5, h6")
    assert_equal "true", body.at_css("[data-slot='app-navigation-spacer']")["aria-hidden"] if body.at_css("[data-slot='app-navigation-spacer']")
  end

  test "items accept bounded native attributes and the explicit class escape" do
    node = render_navigation do |navigation|
      navigation.body do
        navigation.item(
          "Docs",
          href: "https://example.com/docs",
          html: { rel: "noopener", target: "_blank" },
          aria: { describedby: "docs-help" },
          data: { turbo_frame: "content" },
          desperately_need_a_class: "external-item"
        )
      end
    end

    link = node.at_css("[data-slot='app-navigation-item-link']")

    assert_equal "noopener", link["rel"]
    assert_equal "_blank", link["target"]
    assert_equal "docs-help", link["aria-describedby"]
    assert_equal "content", link["data-turbo-frame"]
    assert_equal "external-item", link["class"]
    assert_equal "class", link["data-nk-escape"]

    [
      ->(navigation) { navigation.item("One", href: "/one", html: { class: "utility" }) },
      ->(navigation) { navigation.item("One", href: "/one", data: { state: "current" }) },
      ->(navigation) { navigation.item("One", href: "/one", aria: { current: "page" }) }
    ].each do |declaration|
      assert_raises(ArgumentError) do
        render_navigation { |navigation| navigation.body { declaration.call(navigation) } }
      end
    end
  end

  test "items expose the badge color vocabulary" do
    node = render_navigation do |navigation|
      navigation.body do
        navigation.item("Incidents", href: "/incidents", badge: 3, badge_color: :destructive)
        navigation.item("Inbox", href: "/inbox", badge: "9")
      end
    end

    destructive, neutral = node.css("[data-slot='app-navigation-item-badge']")

    assert_equal "destructive", destructive["data-color"]
    assert_equal "neutral", neutral["data-color"]

    assert_match(/Unknown color/, assert_raises(ArgumentError) do
      render_navigation do |navigation|
        navigation.body { navigation.item("One", href: "/one", badge: "1", badge_color: :chartreuse) }
      end
    end.message)
    assert_match(/badge_color requires a badge/, assert_raises(ArgumentError) do
      render_navigation do |navigation|
        navigation.body { navigation.item("One", href: "/one", badge_color: :destructive) }
      end
    end.message)
  end

  test "renders concise icon and badge options as typed decorative components" do
    node = render_navigation do |navigation|
      navigation.body do
        navigation.item("Dashboard", href: "/dashboard", icon: "house", current: true)
        navigation.item("Inbox", href: "/inbox", badge: "9", icon_end: :arrow_up_right)
      end
    end

    current, inbox = node.css("[data-slot='app-navigation-item-link']")
    icon = current.at_css("[data-slot='app-navigation-item-icon']")
    badge = inbox.at_css("[data-slot='app-navigation-item-badge']")
    icon_end = inbox.at_css("[data-slot='app-navigation-item-icon-end']")

    assert_nil current["data-state"]
    assert_equal "page", current["aria-current"]
    assert_nil inbox["data-state"]
    assert_nil inbox["aria-current"]
    assert_equal "icon", icon["data-nk"]
    assert_equal "true", icon["aria-hidden"]
    assert_nil icon["aria-label"]
    assert_equal "badge", badge["data-nk"]
    assert_equal "sm", badge["data-size"]
    assert_equal "neutral", badge["data-color"]
    assert_equal "9", badge.text
    assert_equal "icon", icon_end["data-nk"]
    assert_equal "true", icon_end["aria-hidden"]
  end

  test "requires an explicit body with at least one item" do
    assert_match(/declaration block/, assert_raises(ArgumentError) do
      NitroKit::AppNavigation.new(label: "Primary").call
    end.message)
    assert_match(/exactly one body/, assert_raises(ArgumentError) do
      render_navigation { |navigation| navigation.header { "Acme" } }
    end.message)
    assert_match(/body requires a block/, assert_raises(ArgumentError) do
      render_navigation { |navigation| navigation.body }
    end.message)
    assert_match(/at least one item/, assert_raises(ArgumentError) do
      render_navigation { |navigation| navigation.body { navigation.divider } }
    end.message)
    assert_match(/section requires at least one item/, assert_raises(ArgumentError) do
      render_navigation do |navigation|
        navigation.body do
          navigation.item("Outside", href: "/outside")
          navigation.section { navigation.divider }
        end
      end
    end.message)
  end

  test "enforces unique regions spacer and current item" do
    assert_raises(ArgumentError) do
      render_navigation do |navigation|
        navigation.header { "One" }
        navigation.header { "Two" }
      end
    end
    assert_raises(ArgumentError) do
      render_navigation do |navigation|
        navigation.body { navigation.item("One", href: "/one") }
        navigation.body { navigation.item("Two", href: "/two") }
      end
    end
    assert_raises(ArgumentError) do
      render_navigation do |navigation|
        navigation.footer { "One" }
        navigation.footer { "Two" }
      end
    end
    assert_match(/at most one spacer/, assert_raises(ArgumentError) do
      render_navigation do |navigation|
        navigation.body do
          navigation.item("One", href: "/one")
          navigation.spacer
          navigation.spacer
        end
      end
    end.message)
    assert_match(/at most one current/, assert_raises(ArgumentError) do
      render_navigation do |navigation|
        navigation.body do
          navigation.item("One", href: "/one", current: true)
          navigation.section { navigation.item("Two", href: "/two", current: true) }
        end
      end
    end.message)
  end

  test "validates the closed item and section vocabulary" do
    [ nil, :primary, "", "  " ].each do |label|
      assert_raises(ArgumentError) { NitroKit::AppNavigation.new(label:) }
    end

    invalid_declarations = [
      ->(navigation) { navigation.item(nil, href: "/one") },
      ->(navigation) { navigation.item("One", href: nil) },
      ->(navigation) { navigation.item("One", href: " ") },
      ->(navigation) { navigation.item("One", href: "/one", icon: "") },
      ->(navigation) { navigation.item("One", href: "/one", icon: Object.new) },
      ->(navigation) { navigation.item("One", href: "/one", icon_end: "") },
      ->(navigation) { navigation.item("One", href: "/one", icon_end: Object.new) },
      ->(navigation) { navigation.item("One", href: "/one", badge: " ") },
      ->(navigation) { navigation.item("One", href: "/one", badge: Object.new) },
      ->(navigation) { navigation.item("One", href: "/one", badge: true) },
      ->(navigation) { navigation.item("One", href: "/one", current: :yes) },
      ->(navigation) { navigation.section(label: :manage) { navigation.item("One", href: "/one") } }
    ]

    invalid_declarations.each do |declaration|
      assert_raises(ArgumentError) do
        render_navigation do |navigation|
          navigation.body do
            declaration.call(navigation)
            navigation.item("Fallback", href: "/fallback")
          end
        end
      end
    end

    later_declarations = []
    assert_match(/Unknown icon/, assert_raises(ArgumentError) do
      render_navigation do |navigation|
        navigation.body do
          navigation.item("One", href: "/one", icon: :definitely_not_an_icon)
          later_declarations << :unreachable
        end
      end
    end.message)
    assert_empty later_declarations
  end

  test "rejects declarations in the wrong phase and arbitrary declaration output" do
    navigation = NitroKit::AppNavigation.new(label: "Primary")
    assert_match(/inside the body/, assert_raises(ArgumentError) do
      navigation.item("One", href: "/one")
    end.message)
    assert_match(/directly inside the body/, assert_raises(ArgumentError) { navigation.section { } }.message)
    assert_match(/directly inside the body/, assert_raises(ArgumentError) { navigation.spacer }.message)

    assert_match(/directly inside the render block/, assert_raises(ArgumentError) do
      render_navigation do |component|
        component.body do
          component.header { "Nested" }
          component.item("One", href: "/one")
        end
      end
    end.message)
    assert_match(/structure accepts declarations/, assert_raises(ArgumentError) do
      render_navigation do |component|
        component.body { component.item("One", href: "/one") }
        "Unexpected"
      end
    end.message)
    assert_match(/body accepts declarations/, assert_raises(ArgumentError) do
      render_navigation do |component|
        component.body do
          component.item("One", href: "/one")
          "Unexpected"
        end
      end
    end.message)
    assert_match(/section accepts declarations/, assert_raises(ArgumentError) do
      render_navigation do |component|
        component.body do
          component.section do
            component.item("One", href: "/one")
            "Unexpected"
          end
        end
      end
    end.message)
  end

  test "preserves bounded root attributes and the explicit class escape" do
    node = render_navigation(
      NitroKit::AppNavigation.new(
        label: "Primary",
        id: "primary-navigation",
        html: { title: "Workspace navigation" },
        aria: { describedby: "navigation-help" },
        data: { tracking_id: "primary" },
        desperately_need_a_class: "external-navigation"
      )
    ) do |navigation|
      navigation.body { navigation.item("Home", href: "/") }
    end

    assert_equal "primary-navigation", node["id"]
    assert_equal "Workspace navigation", node["title"]
    assert_equal "navigation-help", node["aria-describedby"]
    assert_equal "primary", node["data-tracking-id"]
    assert_equal "external-navigation", node["class"]
    assert_equal "class", node["data-nk-escape"]

    assert_raises(ArgumentError) do
      NitroKit::AppNavigation.new(label: "Primary", html: { class: "utility" })
    end
    assert_raises(ArgumentError) do
      NitroKit::AppNavigation.new(label: "Primary", data: { nk: "replacement" })
    end
    assert_raises(ArgumentError) do
      NitroKit::AppNavigation.new(label: "Primary", aria: { label: "Replacement" })
    end
  end

  private

  def render_navigation(component = NitroKit::AppNavigation.new(label: "Primary"), &block)
    Nokogiri::HTML.fragment(component.call(&block)).first_element_child
  end
end
