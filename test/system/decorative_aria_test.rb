require "application_system_test_case"

class DecorativeAriaTest < ApplicationSystemTestCase
  test "decorative form atoms and pagination copy stay out of accessible names" do
    visit gallery_component_path("checkbox")
    assert_equal "Security notices", find("#gallery-checkbox-checked-control", visible: :all).native.accessible_name
    assert_selector "#gallery-checkbox-checked [data-slot='checkbox-indicator'][aria-hidden='true']"

    visit gallery_component_path("radio-button")
    assert_equal "Private to invited members", find("#gallery-radio-button-private-control", visible: :all).native.accessible_name
    assert_selector "#gallery-radio-button-private [data-slot='radio-button-indicator'][aria-hidden='true']"

    visit gallery_component_path("switch")
    assert_equal "Use compact table rows", find("#gallery-switch-aria-control", visible: :all).native.accessible_name
    assert_selector "#gallery-switch-aria [data-slot='switch-track'][aria-hidden='true']"

    visit gallery_component_path("pagination")
    assert_equal "Long audit log pages", find("#gallery-pagination-long").native.accessible_name
    find("#gallery-pagination-long [data-slot='pagination-ellipsis']", match: :first).tap do |ellipsis|
      assert_equal "true", ellipsis["aria-hidden"]
      assert_equal "", ellipsis.native.accessible_name
    end
  end

  test "customizer font radios are named only by their option" do
    visit gallery_customize_path

    Gallery::ThemePreset::CHOICES.fetch(:font).each do |font|
      assert_equal font.to_s.humanize, find("#customizer-font-#{font}", visible: :all).native.accessible_name
    end
  end
end
