require "application_system_test_case"
require "nitro_kit/upgrade_smoke_test"

class NitroKitUpgradeSmokeSystemTest < ApplicationSystemTestCase
  include NitroKit::UpgradeSmokeSystemTests
end
