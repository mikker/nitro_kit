require "test_helper"

class NitroKitTest < ActiveSupport::TestCase
  test("it has a version number") do
    assert NitroKit::VERSION
  end
end
