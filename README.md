<p align="center">
  <a href="https://nitrokit.dev"><img src="https://s3.brnbw.com/Artboard-q85JFfA8Auat32ByIAXtDAsbYGgs5MeTM4GDaonKhlxVniioPDLQTZUeynCfdBSHAfiRYhMWkGaYZC9ClkZS9aFgkBjx9mrAmnFs.png" alt="Nitro Kit" width="335"></a>
</p>

# Nitro Kit

Nitro Kit is a gem-owned, agent-native UI system for Ruby on Rails. Applications compose typed Phlex components, layouts, and blocks; Nitro Kit owns their rendered structure, static CSS, and Stimulus behavior.

The `2.0.0.pre.1` release is a complete break from Nitro Kit 1.x. Components are no longer generated into applications, there are no `nk_*` view helpers, and consumer Tailwind configuration is not required.

[![RubyGems](https://img.shields.io/gem/v/nitro_kit.svg)](https://rubygems.org/gems/nitro_kit)

## Requirements

- Ruby 4.0.6 or newer.
- Rails 7.0 or newer.
- A Phlex Rails view layer through `phlex-rails`.
- Stimulus when using interactive components. Importmap is the verified automatic-loading path for this prerelease.

## Installation

Add the prerelease to your application:

```ruby
gem "nitro_kit", "2.0.0.pre.1"
```

Then install it:

```sh
bundle install
bin/rails generate nitro_kit:install
```

The setup generator installs project-local Rails, Hotwire, and UI skills for
Codex and Claude, and maintains the Nitro Kit 2 section in `AGENTS.md`. It does
not copy component Ruby, CSS, helpers, or controllers into the application.
Run it again after upgrading Nitro Kit to refresh the thin skill routers.

Verify the integration or print the application initialization prompt at any
time:

```sh
bin/rails nitro_kit:doctor
bin/rails nitro_kit:prompt
bin/rails nitro_kit:prompt --copy
```

The installer never launches an agent. Its final interactive step only offers
to copy the initialization prompt to the clipboard. Use `--no-prompt` for CI
and scripted installation.

### CSS

Load the shipped stylesheet through the Rails asset pipeline:

```erb
<%= stylesheet_link_tag "nitro_kit", "data-turbo-track": "reload" %>
```

The stylesheet is plain CSS. It does not require Tailwind or Preflight. Load application styles containing token overrides after Nitro Kit. Applications that use Tailwind CSS v4 load the optional adapter first, then Nitro Kit, compiled Tailwind, and application styles:

```erb
<%= stylesheet_link_tag "nitro_kit-tailwind-v4", "nitro_kit", "tailwind", "application", "data-turbo-track": "reload" %>
```

### Stimulus and importmap

Nitro Kit packages its interactive component controllers. With `importmap-rails` installed, the engine adds their pins automatically. A normal Stimulus loader registers them:

```js
// app/javascript/controllers/index.js
import { application } from "controllers/application";
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading";

eagerLoadControllersFrom("controllers", application);
```

The host application must provide `@hotwired/stimulus` and `@hotwired/stimulus-loading`; Nitro Kit does not install those packages. It ships no third-party JavaScript runtime. Rails applications without importmap can render and style every component, but must expose and register Nitro's Stimulus controllers themselves. A JavaScript-package entrypoint is not part of this prerelease.

Date inputs and Switch use native inputs and do not have controllers.

## Usage

Include Nitro Kit once in your base Phlex component. `NitroKit` is a
`Phlex::Kit`, so every subclass can use its capitalized component methods
without `render` or `.new`:

```ruby
class ApplicationComponent < Phlex::HTML
  include NitroKit
end

class AccountActions < ApplicationComponent
  def view_template
    Button("Save", variant: :primary, type: :submit)
  end
end
```

The scoped `NitroKit::Button("Save")` form also works from a Phlex context.
Kit methods render immediately and are unavailable from ERB. The explicit
`NitroKit::Button.new(...)` constructor remains supported when another API
needs a component object.

Compound components use ordinary Ruby methods:

```ruby
Card do |card|
  card.title("Workspace")
  card.body do
    Badge("Active", color: :success)
  end
  card.footer do
    Button("Manage", href: workspace_path)
  end
end
```

Closed options such as variants, sizes, placements, and layout values are validated. Unknown values and invalid slot combinations raise `ArgumentError` instead of silently changing the output. See [the component contracts](docs/component_contracts.md) for the shipped catalog and compound rules.

### Responsive layouts

Use `Flex` for row and column composition and `Grid` for equal-track collections:

```ruby
Flex(
  dir: "col md:row",
  gap: "3 md:6",
  align: "stretch md:center",
  justify: "start md:between"
) do
  render WorkspaceSummary.new
  render WorkspaceActions.new
end

Grid(cols: "1 sm:2 lg:3", gap: "3 lg:6") do
  records.each { |record| render RecordCard.new(record) }
end
```

Each responsive property receives its own string. The required unprefixed value applies mobile-first; optional `sm`, `md`, `lg`, `xl`, and `2xl` overrides begin at 40rem, 48rem, 64rem, 80rem, and 96rem. Scalar values such as `dir: :col`, `cols: 3`, or `gap: 4` remain valid; reverse scalar symbols use underscores, such as `:row_reverse`, and render hyphenated data tokens. Nitro validates a closed vocabulary, normalizes breakpoint order into the rendered `data-*` attributes, and ships all required CSS. This syntax is not a Tailwind class list and does not require Tailwind at runtime. See [the layout contracts](docs/component_contracts.md#layout-primitives) for every accepted value.

## Rails forms and Hotwire

Rails continues to own form names, IDs, values, validation errors, multipart behavior, CSRF, routes, DOM IDs, and Turbo semantics. Use the Nitro form builder explicitly from Phlex:

```ruby
class ProfileForm < Phlex::HTML
  include Phlex::Rails::Helpers::FormWith

  def initialize(profile)
    @profile = profile
  end

  def view_template
    form_with(model: @profile, builder: NitroKit::FormBuilder) do |form|
      form.field(:name, required: true)
      form.field(:timezone, as: :select, options: timezone_choices)
      form.submit("Save profile")
    end
  end
end
```

There is no `nk_form_with`, `nk_form_for`, or general ERB component bridge. [Rails and Hotwire integration](docs/rails_integration.md) documents model-backed forms, validation responses, Turbo Frames, and Turbo Streams.

Complete recipes cover [queryable collections](docs/patterns/queryable_collection.md), [resource forms](docs/patterns/resource_form.md), [destructive actions](docs/patterns/destructive_action.md), [flash and toast](docs/patterns/flash_and_toast.md), and [inline editing](docs/patterns/inline_edit.md). They use one interaction grammar: ordinary Rails first, one stable Turbo Frame for one independently changing region, request-scoped Turbo Streams for multiple regions, and broadcasts only for other sessions.

## Attributes and application behavior

Component semantics are explicit keywords. Less common native attributes use three deliberate boundaries:

```ruby
NitroKit::Button.new(
  "Save",
  html: { formnovalidate: true },
  aria: { describedby: "save-help" },
  data: { controller: "autosave", action: "click->autosave#record" }
)
```

Nitro Kit reserves `data-nk`, `data-slot`, `data-variant`, `data-size`, `data-state`, and `data-nk-escape`. Application Stimulus controllers and actions compose with Nitro-owned behavior; other collisions raise.

`class:` and `style:` are forbidden. When an external integration genuinely requires a class, use the intentionally loud exception:

```ruby
NitroKit::Button.new(
  "Open support",
  desperately_need_a_class: "support-widget-trigger"
)
```

It renders the class together with `data-nk-escape="class"`, making the exception observable in tests and the DOM.

## Themes

Nitro Kit owns the component CSS and default light and dark themes. Applications customize documented `--nk-*` custom properties:

```css
:root {
  --nk-font-sans: Inter, ui-sans-serif, system-ui, sans-serif;
  --nk-content-lg: 52rem;
}
```

Override semantic colors as coordinated foreground pairs for light, dark, and no-JavaScript system fallback rather than setting one root color in isolation.

Nitro's appearance runtime owns a persistent light, dark, or live system preference. Render `NitroKit::AppearanceBootstrap` in `head` before stylesheet links, and place `NitroKit::AppearancePicker` wherever people choose it. Without JavaScript, the token layer still follows `prefers-color-scheme`. Explicit `data-theme="light"` and `data-theme="dark"` contracts override that fallback.

Public tokens cover semantic colors, the raised default-button treatment, typography, spacing, radii, borders, focus geometry, shadows, motion, control heights, content widths, and application-shell chrome. The default Button has component-specific color tokens so changing it does not recolor data-entry surfaces. Variables beginning with `--_nk-` are private component mechanics. The [customization guide](docs/customization.md) is the complete supported-token reference and includes load order, global and scoped light/dark/system recipes, the gallery wizard, shell composition, and the optional Tailwind adapter. [Rails and Hotwire integration](docs/rails_integration.md#appearance-and-content-security-policy) documents bootstrap placement, persistence, and nonce- and hash-based CSP setup.

## Composition and extension

Composition is the stable extension path. Application-specific product UI belongs in the application's namespace:

```ruby
module UI
  class UpgradeNotice < Phlex::HTML
    def view_template
      render NitroKit::Alert.new(variant: :warning) do |alert|
        alert.title("Plan limit reached")
        alert.description("Upgrade to invite another teammate.")
      end
    end
  end
end
```

Subclassing a Nitro component is allowed when composition cannot express the requirement, but only public constructors and compound methods are stable. Private rendering helpers and internal `Data` records may change between releases. The [customization guide](docs/customization.md#application-composition) shows both boundaries with copyable Phlex examples.

## Catalog

The prerelease ships:

- 37 atoms and components covering actions, display, forms, rich text, structure, navigation, appearance, uploads, images, and overlays.
- Three evidence-backed layouts: responsive `Flex`, responsive `Grid`, and `Container`.
- Eleven blocks and shells: `AuthShell`, `AppShell`, `SettingsLayout`, `Toolbar`, `PaginationBar`, `PageHeader`, `StatGrid`, `DataSection`, `FormSection`, `DangerZone`, and `EmptyState`.
- The non-visual `AppearanceBootstrap`, `NitroKit::FormBuilder`, and typed `NitroKit::Choice` values.

The repository's dummy application is the canonical gallery, deployed at
[gallery.nitrokit.dev](https://gallery.nitrokit.dev). It exercises the
component and block catalog across realistic Rails SaaS flows, narrow and wide
layouts, light, dark, and system themes, and success, empty, error, loading,
and destructive states. The gallery also includes a
[customization wizard](https://gallery.nitrokit.dev/gallery/customize) and
complete [sidebar](https://gallery.nitrokit.dev/gallery/compositions/application-sidebar),
[topbar](https://gallery.nitrokit.dev/gallery/compositions/application-topbar), and
[hybrid](https://gallery.nitrokit.dev/gallery/compositions/application-hybrid)
applications. Every example pairs Preview and Code tabs; the highlighted,
copyable Ruby is extracted from the executable body of its Phlex block or
concrete composition method so examples cannot silently drift from their source.

Every component and block page is also self-contained for a coding agent that
fetches only that page. Below the examples it renders that component's row from
[the component contracts](docs/component_contracts.md), inline summaries of the
[patterns](docs/patterns/) that apply to it, and the shared system rules —
composition-only API, explicit keywords and closed vocabularies, the
`html:`/`aria:`/`data:` boundary, the reserved data attributes read live from
`NitroKit::Component`, the `desperately_need_a_class:` escape, and the variant
identity axis. There is exactly one copy of each in the source.

## Coding agents

The [agent guide](docs/agent_guide.md) routes an agent from a product task to the installed component contract and the matching Hotwire recipe. Add its short `AGENTS.md` block to a consuming application so every agent discovers the version-matched docs through `bundle show nitro_kit`.

This repository and the packaged gem also contain a Codex plugin with separate Nitro Kit Rails, UI, and Hotwire skills. Register a checked-out or installed copy as a local marketplace:

```sh
codex plugin marketplace add "$(bundle show nitro_kit)"
```

Then install **Nitro Kit** from that marketplace in the ChatGPT desktop app. The plugin contains no MCP server and needs no authentication; its skills read the documentation from the application's installed gem before they work.

## Migrating from 1.x

Nitro Kit 2.0 does not include a general compatibility layer. Replace:

- Generated component copies with gem-owned Nitro Kit components.
- `nk_*` ERB helpers and generated variant helpers with capitalized Kit methods such as `Button(...)` from Phlex.
- `from_template`, conditional builder capture, and template-buffer bridges with normal Phlex blocks and compound methods.
- Arbitrary component keyword attributes with explicit options or `html:`, `aria:`, and `data:`.
- Tailwind class customization with documented `--nk-*` theme variables or application composition.
- `VStack` and `HStack` with `Flex(dir: :col, ...)` and `Flex(dir: :row, ...)`; use responsive property strings when the direction or spacing changes by viewport.
- `nk_form_with` and `nk_form_for` with Rails `form_with(..., builder: NitroKit::FormBuilder)`.
- `nk_pagy_nav(@pagy)` with `Pagination(pagy: @pagy)`. Pagination retains this direct Pagy integration because page-series adaptation is mechanical rather than application policy.

The old generators, helper modules, schema/variant layer, Tailwind Merge dependency, vendored Floating UI and combobox navigation code, and ERB test pages have been removed.

## Development

Use the repository's `mise` environment:

```sh
mise exec -- bundle install
mise exec -- bin/rails test
mise exec -- bin/rubocop
mise exec -- rake nitro_kit:css:build
mise exec -- rake nitro_kit:css:check
```

Run the gallery on port 3031 with:

```sh
mise exec -- bin/dev
```

## License

Nitro Kit is distributed under the custom [NitroKit License](LICENSE). It permits use and modification, including commercial application use, subject to its attribution and redistribution restrictions. It is not the MIT License.
