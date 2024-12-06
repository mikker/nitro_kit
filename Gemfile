source "https://rubygems.org"

gemspec

gem "rails", "~> 8.0.0.rc1"
gem "propshaft"
gem "sqlite3", ">= 2.1"
gem "puma", ">= 5.0"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "lucide-rails"
gem "rouge"
gem "commonmarker"
gem "pagy"

gem "bootsnap", require: false
gem "kamal", require: false
gem "thruster", require: false
gem "image_processing", "~> 1.2"

group :development, :test do
  gem "brakeman", require: false
end

group :development do
  gem "solid_cable"
  gem "hotwire-livereload"
  gem "listen"
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
  gem "cuprite", require: "capybara/cuprite"
end

gem "tailwindcss-rails", "~> 3.0"
