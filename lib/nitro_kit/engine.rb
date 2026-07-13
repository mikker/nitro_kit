module NitroKit
  class Engine < ::Rails::Engine
    IMPORTMAP_PATH = root.join("config/importmap.rb")
    JAVASCRIPT_PATHS = [ root.join("app/javascript") ].freeze

    initializer "nitro_kit.assets" do |app|
      next unless app.config.respond_to?(:assets)

      JAVASCRIPT_PATHS.each do |path|
        app.config.assets.paths << path unless app.config.assets.paths.include?(path)
      end
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
