require "set"

module NitroKit
  module SchemaBuilder
    class Component
      def initialize(schema, name, dependencies:, files:, modules:, gems:)
        @schema = schema
        @name = name
        @unresolved_dependencies = dependencies
        @files = files
        @modules = modules
        @gems = gems
        @resolved = false
      end

      attr_reader :name, :files, :modules, :gems, :unresolved_dependencies

      def dependencies
        raise "Component not resolved" unless resolved?
        @dependencies
      end

      def resolve!
        raise "Component already resolved" if resolved?

        @dependencies = @unresolved_dependencies
          .each_with_object(Set.new) do |name, list|
            list.add(name)
            list.merge(@schema.find(name).unresolved_dependencies)
          end
          .map { |name| @schema.find(name) }

        @resolved = true
      end

      def resolved?
        @resolved
      end

      def all_files
        (files + dependencies.flat_map(&:files)).sort
      end

      def all_modules
        (modules + dependencies.flat_map(&:modules)).sort
      end

      def all_gems
        (gems + dependencies.flat_map(&:gems)).sort
      end

      def has_dependencies?
        return true if gems.any?
        return true if modules.any?
        false
      end
    end

    class Schema
      def initialize
        @schema = []
        yield self
        resolve!
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
        components ||= [ name ]
        helpers ||= [ name ]

        files = [
          components.map { |c| "app/components/nitro_kit/#{c}.rb" },
          helpers.map { |c| "app/helpers/nitro_kit/#{c}_helper.rb" },
          js.map { |c| "app/javascript/controllers/nk/#{c}_controller.js" }
        ].flatten

        component = Component.new(
          self,
          name,
          dependencies:,
          files:,
          modules:,
          gems:
        )

        @schema.push(component)
      end

      def all
        @schema
      end

      def find(name)
        component = @schema.find { |c| c.name == name.to_sym }
        raise "Component not found: #{name}" unless component
        component
      end

      def resolved?
        @resolved
      end

      private

      def resolve!
        all.each(&:resolve!)
        @resolved = true
      end
    end

    def build_schema(&block)
      Schema.new(&block)
    end
  end
end
