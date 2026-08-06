require "test_helper"
require "bundler"

class GalleryProductionDependenciesTest < ActiveSupport::TestCase
  test "Pagy is available to the deployed gallery" do
    dependencies = Bundler::Dsl.evaluate(NitroKit::Engine.root.join("Gemfile"), nil, {}).dependencies
    pagy = dependencies.find { _1.name == "pagy" }

    assert pagy
    assert_equal [ :default ], pagy.groups
  end
end
