<p align="center">
  <a href="https://nitrokit.dev"><img src="https://s3.brnbw.com/Artboard-q85JFfA8Auat32ByIAXtDAsbYGgs5MeTM4GDaonKhlxVniioPDLQTZUeynCfdBSHAfiRYhMWkGaYZC9ClkZS9aFgkBjx9mrAmnFs.png" alt="Nitro Kit" width="335"></a>
</p>

# Nitro Kit

**Rails front-end for the agent era.**

Nitro Kit is a gem-owned, agent-native UI system for Ruby on Rails. The `2.0.0.alpha.3` prerelease is a ground-up rebuild under active testing and must not be treated as stable. New documentation and the Nitro Kit Pro alpha catalog are coming next.

[![RubyGems](https://img.shields.io/gem/v/nitro_kit.svg)](https://rubygems.org/gems/nitro_kit)

## Installation

Install the alpha explicitly and keep it pinned while evaluating it.

```ruby
gem "nitro_kit", "2.0.0.alpha.3"
```

Use the released gem and commit `Gemfile` with `Gemfile.lock`. Before upgrading, review the changelog, run `bundle update nitro_kit`, rerun the installer, and test the application.

```sh
bundle install
bin/rails generate nitro_kit:install
bin/rails nitro_kit:doctor
```

Example migration prompt:

> Upgrade this Rails app to Nitro Kit `2.0.0.alpha.3`. Run the installer, follow its diagnostics, preserve existing behavior and styling, and use Nitro Kit MCP patterns where helpful. Run tests and summarize changes or unresolved issues.

Example new application prompt:

> Build this Rails app with Nitro Kit `2.0.0.alpha.3`. Run the installer, follow the included agent guide, compose gem-owned components, and use Nitro Kit MCP patterns where helpful. Add tests and summarize the result.

The [agent guide](docs/agent_guide.md), [Rails integration guide](docs/rails_integration.md), [component contracts](docs/component_contracts.md), and [browser support policy](docs/browser_support.md) are included with the gem.

## Browser support

Nitro Kit uses modern web standards while keeping core content and actions
usable for the overwhelming majority of people on maintained browsers. The
practical target is current stable and popular evergreen releases from roughly
the previous two years, with Mobile Safari as a first-class target. Small,
feature-detected fallbacks preserve essential behavior without holding
components to the oldest browser's feature set; visual polish may degrade. See
the [browser support policy](docs/browser_support.md) for the dated browser
matrix and canonical full/reduced/unavailable no-JavaScript classifications.

Maintaining Nitro Kit 1? Its frozen documentation remains at [v1.nitrokit.dev](https://v1.nitrokit.dev).

## License

Nitro Kit is distributed under the custom [NitroKit License](LICENSE).
