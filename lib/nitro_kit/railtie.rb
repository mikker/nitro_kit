module NitroKit
  class Railtie < ::Rails::Railtie
    initializer("nitro_kit.initialize") do
      # Ignore our generators as they confuse Zeitwerk
      Rails.autoloaders.main.ignore(File.expand_path("../generators", __dir__))
    end
  end
end
