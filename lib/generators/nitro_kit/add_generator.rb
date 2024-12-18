module NitroKit
  class AddGenerator < Rails::Generators::Base
    argument :component_names, type: :array

    source_root File.expand_path("../../../", __dir__)

    def copy_base_component
      copy_file("app/components/nitro_kit/component.rb", "app/components/nitro_kit/component.rb")
    end

    def copy_component_files
      components.map(&:all_files).flatten.uniq.each do |path|
        copy_file(path, path)
      end
    end

    def add_gems
      gems = components.flat_map(&:all_gems)

      return unless gems.any?

      gems.each do |name|
        gem(name) unless has_gem?(name)
      end

      run("bundle install")
    end

    def install_modules
      modules = components.flat_map(&:all_modules).uniq

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
      return @components if @components

      if component_names == ["all"]
        return @components = SCHEMA.all
      end

      # Component names + their dependencies
      @components = component_names
        .flat_map do |name|
          component = SCHEMA.find(name)
          [component] + component.dependencies
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
