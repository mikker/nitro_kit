require "test_helper"

class AppNavigationCssTest < ActiveSupport::TestCase
  DIVIDER = ':where([data-nk="app-navigation"] [data-slot="app-navigation-divider"])'
  ITEM_LINK = ':where([data-nk="app-navigation"] [data-slot="app-navigation-item-link"])'
  ITEM_LABEL = ':where([data-nk="app-navigation"] [data-slot="app-navigation-item-label"])'

  test "the body inset is a single private variable both the padding and the divider read" do
    assert_match(/--_nk-app-navigation-inset: calc\(var\(--nk-space\) \* 3\);/, source_css)
    assert_match(
      /#{Regexp.escape(':where([data-nk="app-navigation"] > [data-slot="app-navigation-body"])')}\s*\{[^}]*padding: var\(--_nk-app-navigation-inset\);/m,
      source_css
    )
  end

  test "a divider bleeds to both navigation edges" do
    assert_match(
      /#{Regexp.escape(DIVIDER)}\s*\{[^}]*margin-inline: calc\(var\(--_nk-app-navigation-inset\) \* -1\);/m,
      source_css
    )
  end

  test "an item link flexes so labels truncate whether or not an icon or badge is present" do
    assert_match(/#{Regexp.escape(ITEM_LINK)}\s*\{\s*display: flex;/, source_css)
    refute_match(/#{Regexp.escape(ITEM_LINK)}\s*\{[^}]*grid-template-columns/m, source_css)

    label = source_css[/#{Regexp.escape(ITEM_LABEL)}\s*\{([^}]*)\}/m, 1]

    assert_match(/flex: 1 1 auto;/, label)
    assert_match(/min-inline-size: 0;/, label)
    assert_match(/overflow: hidden;/, label)
    assert_match(/text-overflow: ellipsis;/, label)
    assert_match(/white-space: nowrap;/, label)
  end

  private

  def source_css
    @source_css ||= Rails.root.join(
      "../../src/stylesheets/nitro_kit/components/app_navigation.css"
    ).read
  end
end
