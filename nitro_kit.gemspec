require_relative "lib/nitro_kit/version"

Gem::Specification.new do |spec|
  spec.name = "nitro_kit"

  spec.version = NitroKit::VERSION
  spec.authors = [ "Mikkel Malmberg" ]
  spec.email = [ "mikkel@brnbw.com" ]
  spec.homepage = "https://nitrokit.dev"
  spec.summary = "An agent-native Phlex UI system for Rails"
  spec.description = "Gem-owned Phlex components, layouts, blocks, static CSS, and Stimulus behavior for Rails applications."
  spec.license = "Nonstandard"
  spec.required_ruby_version = ">= 4.0.6"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/mikker/nitro_kit"
  spec.metadata["changelog_uri"] = "https://github.com/mikker/nitro_kit/releases"
  spec.metadata["license_uri"] = "https://github.com/mikker/nitro_kit/blob/main/LICENSE"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir[
      "app/{components,javascript}/**/*",
      "app/assets/**/*",
      "config/**/*",
      "src/stylesheets/**/*",
      "lib/**/*",
      "docs/**/*",
      "plugins/**/*",
      "plugins/*/.codex-plugin/plugin.json",
      ".agents/plugins/marketplace.json",
      "CHANGELOG.md",
      "LICENSE",
      "README.md",
      "STYLE_GUIDE.md"
    ].select { |path| File.file?(path) }
  end

  spec.add_dependency("rails", ">= 7.0.0")
  spec.add_dependency("phlex-rails", ">= 2.1.0")
  spec.add_dependency("lucide-rails", "~> 0.7")
end
