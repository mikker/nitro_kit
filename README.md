<p align="center">
  <a href="https://nitrokit.dev"><img src="https://s3.brnbw.com/Artboard-q85JFfA8Auat32ByIAXtDAsbYGgs5MeTM4GDaonKhlxVniioPDLQTZUeynCfdBSHAfiRYhMWkGaYZC9ClkZS9aFgkBjx9mrAmnFs.png" alt="Nitro Kit" width="335"></a>
</p>

# Nitro Kit

**Rails front-end for the agent era.**

Nitro Kit is a gem-owned, agent-native UI system for Ruby on Rails. The `2.0.0.alpha.1` prerelease is a ground-up rebuild. The free core is available now; new documentation and the verified Nitro Kit Pro catalog are coming next.

[![RubyGems](https://img.shields.io/gem/v/nitro_kit.svg)](https://rubygems.org/gems/nitro_kit)

## Installation

```ruby
gem "nitro_kit", "2.0.0.alpha.1"
```

Use the released gem and commit `Gemfile` with `Gemfile.lock`. Before upgrading, review the changelog, run `bundle update nitro_kit`, rerun the installer, and test the application.

```sh
bundle install
bin/rails generate nitro_kit:install
bin/rails nitro_kit:doctor
```

The [agent guide](docs/agent_guide.md), [Rails integration guide](docs/rails_integration.md), and [component contracts](docs/component_contracts.md) are included with the gem.

Maintaining Nitro Kit 1? Its frozen documentation remains at [v1.nitrokit.dev](https://v1.nitrokit.dev).

## License

Nitro Kit is distributed under the custom [NitroKit License](LICENSE).
