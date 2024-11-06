require "ignition_kit/schema_builder"

module IgnitionKit
  class AddGenerator < Rails::Generators::Base
    argument :component_names, type: :array
    source_root File.expand_path("../../../", __dir__)

    extend SchemaBuilder

    SCHEMA = build_schema do |s|
      s.add(:badge)
      s.add(
        :button,
        components: [:button, :button_group],
        helpers: [:button, :button_group]
      )
      s.add(
        :dropdown,
        js: [:dropdown],
        modules: ["@floating-ui/core", "@floating-ui/dom"]
      )
      s.add(
        :icon,
        gems: ["lucide-rails"]
      )
    end

    def copy_base_component
      copy_file("app/components/ignition_kit/component.rb", "app/components/ignition_kit/component.rb")
    end

    def copy_component_files
      components.each do |component|
        component.files.each do |path|
          copy_file(path, path)
        end
      end
    end

    def add_gems
      gems = components.flat_map(&:gems)

      return unless gems.any?

      gems.each do |component|
        component.gems.each { |g| gem(g) }
      end

      run("bundle install")
    end

    def install_modules
      modules = components.flat_map(&:modules)

      return unless modules.any?

      if importmaps?
        run("bin/importmap pin #{component.modules.join(" ")}")
      else
        say("oh hai npm/yarn/bun")
      end
    end

    private

    def components
      component_names.map do |name|
        unless component = SCHEMA[name.to_sym]
          raise "Unknown component `#{name}'"
        end

        component
      end
    end

    def importmaps?
      File.exist?(File.expand_path("bin/importmap", Rails.root))
    end
  end
end
