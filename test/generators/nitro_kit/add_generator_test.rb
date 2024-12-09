require "test_helper"
require "minitest/mock"

require "generators/nitro_kit/add_generator"

module NitroKit
  class AddGeneratorTest < Rails::Generators::TestCase
    tests AddGenerator

    destination File.expand_path("../tmp", __FILE__)

    setup :prepare_destination

    test("`all' copies every component") do
      assert_nothing_raised do
        run_generator(["all"])
      end

      Dir["app/components/nitro_kit/*.rb"].each do |name|
        assert_file("#{name}")
      end
    end

    test("copies single component with deps") do
      run_generator(["button"])

      assert_component_file("component")
      assert_component_file("button")
      assert_component_file("icon")
    end

    test("adds js modules when importmaps") do
      subject = generator(["dropdown"])

      calls = []

      stub(subject).run do |cmd|
        calls << cmd
      end

      subject.install_modules

      assert_equal 1, calls.length
      assert_equal(
        "bin/importmap pin @floating-ui/core @floating-ui/dom",
        calls.first
      )
    end

    test("adds js modules when yarn") do
      subject = generator(["dropdown"])

      stub(File).exist?(File.expand_path("bin/importmap", Rails.root)) { false }
      stub(File).exist?(File.expand_path("yarn.lock", Rails.root)) { true }

      calls = []

      stub(subject).run do |cmd|
        calls << cmd
      end

      subject.install_modules

      assert_equal 1, calls.length
      assert_equal(
        "yarn add @floating-ui/core @floating-ui/dom",
        calls.first
      )
    end

    test("adds js modules when npm") do
      subject = generator(["dropdown"])

      stub(File).exist? { false }
      stub(File).exist?(File.expand_path("package-lock.json", Rails.root)) { true }

      calls = []

      stub(subject).run do |cmd|
        calls << cmd
      end

      subject.install_modules

      assert_equal 1, calls.length
      assert_equal(
        "npm install --save @floating-ui/core @floating-ui/dom",
        calls.first
      )
    end

    test("adds js modules when bun") do
      subject = generator(["dropdown"])

      stub(File).exist? { false }
      stub(File).exist?(File.expand_path("bun.lockb", Rails.root)) { true }

      calls = []

      stub(subject).run do |cmd|
        calls << cmd
      end

      subject.install_modules

      assert_equal 1, calls.length
      assert_equal(
        "bun add @floating-ui/core @floating-ui/dom",
        calls.first
      )
    end

    test("complains when can't recognize js context") do
      subject = generator(["dropdown"])

      stub(File).exist? { false }

      stub(subject).say(/Could not determine JS strategy/)

      assert_nothing_raised do
        subject.install_modules
      end
    end

    private

    def assert_component_file(name)
      assert_file("app/components/nitro_kit/#{name}.rb")
    end
  end
end
