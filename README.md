<p align="center">
  <a href="https://nitrokit.dev"><img src="https://s3.brnbw.com/Artboard-q85JFfA8Auat32ByIAXtDAsbYGgs5MeTM4GDaonKhlxVniioPDLQTZUeynCfdBSHAfiRYhMWkGaYZC9ClkZS9aFgkBjx9mrAmnFs.png" alt="Nitro Kit" width="335"></a>
</p>

# Nitro Kit

**Audience:** Rails developers evaluating or installing Nitro Kit.

Nitro Kit is a gem-owned Phlex UI system for Rails. The `2.0.0.alpha.3` prerelease
is under active testing and is not stable.

[![RubyGems](https://img.shields.io/gem/v/nitro_kit.svg)](https://rubygems.org/gems/nitro_kit)

## Install

Pin the prerelease:

```ruby
gem "nitro_kit", "2.0.0.alpha.3"
```

```sh
bundle install
bin/rails generate nitro_kit:install
bin/rails nitro_kit:doctor
```

Commit `Gemfile` and `Gemfile.lock`. Before upgrading, review the changelog,
run `bundle update nitro_kit`, rerun the installer, and test the application.
Production applications should use a released gem with a committed lockfile.

Start with:

- [Rails integration](docs/rails_integration.md)
- [Component contracts](docs/component_contracts.md)
- [Customization](docs/customization.md)
- [Browser support](docs/browser_support.md)
- [Nitro Kit 1.x migration](docs/migration_1_to_2.md)
- [Coding-agent guide](docs/agent_guide.md)

Nitro Kit targets maintained evergreen browsers from roughly the previous two
years, with Mobile Safari as a first-class target. See the
[browser support policy](docs/browser_support.md) for exact fallback behavior.

Maintaining Nitro Kit 1? Its frozen documentation remains at
[v1.nitrokit.dev](https://v1.nitrokit.dev).

## License

Nitro Kit uses the custom [NitroKit License](LICENSE).
