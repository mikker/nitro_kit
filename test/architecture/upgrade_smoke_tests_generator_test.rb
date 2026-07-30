require "test_helper"
require "rails/generators/test_case"
require "generators/nitro_kit/upgrade_smoke_tests_generator"

class UpgradeSmokeTestsGeneratorTest < Rails::Generators::TestCase
  tests NitroKit::UpgradeSmokeTestsGenerator
  destination File.expand_path("../../tmp/upgrade_smoke_tests_generator", __dir__)
  setup :prepare_destination

  test "installs tests when the host Minitest infrastructure is present" do
    install_prerequisites

    run_generator

    NitroKit::UpgradeSmokeTestsGenerator::TESTS.each do |path, test_file|
      assert_file path, test_file.content
    end
  end

  test "generates an ApplicationController callback setup seam with practical guidance" do
    install_prerequisites

    run_generator

    assert_file "test/integration/nitro_kit_upgrade_smoke_test.rb" do |content|
      assert_includes content, "class NitroKitUpgradeSmokeTest < NitroKit::UpgradeSmokeTest"
      assert_includes content, "def prepare_nitro_kit_upgrade_smoke_test"
      assert_includes content, "inherits ApplicationController callbacks"
      assert_includes content, "sign_in users(:owner)"
      assert_includes content, "select_account accounts(:primary)"
    end
    assert_file "test/system/nitro_kit_upgrade_smoke_test.rb" do |content|
      assert_includes content, "include NitroKit::UpgradeSmokeSystemTests"
      assert_includes content, "def prepare_nitro_kit_upgrade_smoke_test"
      assert_includes content, "inherits ApplicationController callbacks"
      assert_includes content, "sign_in_as users(:owner)"
      assert_includes content, "select_account accounts(:primary)"
    end
  end

  test "skips unsupported tests with actionable prerequisite messages" do
    output = run_generator

    NitroKit::UpgradeSmokeTestsGenerator::TESTS.each do |path, test_file|
      assert_no_file path
      assert_includes output, "missing #{test_file.prerequisite}"
      assert_includes output, test_file.remedy
    end
  end

  test "generates only the supported integration test" do
    create_host_file("test/test_helper.rb")

    output = run_generator

    assert_file "test/integration/nitro_kit_upgrade_smoke_test.rb"
    assert_no_file "test/system/nitro_kit_upgrade_smoke_test.rb"
    assert_includes output, "missing test/application_system_test_case.rb"
  end

  test "does not overwrite existing tests" do
    install_prerequisites

    NitroKit::UpgradeSmokeTestsGenerator::TESTS.each_key do |path|
      destination = File.join(destination_root, path)
      FileUtils.mkdir_p(File.dirname(destination))
      File.write(destination, "# Application-owned acceptance coverage\n")
    end

    run_generator

    NitroKit::UpgradeSmokeTestsGenerator::TESTS.each_key do |path|
      assert_equal "# Application-owned acceptance coverage\n",
        File.read(File.join(destination_root, path))
    end
  end

  private
    def install_prerequisites
      NitroKit::UpgradeSmokeTestsGenerator::TESTS.each_value do |test_file|
        create_host_file(test_file.prerequisite)
      end
    end

    def create_host_file(path)
      destination = File.join(destination_root, path)
      FileUtils.mkdir_p(File.dirname(destination))
      File.write(destination, "# Host test infrastructure\n")
    end
end
