require "test_helper"

class AppNavigationCssTest < ActiveSupport::TestCase
  DIVIDER = ':where([data-nk="app-navigation"] [data-slot="app-navigation-divider"])'
  ITEM_LINK = ':where([data-nk="app-navigation"] [data-slot="app-navigation-item-link"])'
  ITEM_LABEL = ':where([data-nk="app-navigation"] [data-slot="app-navigation-item-label"])'

  test "the body inset is a single private variable both the padding and the divider read" do
    each_stylesheet do |css|
      assert_match(/--_nk-app-navigation-inset: calc\(var\(--nk-space\) \* 3\);/, css)
      assert_match(
        /#{Regexp.escape(':where([data-nk="app-navigation"] > [data-slot="app-navigation-body"])')}\s*\{[^}]*padding: var\(--_nk-app-navigation-inset\);/m,
        css
      )
    end
  end

  test "a divider bleeds to both navigation edges" do
    each_stylesheet do |css|
      assert_match(
        /#{Regexp.escape(DIVIDER)}\s*\{[^}]*margin-inline: calc\(var\(--_nk-app-navigation-inset\) \* -1\);/m,
        css
      )
    end
  end

  test "an item link flexes so labels truncate whether or not an icon or badge is present" do
    each_stylesheet do |css|
      assert_match(/#{Regexp.escape(ITEM_LINK)}\s*\{\s*display: flex;/, css)
      refute_match(/#{Regexp.escape(ITEM_LINK)}\s*\{[^}]*grid-template-columns/m, css)

      label = css[/#{Regexp.escape(ITEM_LABEL)}\s*\{([^}]*)\}/m, 1]

      assert_match(/flex: 1 1 auto;/, label)
      assert_match(/min-inline-size: 0;/, label)
      assert_match(/overflow: hidden;/, label)
      assert_match(/text-overflow: ellipsis;/, label)
      assert_match(/white-space: nowrap;/, label)
    end
  end

  private

  def each_stylesheet
    [ source_css, bundle_css ].each { |css| yield css }
  end

  def source_css
    @source_css ||= Rails.root.join(
      "../../src/stylesheets/nitro_kit/components/app_navigation.css"
    ).read
  end

  def bundle_css
    @bundle_css ||= Rails.root.join(
      "../../app/assets/stylesheets/nitro_kit.css"
    ).read
  end
end
