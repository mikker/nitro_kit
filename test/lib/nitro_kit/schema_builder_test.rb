require "test_helper"

module NitroKit
  class SchemaBuilderSchemaTest < ActiveSupport::TestCase
    test("builds schema and resolves it") do
      schema = SchemaBuilder::Schema.new do |s|
        s.add(:foo)
      end

      assert_equal 1, schema.all.size
      assert schema.resolved?
    end
  end

  class SchemaBuilderComponentTest < ActiveSupport::TestCase
    test("resolves dependencies") do
      schema = SchemaBuilder::Schema.new do |s|
        s.add(:foo, [:bar])
        s.add(:bar, [:baz])
        s.add(:baz, [:foo])
      end

      subject = schema.find(:foo)

      assert_equal [schema.find(:bar), schema.find(:baz)], subject.dependencies
      assert_equal 6, subject.all_files.length
    end
  end
end
