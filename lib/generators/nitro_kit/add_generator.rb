module NitroKit
  class AddGenerator < Rails::Generators::Base
    argument :component_names, type: :array

    source_root File.expand_path("../../../", __dir__)

    def copy_base_component
      copy_file("app/components/nitro_kit/component.rb", "app/components/nitro_kit/component.rb")
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

      gems.each do |name|
        gem(name) unless has_gem?(name)
      end

      run("bundle install")
    end

    def install_modules
      modules = components.flat_map(&:modules)

      return unless modules.any?

      case js_strategy
      when :importmaps
        run("bin/importmap pin #{modules.join(" ")}")
      when :yarn
        run("yarn add #{modules.join(" ")}")
      when :npm
        run("npm install --save #{modules.join(" ")}")
      when :bun
        run("bun add #{modules.join(" ")}")
      else
        say("Could not determine JS strategy. Please install one of: npm, yarn, bun, or importmaps")
      end
    end

    private

    def components
      list = component_names

      if list == ["all"]
        list = SCHEMA.all
      end

      list.map do |name|
        unless component = SCHEMA[name.to_sym]
          raise "Unknown component `#{name}'"
        end

        component
      end
    end

    def js_strategy
      if File.exist?(File.expand_path("bin/importmap", Rails.root))
        :importmaps
      elsif File.exist?(File.expand_path("yarn.lock", Rails.root))
        :yarn
      elsif File.exist?(File.expand_path("package-lock.json", Rails.root))
        :npm
      elsif File.exist?(File.expand_path("bun.lockb", Rails.root))
        :bun
      else
        nil
      end
    end

    def has_gem?(name)
      gemfile = File.read(File.expand_path("Gemfile", Rails.root))
      gemfile.include?("gem '#{name}'") || gemfile.include?("gem \"#{name}\"")
    end
  end
end
