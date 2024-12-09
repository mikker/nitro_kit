module NitroKit
  module SchemaBuilder
    Component = Struct.new(:name, :files, :dependencies, :modules, :gems)

    class Builder
      def initialize
        @schema = []
        yield self
      end

      def add(
        name,
        dependencies = [],
        components: nil,
        helpers: nil,
        js: [],
        modules: [],
        gems: []
      )
        # Default is one component, one helper with same name
        components ||= [name]
        helpers ||= [name]

        component = Component.new(
          name,
          [
            components.map { |c| "app/components/nitro_kit/#{c}.rb" },
            helpers.map { |c| "app/helpers/nitro_kit/#{c}_helper.rb" },
            js.map { |c| "app/javascript/controllers/nk/#{c}_controller.js" }
          ].flatten,
          dependencies,
          modules,
          gems
        )

        @schema.push(component)
      end

      def find(name)
        @schema.find { |c| c.name == name.to_sym }
      end

      def all
        @schema
      end
    end

    def build_schema(&block)
      Builder.new(&block)
    end
  end
end
