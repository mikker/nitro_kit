require "test_helper"

class NitroKitTest < ActiveSupport::TestCase
  ROOT = NitroKit::Engine.root

  test "stable release metadata and public docs share the current version" do
    version = NitroKit::VERSION
    specification = Gem::Specification.load(ROOT.join("nitro_kit.gemspec").to_s)

    assert_equal "2.0.0", version
    refute Gem::Version.new(version).prerelease?
    assert_equal version, specification.version.to_s
    assert_includes ROOT.join("README.md").read, "The `#{version}` release"
    assert_match(/^## #{Regexp.escape(version)}$/, ROOT.join("CHANGELOG.md").read)
    assert_includes ROOT.join("docs/component_contracts.md").read, "catalog for `#{version}`"
  end
end
