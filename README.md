<p align="center">
  <a href="https://nitrokit.dev"><img src="https://s3.brnbw.com/Artboard-q85JFfA8Auat32ByIAXtDAsbYGgs5MeTM4GDaonKhlxVniioPDLQTZUeynCfdBSHAfiRYhMWkGaYZC9ClkZS9aFgkBjx9mrAmnFs.png" alt="Nitro Kit" width="335"></a>
</p>

# Nitro Kit

**Audience:** Rails developers evaluating or installing Nitro Kit.

Nitro Kit is a gem-owned Phlex UI system for Rails. The `2.0.0.beta.3` prerelease
is under active testing and is not stable.

[![RubyGems](https://img.shields.io/gem/v/nitro_kit.svg)](https://rubygems.org/gems/nitro_kit)

## Install

Pin the prerelease:

```ruby
gem "nitro_kit", "2.0.0.beta.3"
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
- [Eject a component into application-owned code](docs/eject.md)
- [Browser support](docs/browser_support.md)
- [Nitro Kit 1.x migration](docs/migration_1_to_2.md)
- [Coding-agent guide](docs/agent_guide.md)

Nitro Kit targets maintained evergreen browsers from roughly the previous two
years, with Mobile Safari as a first-class target. See the
[browser support policy](docs/browser_support.md) for exact fallback behavior.

## Prompting a coding agent

Add this to a product bootstrap prompt so the agent installs Nitro Kit, uses
its guidance, and discovers optional product patterns when available:

```text
Add Nitro Kit 2 to this Rails app and use it for the product's application UI.

Set up Nitro Kit before planning or implementing the product:
- Add and pin the current Nitro Kit 2 prerelease in the Gemfile, run bundle install, run bin/rails generate nitro_kit:install, and run bin/rails nitro_kit:doctor.
- Load the generated project-local Nitro Kit skills and installed, version-matched docs.
- Check whether Nitro Kit catalog or MCP tools are available. If they are, inventory and search them by product workflow, retrieve relevant patterns, and state what you will use, adapt, or defer.
- If no catalog is available, continue with the bundled docs and component contracts; catalog access is optional.
```

Maintaining Nitro Kit 1? Its frozen documentation remains at
[v1.nitrokit.dev](https://v1.nitrokit.dev).

## Eject for source-level customization

Prefer tokens and composition. When you need to change a component's source:

```sh
bin/rails generate nitro_kit:eject Button
```

Render `Ui::EjectedButton::Button.new("Save")` and load `ejected_button.css`
after `nitro_kit.css`. Ruby, CSS, and Stimulus dependencies become application-owned;
keep the gem installed for the shared kernel and tokens. See [Eject](docs/eject.md)
for integration, collision handling, and upgrade responsibilities.

## License

Nitro Kit uses the custom [NitroKit License](LICENSE).
