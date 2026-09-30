require "rails/generators"
require "nitro_kit/ejection"

module NitroKit
  class EjectGenerator < Rails::Generators::Base
    argument :component, type: :string, desc: "Component to eject (for example Button)"
    desc "Copy one component and its dependencies into isolated application-owned code."

    def eject_component
      ejection = Ejection.new(component)
      files = ejection.files
      existing = files.keys.select { |path| File.exist?(File.join(destination_root, path)) }
      if existing.any? && !options[:force]
        say_status :skip, "Already ejected or conflicting files: #{existing.join(', ')}. No files changed; use --force to replace the entire snapshot.", :yellow
        return
      end

      files.each { |path, content| create_file(path, content) }
      say "Render #{ejection.namespace}::#{ejection.component_name}.new(...)"
      say "Load #{ejection.stylesheet_name}.css after nitro_kit.css (stylesheet_link_tag, or your CSS entrypoint)."
      say "Keep Nitro Kit installed and keep the application's Stimulus controller loader enabled. See docs/eject.md."
    rescue ArgumentError => error
      raise Rails::Generators::Error, error.message
    end
  end
end
