module NitroKit
  module SchemaBuilder
    Component = Struct.new(:files, :modules, :gems)

    class Builder
      def initialize
        @schema = {}
        yield self
      end

      def add(
        name,
        components: nil,
        helpers: nil,
        js: [],
        modules: [],
        gems: []
      )
        # Default is one component, one helper with same name
        components ||= [name]
        helpers ||= [name]

        @schema[name] = Component.new(
          [
            components.map { |c| "app/components/nitro_kit/#{c}.rb" },
            helpers.map { |c| "app/helpers/nitro_kit/#{c}_helper.rb" },
            js.map { |c| "app/javascript/controllers/nk/#{c}_controller.js" }
          ].flatten,
          modules,
          gems
        )
      end

      def [](key)
        @schema[key]
      end

      def all
        @schema.keys.map(&:to_s)
      end
    end

    def build_schema(&block)
      Builder.new(&block)
    end
  end
end
