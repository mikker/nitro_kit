module NitroKit
  class Engine < ::Rails::Engine
    # Rails would otherwise derive "nitro_kit_engine". tailwindcss-rails looks up
    # app/assets/tailwind/<engine_name>/engine.css, so the name is public.
    engine_name "nitro_kit"

    IMPORTMAP_PATH = root.join("config/importmap.rb")
    JAVASCRIPT_PATHS = [ root.join("app/javascript") ].freeze
    TAILWIND_PATH = root.join("app/assets/tailwind")

    initializer "nitro_kit.assets" do |app|
      next unless app.config.respond_to?(:assets)

      JAVASCRIPT_PATHS.each do |path|
        app.config.assets.paths << path unless app.config.assets.paths.include?(path)
      end
    end

    # The Tailwind engine entry is a build input for tailwindcss-rails, not a
    # servable asset. Keep it out of Propshaft's load path.
    initializer "nitro_kit.exclude_tailwind_path", before: "propshaft.append_assets_path" do |app|
      next unless app.config.respond_to?(:assets) && app.config.assets.respond_to?(:excluded_paths)

      app.config.assets.excluded_paths << TAILWIND_PATH unless app.config.assets.excluded_paths.include?(TAILWIND_PATH)
    end

    initializer "nitro_kit.importmap", before: "importmap" do |app|
      next unless app.config.respond_to?(:importmap)

      app.config.importmap.paths << IMPORTMAP_PATH unless app.config.importmap.paths.include?(IMPORTMAP_PATH)

      JAVASCRIPT_PATHS.each do |path|
        app.config.importmap.cache_sweepers << path unless app.config.importmap.cache_sweepers.include?(path)
      end
    end
  end
end
