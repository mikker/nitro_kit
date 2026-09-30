# Eject one component

Gem-owned components, token overrides, and composition remain the default.
Eject is an explicit source-level customization opt-out, never an installation
step. Free eject turns a gem component into your code; Pro exemplars are already
your code when retrieved.

```sh
bin/rails generate nitro_kit:eject Button
```

Use the ordinary Phlex constructor:

```ruby
render Ui::EjectedButton::Button.new("Save", icon: :check)
```

## Files and integration

- `app/components/ui/ejected_button/`: Button, nested slot classes, transitive
  Ruby component/support dependencies (such as Icon), and an application-owned
  Component adapter with a snapshot of base component-level helpers.
- `app/assets/stylesheets/ejected_button.css`: those components' CSS plus shared
  palette/layout rules where needed, with explicit cascade-layer order.
- `app/javascript/controllers/ui/ejected_button/`: referenced Stimulus
  controllers and their local JavaScript imports.
- `config/nitro_kit/ejected/button.json`: source version, component, namespace,
  and generated file inventory. Every source file also records the version.

Keep Nitro Kit installed. The attribute/render kernel (`NitroKit::Component`),
public `--nk-*` tokens, global reset, translations, appearance document runtime,
and third-party integrations (Phlex, Lucide, Turbo, Active Storage) stay shared.
This is not a standalone replacement for the gem. Pin the gem and test kernel
upgrades even after ejecting.

Load the generated CSS after Nitro Kit and before application overrides:

```erb
<%= stylesheet_link_tag "nitro_kit", "ejected_button", "application",
  "data-turbo-track": "reload" %>
```

In Phlex, use the Rails `stylesheet_link_tag` adapter with the same asset names;
CSS bundlers may import the generated file instead. The generator reports this
manual step rather than guessing which of your layouts or CSS entrypoints owns
the page. Keep the app's normal Stimulus loader enabled. Standard Rails importmap
apps already pin `app/javascript/controllers` recursively; bundler apps must
include the generated controllers in their controller loader/build as usual.

Dropzone's copied controller imports Active Storage's JavaScript even when
`direct_upload: false`. If the app omits Active Storage, its JavaScript asset
must still be available; eject does not install third-party integrations.

## Isolation and composition

Each ejection has its own dependency snapshot. Ruby uses `Ui::EjectedButton`,
not `NitroKit` or an existing `Ui::Button`. Root/slot identities use
`ui-ejected-button-*`; controller identifiers follow Rails filename conventions
(`ui--ejected-button--button`); CSS layers, private variables, and keyframes
are renamed. Public tokens and the global reset deliberately remain shared.
Gem Buttons and ejected Buttons can render on the same page without sharing
component CSS or controller identifiers.

Namespace spelling follows the host application's inflections (for example,
an app with the `UI` acronym gets `UI::EjectedButton`). Use the constructor
printed by the generator.

For typed slots, construct children from the same snapshot, for example
`Ui::EjectedEmptyState::Button`. Arbitrary content blocks may still compose gem
components, but snapshot-specific contextual styling targets snapshot children.
Separate ejections do not silently share mutable dependencies.

## Existing files and updates

Unknown names fail with a list of supported names before writing. CamelCase,
snake_case, and `NitroKit::Button` names are accepted. If any snapshot file
already exists, the entire operation skips without changing anything (including
with `--skip`). `--force` explicitly replaces the entire generated snapshot;
commit your modifications first. Stale files from older dependency graphs are
not deleted automatically.

Bundler updates do not update ejected component implementations, styles, or
controllers. Compare the recorded version to the changelog and port fixes
yourself, or generate a new snapshot in a disposable application and diff it.
The manifest enables future update notices; no updater or notice UI ships yet.
Commit all generated files and the stylesheet integration together.
