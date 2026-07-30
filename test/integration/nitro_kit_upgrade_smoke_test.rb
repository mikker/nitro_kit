require "test_helper"
require "nitro_kit/upgrade_smoke_test"

class NitroKitUpgradeSmokeTest < NitroKit::UpgradeSmokeTest
  teardown do
    I18n.locale = @original_locale if @original_locale
  end

  test "runs the inherited assertions under a host locale" do
    assert_equal :upgrade_smoke, I18n.locale

    profile = NitroKit::UpgradeSmoke::Profile.new(name: "x")
    profile.validate

    assert_equal [ { error: :too_short, count: 3 } ], profile.errors.details.fetch(:name)
  end

  private
    def prepare_nitro_kit_upgrade_smoke_test
      @original_locale = I18n.locale
      I18n.locale = :upgrade_smoke
    end
end
