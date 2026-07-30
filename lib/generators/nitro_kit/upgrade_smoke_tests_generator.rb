require "rails/generators"

module NitroKit
  class UpgradeSmokeTestsGenerator < Rails::Generators::Base
    TestFile = Data.define(:content, :prerequisite, :remedy)

    TESTS = {
      "test/integration/nitro_kit_upgrade_smoke_test.rb" => TestFile.new(
        prerequisite: "test/test_helper.rb",
        remedy: "Install Rails' Minitest test infrastructure, then rerun this generator.",
        content: <<~RUBY
        require "test_helper"
        require "nitro_kit/upgrade_smoke_test"

        class NitroKitUpgradeSmokeTest < NitroKit::UpgradeSmokeTest
          private
            def prepare_nitro_kit_upgrade_smoke_test
              # This endpoint inherits ApplicationController callbacks. Use host helpers here, for example:
              # sign_in users(:owner)
              # select_account accounts(:primary)
            end
        end
      RUBY
      ),
      "test/system/nitro_kit_upgrade_smoke_test.rb" => TestFile.new(
        prerequisite: "test/application_system_test_case.rb",
        remedy: "Run `bin/rails generate system_test`, configure a browser driver, then rerun this generator.",
        content: <<~RUBY
        require "application_system_test_case"
        require "nitro_kit/upgrade_smoke_test"

        class NitroKitUpgradeSmokeSystemTest < ApplicationSystemTestCase
          include NitroKit::UpgradeSmokeSystemTests

          private
            def prepare_nitro_kit_upgrade_smoke_test
              # This endpoint inherits ApplicationController callbacks. Use host browser helpers here, for example:
              # sign_in_as users(:owner)
              # select_account accounts(:primary)
            end
        end
      RUBY
      )
    }.freeze

    def install_upgrade_smoke_tests
      TESTS.each do |path, test_file|
        if File.exist?(destination_path(path))
          say_status :skip, "#{path} already exists", :yellow
          next
        end

        unless File.exist?(destination_path(test_file.prerequisite))
          say_status :skip, "#{path}: missing #{test_file.prerequisite}. #{test_file.remedy}", :yellow
          next
        end

        create_file(path, test_file.content)
      end
    end

    private
      def destination_path(path)
        File.join(destination_root, path)
      end
  end
end
