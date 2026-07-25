require "test_helper"

class GalleryGhostButtonInventoryTest < ActiveSupport::TestCase
  GhostUse = Data.define(:pattern, :reason)
  ROOT = NitroKit::Engine.root
  GHOST_PATTERN = /:ghost\b/
  OWNED_FILES = [
    *ROOT.glob("test/dummy/app/components/gallery/components/**/*.rb"),
    *ROOT.glob("test/dummy/app/components/gallery/blocks/**/*.rb"),
    *ROOT.glob("test/dummy/app/components/gallery/flows/**/*.rb"),
    ROOT.join("test/dummy/app/components/gallery/customize_page.rb"),
    ROOT.join("test/dummy/app/components/gallery/code_sample.rb")
  ].freeze
  RETAINED_GHOSTS = {
    "test/dummy/app/components/gallery/blocks/app_shell_page.rb" => [
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
    "test/dummy/app/components/gallery/components/app_navigation_page.rb" => [
      GhostUse.new(
        pattern: /Button\.new\("Sign out", href: "#sign-out", variant: :ghost, size: :sm, icon: :log_out\)/,
        reason: "account utility embedded in navigation chrome"
      )
    ],
    "test/dummy/app/components/gallery/components/button_page.rb" => [
      GhostUse.new(
        pattern: /id: "gallery-button-icon-only",\s+icon: :x,\s+variant: :ghost,/m,
        reason: "dedicated icon-only dismiss treatment in the Button showcase"
      )
    ],
    "test/dummy/app/components/gallery/components/dropdown_page.rb" => [
      GhostUse.new(
        pattern: /menu\.trigger\("Release actions", variant: :ghost\)/,
        reason: "menu trigger embedded in record-card chrome"
      )
    ],
    "test/dummy/app/components/gallery/components/tooltip_page.rb" => [
      GhostUse.new(
        pattern: /id: "gallery-tooltip-icon".*?tooltip\.trigger\(\s+variant: :ghost,/m,
        reason: "icon-only copy control in the Tooltip showcase"
      )
    ],
    "test/dummy/app/components/gallery/flows/hybrid_application_page.rb" => [
      GhostUse.new(
        pattern: /menu\.trigger\("Ada Lovelace", variant: :ghost, size: :sm\)/,
        reason: "compact account menu trigger embedded in application-shell topbar chrome"
      )
    ],
    "test/dummy/app/components/gallery/flows/sidebar_application_page.rb" => [
      GhostUse.new(
        pattern: /menu\.trigger\("Account", variant: :ghost, size: :sm\)/,
        reason: "compact account menu trigger embedded in application-shell topbar chrome"
      )
    ],
    "test/dummy/app/components/gallery/flows/topbar_application_page.rb" => [
      GhostUse.new(
        pattern: /group\.button\("Search", href: "#search", variant: :ghost, size: :sm, icon: :search\)/,
        reason: "compact search control embedded in application-shell topbar chrome"
      ),
      GhostUse.new(
        pattern: /menu\.trigger\("Media actions", variant: :ghost, size: :sm\)/,
        reason: "compact record menu trigger embedded in an application card"
      )
    ],
    "test/dummy/app/components/gallery/customize_page.rb" => [
      GhostUse.new(
        pattern: /group\.button\("Search", type: :button, variant: :ghost, size: :sm, icon: :search\)/,
        reason: "topbar utility embedded in preview-shell chrome"
      ),
      GhostUse.new(
        pattern: /group\.button\("Account", type: :button, variant: :ghost, size: :sm, icon: :circle_user_round\)/,
        reason: "account utility embedded in preview-shell chrome"
      ),
      GhostUse.new(
        pattern: /Button\.new\("Help", href: "#customizer-help", variant: :ghost, size: :sm, icon: :circle_help\)/,
        reason: "help utility embedded in preview navigation chrome"
      ),
      GhostUse.new(
        pattern: /variant: :ghost,.*?copy_kind: kind/m,
        reason: "copy control embedded in an export-panel toolbar"
      )
    ]
  }.freeze

  test "ghost buttons are limited to the reviewed low-emphasis inventory" do
    actual_by_file = OWNED_FILES.to_h do |path|
      relative_path = path.relative_path_from(ROOT).to_s
      [ relative_path, path.read.scan(GHOST_PATTERN).length ]
    end.reject { |_path, count| count.zero? }

    assert_equal RETAINED_GHOSTS.keys.sort, actual_by_file.keys.sort
    assert_equal 16, actual_by_file.values.sum

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
