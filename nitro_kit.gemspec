require_relative "lib/nitro_kit/version"

Gem::Specification.new do |spec|
  spec.name = "nitro_kit"

  spec.version = NitroKit::VERSION
  spec.authors = ["Mikkel Malmberg"]
  spec.email = ["mikkel@brnbw.com"]
  spec.homepage = "https://github.com/mikker/nitro_kit"
  spec.summary = "WIP, not usable yet"
  spec.description = "WIP, not usable yet"
  spec.license = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/mikker/nitro_kit"
  spec.metadata["changelog_uri"] = "https://github.com/mikker/nitro_kit/releases"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir[
      "app/{helpers,components,javascript}/**/*",
      "lib/**/*",
      "MIT-LICENSE",
      "Rakefile",
      "README.md"
    ]
  end

  spec.add_dependency("rails", ">= 7.0.0")
  spec.add_dependency("tailwind_merge", ">= 0.13.0")
  spec.add_dependency("phlex-rails", "~> 2.1.0")
end
