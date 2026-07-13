require "bundler/setup"

APP_RAKEFILE = File.expand_path("test/dummy/Rakefile", __dir__)
load "rails/tasks/engine.rake"

namespace :nitro_kit do
  namespace :css do
    desc "Build the committed Nitro Kit stylesheet"
    task build: "app:nitro_kit:css:build"

    desc "Check that the committed Nitro Kit stylesheet is current"
    task check: "app:nitro_kit:css:check"
  end
end

require "bundler/gem_tasks"
