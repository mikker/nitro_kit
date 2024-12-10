require "test_helper"

module NitroKit
  class ComponentTest < ActiveSupport::TestCase
    class Tester < Component
      def run(...)
        mattr(...)
      end
    end

    def mattr(...)
      Tester.new.run(...)
    end

    # first argument should win

    test("empty doesn't blow up") do
      assert_equal({}, mattr)
    end

    test("simple merge") do
      assert_equal(
        {class: "a b", data: {one: 1, two: 2}},
        mattr({class: "a b"}, data: {one: 1, two: 2})
      )
      assert_equal(
        {a: 1},
        mattr({a: 1}, a: 2)
      )
    end

    test("class tw merge") do
      assert_equal(
        {class: "shadow bg-black font-bold"},
        mattr({class: "bg-black font-bold"}, class: "bg-red-100 shadow")
      )
    end

    test("data stimulus aware merge") do
      assert_equal(
        {data: {controller: "first last", action: "another->thing#one test#what", state: "last"}},
        mattr(
          {data: {controller: "last", action: "another->thing#one", state: "last"}},
          data: {controller: "first", action: "test#what", state: "first"}
        )
      )
    end
  end
end
