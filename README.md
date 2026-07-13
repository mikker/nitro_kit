<p align="center">
  <a href="https://nitrokit.dev"><img src="https://s3.brnbw.com/Artboard-q85JFfA8Auat32ByIAXtDAsbYGgs5MeTM4GDaonKhlxVniioPDLQTZUeynCfdBSHAfiRYhMWkGaYZC9ClkZS9aFgkBjx9mrAmnFs.png" alt="Nitro Kit" width="335"></a>
</p>

# Nitro Kit

Nitro Kit is a gem-owned, agent-native UI system for Ruby on Rails. Applications compose typed Phlex components, layouts, and blocks; Nitro Kit owns their rendered structure, static CSS, and Stimulus behavior.

The `2.0.0.pre.1` release is a complete break from Nitro Kit 1.x. Components are no longer generated into applications, there are no `nk_*` view helpers, and consumer Tailwind configuration is not required.

[![RubyGems](https://img.shields.io/gem/v/nitro_kit.svg)](https://rubygems.org/gems/nitro_kit)

## Requirements

- Ruby 3.2 or newer.
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
```

There is no Nitro Kit install generator. Components, CSS, and controllers stay in the gem and are upgraded with it.

### CSS

Load the shipped stylesheet through the Rails asset pipeline:

```erb
<%= stylesheet_link_tag "nitro_kit", "data-turbo-track": "reload" %>
```

The stylesheet is plain CSS. It does not require Tailwind or Preflight. Applications that use Tailwind CSS v4 may load the optional adapter before both Nitro Kit and their compiled Tailwind stylesheet:

```erb
<%= stylesheet_link_tag "nitro_kit-tailwind-v4", "nitro_kit", "tailwind", "data-turbo-track": "reload" %>
```

### Stimulus and importmap

Nitro Kit packages controllers for Accordion, Combobox, Dialog, Dropdown, Tabs, Toast, and Tooltip. With `importmap-rails` installed, the engine adds their pins automatically. A normal Stimulus loader registers them:

```js
// app/javascript/controllers/index.js
import { application } from "controllers/application";
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading";

eagerLoadControllersFrom("controllers", application);
```

The host application must provide `@hotwired/stimulus` and `@hotwired/stimulus-loading`; Nitro Kit does not install those packages. It ships no third-party JavaScript runtime. Rails applications without importmap can render and style every component, but must expose and register the seven Stimulus controllers themselves. A JavaScript-package entrypoint is not part of this prerelease.

Datepicker and Switch use native inputs and do not have controllers.

## Usage

Direct Phlex construction is the component API:

```ruby
class AccountActions < Phlex::HTML
  def view_template
    render NitroKit::Button.new("Save", variant: :primary, type: :submit)
  end
end
```

Compound components use ordinary Ruby methods:

```ruby
render NitroKit::Card.new do |card|
  card.title("Workspace")
  card.body do
    render NitroKit::Badge.new("Active", color: :success)
  end
  card.footer do
    render NitroKit::Button.new("Manage", href: workspace_path)
  end
end
```

Closed options such as variants, sizes, placements, and layout values are validated. Unknown values and invalid slot combinations raise `ArgumentError` instead of silently changing the output. See [the component contracts](docs/component_contracts.md) for the shipped catalog and compound rules.

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
  --nk-color-primary: oklch(0.55 0.18 260);
  --nk-color-primary-hover: oklch(0.49 0.18 260);
  --nk-radius-md: 0.5rem;
  --nk-font-sans: Inter, ui-sans-serif, system-ui, sans-serif;
}
```

Use `data-theme="light"` or `data-theme="dark"` on a document or containing element. Public tokens cover semantic colors, typography, spacing, radii, borders, focus geometry, shadows, motion, control heights, and content widths. Variables beginning with `--_nk-` are private component mechanics.

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

Subclassing a Nitro component is allowed when composition cannot express the requirement, but only public constructors and compound methods are stable. Private rendering helpers and internal `Data` records may change between releases.

## Catalog

The prerelease ships:

- 30 atoms and components covering actions, display, forms, structure, navigation, and overlays.
- Four evidence-backed layouts: `VStack`, `HStack`, `Grid`, and `Container`.
- Ten blocks and shells: `AuthShell`, `SettingsLayout`, `Toolbar`, `PaginationBar`, `PageHeader`, `StatGrid`, `DataSection`, `FormSection`, `DangerZone`, and `EmptyState`.
- `NitroKit::FormBuilder` and typed `NitroKit::Choice` values for Rails form composition.

The repository's dummy application is the canonical gallery. It exercises the component and block catalog across realistic Rails SaaS flows, narrow and wide layouts, light and dark themes, and success, empty, error, loading, and destructive states. Every example pairs Preview and Code tabs; the highlighted, copyable Ruby is extracted from the executable body of its Phlex block or concrete flow method so examples cannot silently drift from their source.

## Migrating from 1.x

Nitro Kit 2.0 does not include a compatibility layer. Replace:

- Generated component copies with gem-owned `NitroKit::*` classes.
- `nk_*` ERB helpers and generated variant helpers with direct `render NitroKit::Component.new(...)` calls from Phlex.
- `from_template`, conditional builder capture, and template-buffer bridges with normal Phlex blocks and compound methods.
- Arbitrary component keyword attributes with explicit options or `html:`, `aria:`, and `data:`.
- Tailwind class customization with documented `--nk-*` theme variables or application composition.
- `nk_form_with` and `nk_form_for` with Rails `form_with(..., builder: NitroKit::FormBuilder)`.

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
