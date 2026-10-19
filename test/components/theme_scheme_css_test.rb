require "test_helper"

# `data-nk-scheme` lets a host whose `data-theme` values are its own names
# (daisyUI's `night`, `lofi`) declare which Nitro palette applies. Every rule
# that selects on `data-theme="dark"` or the no-JavaScript system fallback must
# honour it, or a named dark theme gets light-palette component mechanics.
class ThemeSchemeCssTest < ActiveSupport::TestCase
  DARK_CONTEXT = ':is([data-theme="dark"]:not([data-nk-scheme]), [data-nk-scheme="dark"])'
  SYSTEM_FALLBACK = ":root:not([data-theme], [data-nk-scheme])"

  test "the light palette also answers to data-nk-scheme=light" do
    assert_match(
      /:where\(:root, \[data-theme="light"\], \[data-nk-scheme="light"\]\) \{\s*color-scheme: light;/,
      compiled_css
    )
  end

  test "the dark palette answers to data-nk-scheme=dark, which wins over data-theme" do
    assert_match(
      /:where\(\[data-theme="dark"\]:not\(\[data-nk-scheme\]\), \[data-nk-scheme="dark"\]\) \{\s*color-scheme: dark;/,
      compiled_css
    )
  end

  test "the system fallback steps aside when either attribute is present" do
    assert_match(
      /@media \(prefers-color-scheme: dark\) \{\s*:where\(#{Regexp.escape(SYSTEM_FALLBACK)}\) \{\s*color-scheme: dark;/,
      compiled_css
    )
  end

  test "derived tokens and Tailwind aliases resolve on scheme-only elements" do
    assert_includes compiled_css, ":where(:root, [data-theme], [data-nk-scheme]) {\n    --nk-button-default-background"
    assert_includes compiled_css, ":where(:root, [data-theme], [data-nk-scheme]) {\n    --font-sans"
  end

  test "no rule still keys dark behavior on data-theme alone" do
    selectors_without_hook = compiled_css.gsub(%r{/\*.*?\*/}m, "").lines.grep(/data-theme/).reject { |line| line.include?("data-nk-scheme") }

    assert_empty selectors_without_hook.grep(/data-theme="dark"|:not\(\[data-theme\]\)/),
      "dark selectors must include the data-nk-scheme hook"
  end

  test "component dark mechanics use the shared dark context" do
    %w[badge button palette].each do |name|
      css = Rails.root.join("../../src/stylesheets/nitro_kit/components/#{name}.css").read

      assert_includes css, DARK_CONTEXT, "#{name}.css"
      assert_includes css, SYSTEM_FALLBACK, "#{name}.css"
    end
  end

  test "Tailwind aliases sit in their own layer below the Nitro tokens" do
    assert_match(/@layer nitro-kit\.aliases,\s*nitro-kit\.tokens,/, compiled_css)
    assert_match(/@layer nitro-kit\.aliases \{\s*:where\(:root, \[data-theme\], \[data-nk-scheme\]\) \{\s*--font-sans/, compiled_css)
  end

  private

  def compiled_css
    @compiled_css ||= Rails.root.join("../../app/assets/stylesheets/nitro_kit.css").read
  end
end
