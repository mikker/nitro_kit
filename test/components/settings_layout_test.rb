require "test_helper"

class SettingsLayoutTest < ActiveSupport::TestCase
  test "navigation items render an optional leading icon before their label" do
    node = settings_layout do |layout|
      layout.navigation(label: "Account settings") do
        layout.item("Profile", href: "/settings/profile", icon: :user_round, current: true)
        layout.item("Security", href: "/settings/security")
      end
      layout.content { "Content" }
    end

    profile, security = node.css("[data-slot='settings-layout-item-link']")
    icon = profile.at_css("[data-slot='settings-layout-item-icon']")

    assert_equal "svg", icon.name
    assert_equal "icon", icon["data-nk"]
    assert_equal "sm", icon["data-size"]
    assert_equal "true", icon["aria-hidden"]
    assert_equal "Profile", profile.text.strip
    assert_equal icon, profile.element_children.first
    assert_nil security.at_css("[data-slot='settings-layout-item-icon']")
  end

  test "the item icon vocabulary rejects blank and unknown names" do
    [ "", "  ", 1, :not_a_real_lucide_icon ].each do |icon|
      assert_raises(ArgumentError) do
        settings_layout do |layout|
          layout.navigation(label: "Settings") { layout.item("Profile", href: "/profile", icon:) }
          layout.content { "Content" }
        end
      end
    end
  end

  private

  def settings_layout(&block)
    Nokogiri::HTML.fragment(NitroKit::SettingsLayout.new.call(&block)).first_element_child
  end
end
