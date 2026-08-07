require "test_helper"

class GalleryGhostButtonInventoryTest < ActiveSupport::TestCase
  GhostUse = Data.define(:pattern, :reason)
  ROOT = NitroKit::Engine.root
  GHOST_PATTERN = /:ghost\b/
  OWNED_FILES = [
    *ROOT.glob("test/dummy/app/components/gallery/components/**/*.rb"),
    *ROOT.glob("test/dummy/app/components/gallery/compositions/**/*.rb"),
    ROOT.join("test/dummy/app/components/gallery/code_sample.rb"),
    ROOT.join("test/dummy/app/components/gallery/example.rb"),
    ROOT.join("test/dummy/app/components/gallery/page.rb")
  ].freeze
  RETAINED_GHOSTS = {
    "test/dummy/app/components/gallery/components/app_shell_page.rb" => [
      GhostUse.new(
        pattern: /group\.button\("Search", href: "#search", variant: :ghost, size: :sm, icon: :search\)/,
        reason: "topbar utility embedded in application-shell chrome"
      ),
      GhostUse.new(
        pattern: /group\.button\("Account", href: "#account", variant: :ghost, size: :sm, icon: :circle_user_round\)/,
        reason: "account utility embedded in application-shell chrome"
      ),
      GhostUse.new(
        pattern: /Button\.new\("Help", href: "#help", variant: :ghost, size: :sm, icon: :circle_help\)/,
        reason: "help utility embedded in navigation chrome"
      )
    ],
    "test/dummy/app/components/gallery/code_sample.rb" => [
      GhostUse.new(
        pattern: /"Copy",\s+id: copy_button_id,.*?variant: :ghost,/m,
        reason: "copy control embedded in the code toolbar"
      )
    ],
    "test/dummy/app/components/gallery/example.rb" => [
      GhostUse.new(
        pattern: /"Reset",\s+type: :button,\s+variant: :ghost,/m,
        reason: "reset control embedded in the responsive preview toolbar"
      ),
      GhostUse.new(
        pattern: /"Full width",\s+type: :button,\s+variant: :ghost,/m,
        reason: "full-width control embedded in the responsive preview toolbar"
      )
    ],
    "test/dummy/app/components/gallery/page.rb" => [
      GhostUse.new(
        pattern: /variant: destination\.fetch\(:current\) \? :primary : :ghost/,
        reason: "inactive destinations in the gallery's composition-state navigation chrome"
      )
    ],
    "test/dummy/app/components/gallery/components/app_navigation_page.rb" => [
      GhostUse.new(
        pattern: /Button\.new\("Sign out", href: "#sign-out", variant: :ghost, size: :sm, icon: :log_out\)/,
        reason: "account utility embedded in navigation chrome"
      )
    ],
    "test/dummy/app/components/gallery/components/button_page.rb" => [
      GhostUse.new(
        pattern: /id: "gallery-button-variant-ghost",\s+variant: :ghost/m,
        reason: "ghost entry in the Button variant matrix"
      ),
      GhostUse.new(
        pattern: /id: "gallery-button-icon-only",\s+icon: :x,\s+variant: :ghost,/m,
        reason: "dedicated icon-only dismiss treatment in the Button showcase"
      )
    ],
    "test/dummy/app/components/gallery/components/dropdown_page.rb" => [
      GhostUse.new(
        pattern: /menu\.trigger\("Release actions", variant: :ghost\)/,
        reason: "menu trigger embedded in record-card chrome"
      ),
      GhostUse.new(
        pattern: /menu\.trigger\(icon: :ellipsis, label: "Record actions", variant: :ghost\)/,
        reason: "icon-only overflow menu trigger, the canonical low-emphasis record control"
      )
    ],
    "test/dummy/app/components/gallery/components/tooltip_page.rb" => [
      GhostUse.new(
        pattern: /tooltip\.trigger\(\s+icon: :copy,\s+variant: :ghost,/m,
        reason: "icon-only copy control in the Tooltip showcase"
      )
    ],
    "test/dummy/app/components/gallery/compositions/hybrid_application_page.rb" => [
      GhostUse.new(
        pattern: /menu\.trigger\("Ada Lovelace", variant: :ghost, size: :sm\)/,
        reason: "compact account menu trigger embedded in application-shell topbar chrome"
      )
    ],
    "test/dummy/app/components/gallery/compositions/product_resource_page.rb" => [
      GhostUse.new(
        pattern: /href: back_path,\s+icon: :arrow_left,\s+label: back_label,\s+size: :sm,\s+variant: :ghost,/m,
        reason: "compact back link embedded in product-resource toolbar chrome"
      )
    ],
    "test/dummy/app/components/gallery/compositions/sidebar_application_page.rb" => [
      GhostUse.new(
        pattern: /menu\.trigger\("Account", variant: :ghost, size: :sm\)/,
        reason: "compact account menu trigger embedded in application-shell topbar chrome"
      )
    ],
    "test/dummy/app/components/gallery/compositions/topbar_application_page.rb" => [
      GhostUse.new(
        pattern: /group\.button\("Search", href: "#search", variant: :ghost, size: :sm, icon: :search\)/,
        reason: "compact search control embedded in application-shell topbar chrome"
      ),
      GhostUse.new(
        pattern: /menu\.trigger\("Media actions", variant: :ghost, size: :sm\)/,
        reason: "compact record menu trigger embedded in an application card"
      )
    ]
  }.freeze

  test "ghost buttons are limited to the reviewed low-emphasis inventory" do
    actual_by_file = OWNED_FILES.to_h do |path|
      relative_path = path.relative_path_from(ROOT).to_s
      [ relative_path, path.read.scan(GHOST_PATTERN).length ]
    end.reject { |_path, count| count.zero? }

    assert_equal RETAINED_GHOSTS.keys.sort, actual_by_file.keys.sort
    assert_equal 18, actual_by_file.values.sum

    RETAINED_GHOSTS.each do |relative_path, uses|
      source = ROOT.join(relative_path).read

      assert_equal uses.length, actual_by_file.fetch(relative_path)
      uses.each do |use|
        assert_predicate use.reason, :present?
        assert_equal 1, source.scan(use.pattern).length,
          "#{relative_path} lost its reviewed ghost call: #{use.reason}"
      end
    end
  end
end
