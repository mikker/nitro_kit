module IgnitionKit
  class Railtie < ::Rails::Railtie
    initializer("ignition_kit.initialize") do |application|
      # Ignore our generators as they confuse Zeitwerk
      Rails.autoloaders.main.ignore(File.expand_path("../generators", __dir__))
    end
  end
end
