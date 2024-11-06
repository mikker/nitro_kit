require_relative "lib/ignition_kit/version"

Gem::Specification.new do |spec|
  spec.name = "ignition_kit"

  spec.version = IgnitionKit::VERSION
  spec.authors = ["Mikkel Malmberg"]
  spec.email = ["mikkel@brnbw.com"]
  spec.homepage = "https://github.com/IgnitionKit/ignition_kit"
  spec.summary = "WIP, not usable yet"
  spec.description = "WIP, not usable yet"
  spec.license = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/IgnitionKit/ignition_kit"
  spec.metadata["changelog_uri"] = "https://github.com/IgnitionKit/ignition_kit/releases"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir[
      "app/{helpers,components}/**/*",
      "lib/**/*",
      "MIT-LICENSE",
      "Rakefile",
      "README.md"
    ]
  end

  spec.add_dependency("activesupport", ">= 7.0.0")
  spec.add_dependency("tailwind_merge")
  spec.add_dependency("phlex-rails", ">= 2.0.0.beta2")
end
