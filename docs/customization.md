# Customizing Nitro Kit

Nitro Kit owns component Ruby, markup, behavior, and default CSS. Applications customize the system by overriding the public `--nk-*` custom properties, composing components into application UI, and occasionally creating a narrow subclass. Applications do not copy or edit Nitro components.

## Stylesheet order

Load browser styles in this order:

1. Optional third-party base styles, such as Lexxy.
2. The optional `nitro_kit-tailwind-v4` adapter.
3. The generated `nitro_kit` distribution stylesheet.
4. The application's compiled Tailwind CSS, when present.
5. Application styles, including Nitro token overrides.

`NitroKit::AppearanceBootstrap` precedes every entry in this list. The install
generator owns this ordering and can safely be rerun. For example, an
application with Lexxy and no Tailwind has exactly three stylesheet entries:

```erb
<%= stylesheet_link_tag "lexxy", "nitro_kit", "application", "data-turbo-track": "reload" %>
```

A Rails application without Tailwind can use:

```erb
<%= stylesheet_link_tag "nitro_kit", "application", "data-turbo-track": "reload" %>
```

A Tailwind CSS v4 application can use:

```erb
<%= stylesheet_link_tag \
  "nitro_kit-tailwind-v4", \
  "nitro_kit", \
  "tailwind", \
  "application", \
  "data-turbo-track": "reload" %>
```

Keep overrides unlayered in application CSS and load them after Nitro Kit. Nitro's selectors use `:where()` inside named cascade layers, so an ordinary application rule can override a token without selector escalation or `!important`.

Do not edit `app/assets/stylesheets/nitro_kit.css` in the gem or a bundled copy of it. That file is generated from `src/stylesheets/nitro_kit/` and is replaced on upgrade. Variables named `--_nk-*` are private component mechanics and may change without notice. Only the `--nk-*` variables listed below are the customization contract.

## Global overrides

Shared tokens can be changed once on the document root:

```css
:root {
  --nk-font-sans: Inter, ui-sans-serif, system-ui, sans-serif;
  --nk-content-lg: 52rem;
}
```

Color tokens need a light value, a no-JavaScript system fallback, and a dark value. Keep the selectors in this order:

```css
:root,
[data-theme="light"] {
  --nk-color-primary: oklch(0.55 0.2 260);
  --nk-color-primary-foreground: oklch(0.985 0 0);
  --nk-color-focus: oklch(0.55 0.2 260);
}

@media (prefers-color-scheme: dark) {
  :root:not([data-theme]) {
    --nk-color-primary: oklch(0.72 0.16 260);
    --nk-color-primary-foreground: oklch(0.15 0.02 260);
    --nk-color-focus: oklch(0.72 0.16 260);
  }
}

[data-theme="dark"] {
  --nk-color-primary: oklch(0.72 0.16 260);
  --nk-color-primary-foreground: oklch(0.15 0.02 260);
  --nk-color-focus: oklch(0.72 0.16 260);
}
```

The media query matters when JavaScript or the appearance bootstrap is unavailable. When the runtime is active, `data-theme` is always the resolved `light` or `dark` appearance. `system` is a stored preference in `data-theme-preference`, not a third palette and never a `data-theme="system"` selector.

Buttons can also preserve a product-specific shape without changing inputs or surfaces:

```css
:root {
  --nk-button-radius: var(--nk-radius-full);
}
```

Raised default Buttons have their own color tokens, so their dark treatment can change without recoloring cards, dialogs, menus, or data-entry controls:

```css
@media (prefers-color-scheme: dark) {
  :root:not([data-theme]) {
    --nk-button-default-background: oklch(0.3 0.01 286);
  }
}

[data-theme="dark"] {
  --nk-button-default-background: oklch(0.3 0.01 286);
}
```

## Scoped overrides

Wrap a product area in an application-owned attribute when only that subtree should change:

```ruby
class BillingArea < Phlex::HTML
  def view_template
    div(data: { app_theme: "billing" }) do
      render Billing::Overview.new
    end
  end
end
```

Then scope shared and appearance-specific values. This example follows the document appearance set by `AppearanceBootstrap` while retaining the no-JavaScript system fallback.

```css
[data-app-theme="billing"] {
  --nk-font-sans: ui-monospace, SFMono-Regular, Menlo, monospace;
  --nk-content-md: 36rem;
}

:root [data-app-theme="billing"],
[data-theme="light"] [data-app-theme="billing"] {
  --nk-color-primary: oklch(0.49 0.17 155);
  --nk-color-primary-foreground: white;
}

@media (prefers-color-scheme: dark) {
  :root:not([data-theme]) [data-app-theme="billing"] {
    --nk-color-primary: oklch(0.72 0.16 155);
    --nk-color-primary-foreground: oklch(0.15 0.02 155);
  }
}

[data-theme="dark"] [data-app-theme="billing"] {
  --nk-color-primary: oklch(0.72 0.16 155);
  --nk-color-primary-foreground: oklch(0.15 0.02 155);
}
```

This changes Nitro descendants through inheritance without adding classes to them or reaching into `data-slot` markup.

## Appearance setup

Render `NitroKit::AppearanceBootstrap` in the document `head` before every stylesheet link. It resolves a validated `light`, `dark`, or `system` preference before CSS-visible paint. Render zero, one, or many pickers in the body; they all use the same document runtime.

```ruby
class ApplicationLayout < Phlex::HTML
  include Phlex::Rails::Layout
  include Phlex::Rails::Helpers::ContentSecurityPolicyNonce

  def view_template
    doctype

    html(lang: "en") do
      head do
        render NitroKit::AppearanceBootstrap.new(
          default: :system,
          nonce: content_security_policy_nonce
        )
        stylesheet_link_tag("nitro_kit", data: { turbo_track: "reload" })
        stylesheet_link_tag("application", data: { turbo_track: "reload" })
      end

      body do
        render NitroKit::AppearancePicker.new(
          id: "application-appearance",
          label: "Appearance"
        )
        yield
      end
    end
  end
end
```

The runtime persists the preference in `localStorage` under `nitro-kit-appearance`, follows live operating-system changes in system mode, and synchronizes other tabs. Storage failure leaves in-document selection working and falls back to `default:`. Nitro Kit does not synchronize the preference to an application user record.

For a nonce-based content security policy, pass Rails' `content_security_policy_nonce` as above and allow that nonce in `script-src`. For a hash-based policy, allow the exact fixed script body:

```text
script-src 'self' 'sha256-Vcime4euWSeYtHSfjYjqz/XhRyzMcLpn6Ip2LlaHleY='
```

The value is also available as `NitroKit::AppearanceBootstrap::CSP_HASH`. The default preference is stored in a data attribute, so changing `default:` does not change the hash. Recheck the constant when upgrading because an intentional runtime change produces a new hash.

## Choosing a theme

Treat related tokens as a system:

- Accent changes usually set `--nk-color-primary`, `--nk-color-primary-foreground`, and `--nk-color-focus` for both appearances. The default hover value is derived automatically; set `--nk-color-primary-hover` only when the derived color is unsuitable.
- Neutral changes should coordinate canvas, surface, elevated, foreground, muted, border, and neutral-content pairs for both appearances.
- Default Button changes use the `--nk-button-default-*` tokens. They are separate from `--nk-color-surface` so a raised neutral action can change without recoloring inputs, cards, dialogs, and menus.
- Radius changes should move `--nk-radius-xs` through `--nk-radius-xl` together. Leave `--nk-radius-full` alone unless pills and circular controls should stop being fully rounded. Set `--nk-button-radius` when buttons intentionally use a distinct shape, such as a pill treatment, without changing inputs and surfaces.
- Density changes should coordinate `--nk-space` with all five control-height tokens. Changing one component's internal gap is not a public theme contract.
- Font changes normally set `--nk-font-sans`; set `--nk-font-mono`, text sizes, line heights, or weights only when the whole type system calls for it.

Check foreground pairs and focus indicators for contrast in both appearances. The semantic names describe use, not a fixed hue: `danger` can be a project-appropriate destructive color, but it should remain recognizably destructive everywhere it appears.

## Theme customizer

The interactive theme customizer lives on the documentation site at
[nitrokit.dev/customize](https://nitrokit.dev/customize). Pick an accent, neutral, radius, density, font, and application shell, watch a complete workspace update, then copy deterministic CSS containing only changed public tokens plus a copyable `AppShell` composition for the selected layout.

Paste the CSS into an application-owned stylesheet such as `app/assets/stylesheets/nitro_theme.css`, then load that stylesheet after Nitro Kit and any compiled Tailwind CSS:

```erb
<%= stylesheet_link_tag \
  "nitro_kit", \
  "application", \
  "nitro_theme", \
  "data-turbo-track": "reload" %>
```

The customizer copies text to the clipboard. It does not download files, write into an application, or generate a component implementation.

## Application composition

Composition is the default extension mechanism. Put product policy, routes, copy, and domain objects in application components while Nitro owns the visual components:

Use an application-owned base beside Nitro Kit. Including `NitroKit` once makes
capitalized Kit methods available to descendants; the merge helper below is
ordinary application code and does not call Nitro private APIs:

```ruby
class ApplicationComponent < Phlex::HTML
  include NitroKit

  private

  def merge_attributes(defaults = {}, html: {}, data: {}, aria: {})
    defaults = canonical_attributes(defaults, "defaults")
    html = canonical_attributes(html, "HTML")
    validate_html_boundaries!(html)

    default_data = canonical_attributes(defaults.delete(:data) || {}, "default data", prefix: "data")
    default_aria = canonical_attributes(defaults.delete(:aria) || {}, "default ARIA", prefix: "aria")
    data = canonical_attributes(data, "data", prefix: "data")
    aria = canonical_attributes(aria, "ARIA", prefix: "aria")
    classes = merged_classes(defaults.delete(:class), html.delete(:class))

    defaults.merge(html).tap do |attributes|
      attributes[:class] = classes if classes
      attributes[:data] = default_data.merge(data) if default_data.any? || data.any?
      attributes[:aria] = default_aria.merge(aria) if default_aria.any? || aria.any?
    end
  end

  def canonical_attributes(value, name, prefix: nil)
    raise ArgumentError, "#{name} must be a Hash" unless value.is_a?(Hash)

    value.each_with_object({}) do |(key, item), normalized|
      unless key.is_a?(String) || key.is_a?(Symbol)
        raise ArgumentError, "#{name} attribute keys must be Strings or Symbols"
      end

      key = key.to_s.downcase.tr("_", "-").to_sym
      emitted_name = [ prefix, key ].compact.join("-")
      raise ArgumentError, "Duplicate #{name} attribute #{emitted_name}" if normalized.key?(key)

      normalized[key] = item
    end
  end

  def validate_html_boundaries!(html)
    html.each_key do |key|
      boundary = %w[data aria].find do |name|
        key == name.to_sym || key.to_s.start_with?("#{name}-")
      end
      next unless boundary

      raise ArgumentError, "Pass #{key} through #{boundary}:, not html:"
    end
  end

  def merged_classes(*values)
    tokens = values.compact.flat_map do |value|
      raise ArgumentError, "class values must be Strings" unless value.is_a?(String)

      value.split
    end
    tokens = tokens.reverse.uniq.reverse
    tokens.join(" ") if tokens.any?
  end
end
```

The precedence is explicit:

1. Caller `html:` values replace same-key defaults.
2. Caller `data:` and `aria:` values replace same-key nested defaults.
3. Classes merge instead of replacing. Default tokens come first; caller
   tokens come last; a duplicate survives once at its caller position.

Class attribute order does not override the CSS cascade; application
stylesheet source order still decides conflicts between class rules. The
helper canonicalizes keys to their lowercase, hyphenated HTML spelling before
merging, rejects nested or flattened `data-*`/`aria-*` attributes inside
`html:`, and never mutates the defaults. String, symbol, underscore, and dash
aliases therefore emit once; caller values win over defaults, while duplicate
aliases within one bag raise an error naming the emitted attribute.

A small reusable application component can then provide its own class-based
root while composing Nitro through the public Kit method:

```ruby
module RailsIntegration
  class StatusPill < ApplicationComponent
    STATUSES = %i[received reviewed].freeze

    def initialize(status, html: {}, data: {}, aria: {})
      @status = status.respond_to?(:to_sym) ? status.to_sym : status
      raise ArgumentError, "Unknown status #{status.inspect}" unless STATUSES.include?(@status)

      @attributes = merge_attributes(
        {
          class: "status-pill status-pill--quiet",
          title: "Submission status",
          data: { application_component: "status-pill", state: @status },
          aria: { live: "polite" }
        },
        html:,
        data:,
        aria:
      )
    end

    def view_template
      span(**attributes) do
        Badge(status.to_s.humanize, color: :success, size: :sm)
      end
    end

    private

    attr_reader :attributes, :status
  end
end
```

For example, `html: { class: "receipt-state status-pill--quiet" }, data:
{ state: "reviewed" }, aria: { live: "assertive" }` renders the classes as
`status-pill receipt-state status-pill--quiet` and lets the caller replace the
default state and live mode. The dummy application's
`ApplicationComponent`, `RailsIntegration::StatusPill`, and focused component
test execute this exact reference implementation.

Product components that do not need application classes remain smaller:

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

A narrow subclass is acceptable when it fixes a small, stable application vocabulary and delegates everything to a public constructor:

```ruby
module UI
  class SaveButton < NitroKit::Button
    def initialize(text = "Save", disabled: false, data: {})
      super(text, variant: :primary, type: :submit, disabled:, data:)
    end
  end
end
```

Do not override Nitro rendering methods, private helpers, internal `Data` records, `data-slot` structure, or Stimulus state. Those are implementation details. If a subclass needs those surfaces, compose a new application component instead.

## Application shells

`AppShell` owns responsive application chrome. The caller owns one navigation tree, current-route policy, brand, account actions, and page content:

```ruby
module Workspace
  class Layout < Phlex::HTML
    include Phlex::Rails::Helpers::Routes

    def initialize(page:)
      @page = page
    end

    def view_template
      render NitroKit::AppShell.new(id: "workspace", layout: :sidebar) do |shell|
        shell.brand { strong { "Northstar" } }

        shell.navigation do
          render NitroKit::AppNavigation.new(label: "Primary navigation") do |navigation|
            navigation.body do
              navigation.section(label: "Workspace") do
                navigation.item("Overview", href: root_path, icon: :house, current: true)
                navigation.item("Projects", href: projects_path, icon: :folder, badge: 12)
              end
              navigation.spacer
              navigation.item("Settings", href: settings_path, icon: :settings)
            end
          end
        end

        shell.topbar do
          render NitroKit::Button.new("New project", href: new_project_path, variant: :primary)
        end

        shell.main { render @page }
      end
    end
  end
end
```

Change only `layout:` to `:topbar` or `:hybrid`; the same `brand`, `navigation`, `topbar`, and `main` declarations remain valid. Nitro owns the responsive breakpoint, narrow drawer, focus management, sticky regions, and one reflowed navigation DOM tree. Do not clone navigation for mobile or add route registries to the shell.

The gallery has complete executable examples for [sidebar](/gallery/compositions/application-sidebar), [topbar](/gallery/compositions/application-topbar), and [hybrid](/gallery/compositions/application-hybrid) applications. Each route contains multiple populated, empty, loading, long-content, missing-content, or error combinations.

## Rails forms and Hotwire

Customization does not change Rails ownership. Keep using Rails helpers directly from Phlex and select the Nitro builder explicitly:

```ruby
class ProfileForm < Phlex::HTML
  include Phlex::Rails::Helpers::FormWith

  def initialize(profile)
    @profile = profile
  end

  def view_template
    form_with(model: @profile, builder: NitroKit::FormBuilder) do |form|
      form.group do
        form.field(:name, required: true)
        form.field(:timezone, as: :select, options: timezone_choices)
        form.submit("Save profile")
      end
    end
  end
end
```

Nitro Kit's engine contributes its controller pins automatically when `importmap-rails` is present. The application still owns Stimulus and its normal loader:

```js
// app/javascript/controllers/index.js
import { application } from "controllers/application";
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading";

eagerLoadControllersFrom("controllers", application);
```

This registers Nitro's `controllers/nk/*` modules together with application controllers. Without importmap, server-rendered HTML and CSS remain available, but controller-dependent behavior and compatibility bridges are unavailable unless a bundler-based application exposes and registers those Stimulus modules itself. Nitro Kit ships no third-party JavaScript runtime, and Nitro Kit 2.0 has no JavaScript-package entrypoint.

For the resulting behavior when those modules are not registered, use the
canonical no-JavaScript matrix in [`browser_support.md`](browser_support.md).

## Optional Tailwind CSS v4 adapter

Nitro Kit does not require Tailwind, Tailwind configuration, or Tailwind Preflight — it ships its own global preflight in the `nitro-kit.reset` cascade layer, which unlayered application CSS always overrides. The optional `nitro_kit-tailwind-v4.css` asset only establishes compatible cascade-layer order and maps Nitro tokens to common Tailwind v4 theme variables, including background, foreground, primary, destructive, radii, shadows, fonts, spacing, and transition defaults.

Tailwind remains compiled and configured by the application. An application can add further aliases in its Tailwind CSS source with the v4 CSS-first API:

```css
@import "tailwindcss";

@theme inline {
  --color-brand: var(--nk-color-primary);
  --color-brand-foreground: var(--nk-color-primary-foreground);
  --font-product: var(--nk-font-sans);
}
```

Use `@theme inline` when a Tailwind theme variable references another custom property so generated utilities resolve the live Nitro value. The adapter does not make Tailwind a Nitro runtime dependency, configure source detection, generate utility classes, or permit Tailwind classes inside Nitro component APIs.

## Public token reference

The following variables are the complete public token set. Theme-independent tokens are declared on `:root`. Appearance tokens have light, dark, and system-fallback values. Derived tokens have defaults expressed in terms of other public tokens and remain overrideable.

### Typography

| Token                       | Role                               |
| --------------------------- | ---------------------------------- |
| `--nk-font-sans`            | Default UI font family.            |
| `--nk-font-mono`            | Monospace font family.             |
| `--nk-text-xs`              | Extra-small text size.             |
| `--nk-text-sm`              | Small text size.                   |
| `--nk-text-base`            | Base text size.                    |
| `--nk-text-lg`              | Large text size.                   |
| `--nk-text-xl`              | Extra-large text size.             |
| `--nk-text-2xl`             | Largest shipped display text size. |
| `--nk-leading-tight`        | Tight line-height ratio.           |
| `--nk-leading-normal`       | Default line-height ratio.         |
| `--nk-leading-relaxed`      | Relaxed line-height ratio.         |
| `--nk-font-weight-normal`   | Normal text weight.                |
| `--nk-font-weight-medium`   | Medium text weight.                |
| `--nk-font-weight-semibold` | Semibold text weight.              |
| `--nk-font-weight-bold`     | Bold text weight.                  |
| `--nk-typeset-font-body`    | Typeset body font family.          |
| `--nk-typeset-font-heading` | Typeset heading font family.       |
| `--nk-typeset-font-mono`    | Typeset code font family.          |
| `--nk-typeset-size`         | Typeset base text size.            |
| `--nk-typeset-leading`      | Typeset body line-height ratio.    |
| `--nk-typeset-flow`         | Typeset vertical rhythm unit.      |

### Spacing and dimensions

| Token                    | Role                                                            |
| ------------------------ | --------------------------------------------------------------- |
| `--nk-space`             | Base spacing unit multiplied throughout components and layouts. |
| `--nk-control-height-xs` | Extra-small control height.                                     |
| `--nk-control-height-sm` | Small control height.                                           |
| `--nk-control-height-md` | Default control height.                                         |
| `--nk-control-height-lg` | Large control height.                                           |
| `--nk-control-height-xl` | Extra-large control height.                                     |
| `--nk-content-sm`        | Small Container maximum width.                                  |
| `--nk-content-md`        | Medium Container maximum width.                                 |
| `--nk-content-lg`        | Large Container maximum width.                                  |
| `--nk-content-xl`        | Extra-large Container maximum width.                            |

### Shape, borders, and focus

| Token                | Role                                                                                       |
| -------------------- | ------------------------------------------------------------------------------------------ |
| `--nk-radius-xs`     | Extra-small corner radius.                                                                 |
| `--nk-radius-sm`     | Small corner radius.                                                                       |
| `--nk-radius-md`     | Default control corner radius.                                                             |
| `--nk-radius-lg`     | Large surface corner radius.                                                               |
| `--nk-radius-xl`     | Extra-large overlay corner radius.                                                         |
| `--nk-radius-full`   | Fully rounded pills and circles.                                                           |
| `--nk-button-radius` | Optional Button-only radius override; the default `initial` preserves size-specific radii. |
| `--nk-border-width`  | Default border and separator width.                                                        |
| `--nk-focus-width`   | Focus-ring width.                                                                          |
| `--nk-focus-offset`  | Focus-ring offset.                                                                         |

### Elevation and motion

| Token                  | Role                                  |
| ---------------------- | ------------------------------------- |
| `--nk-shadow-sm`       | Low surface elevation.                |
| `--nk-shadow-md`       | Medium floating elevation.            |
| `--nk-shadow-lg`       | High overlay elevation.               |
| `--nk-duration-fast`   | Fast interaction duration.            |
| `--nk-duration-normal` | Default interaction duration.         |
| `--nk-duration-slow`   | Deliberate overlay or image duration. |
| `--nk-ease`            | Default transition timing function.   |

### Semantic colors

| Token                           | Role                                                                   |
| ------------------------------- | ---------------------------------------------------------------------- |
| `--nk-color-canvas`             | Page canvas and overscroll; light zinc uses a zinc-25-like near-white. |
| `--nk-color-surface`            | Default component surface.                                             |
| `--nk-color-surface-hover`      | Derived interactive surface hover.                                     |
| `--nk-color-elevated`           | Raised or inset-neutral surface.                                       |
| `--nk-color-foreground`         | Primary text and icon color.                                           |
| `--nk-color-muted`              | Quiet fill.                                                            |
| `--nk-color-muted-foreground`   | Secondary text and icon color.                                         |
| `--nk-color-border`             | Borders and separators.                                                |
| `--nk-color-focus`              | Focus indicator.                                                       |
| `--nk-color-primary`            | Primary action and selected-state fill.                                |
| `--nk-color-primary-hover`      | Derived primary interaction hover.                                     |
| `--nk-color-primary-foreground` | Content placed on primary fill.                                        |
| `--nk-color-neutral`            | Neutral status fill or marker.                                         |
| `--nk-color-neutral-content`    | Strong neutral status content.                                         |
| `--nk-color-info`               | Informational status fill or marker.                                   |
| `--nk-color-info-content`       | Informational status content.                                          |
| `--nk-color-success`            | Successful status fill or marker.                                      |
| `--nk-color-success-content`    | Successful status content.                                             |
| `--nk-color-warning`            | Warning status fill or marker.                                         |
| `--nk-color-warning-content`    | Warning status content.                                                |
| `--nk-color-danger`             | Destructive action and error fill.                                     |
| `--nk-color-danger-hover`       | Derived destructive interaction hover.                                 |
| `--nk-color-danger-foreground`  | Content placed on destructive fill.                                    |
| `--nk-color-danger-content`     | Error and destructive status content.                                  |
| `--nk-color-overlay`            | Modal and drawer backdrop.                                             |

The five status families — neutral, info, success, warning, and danger — carry
two roles each. `--nk-color-{family}` is the fill axis: strong marks, icons, and
fills such as the destructive Button or an upload marker. The tint axis
`--nk-palette-{family}` drives the soft surfaces of `Badge`, `Alert`, and
`Toast::Item`, and defaults to the same scale steps as the matching hue family,
so an `info` badge renders exactly like a `blue` badge out of the box:

```css
:root {
  --nk-palette-success: var(--nk-teal-400);
}
:root,
[data-theme="light"] {
  --nk-palette-success-content: var(--nk-teal-800);
}
@media (prefers-color-scheme: dark) {
  :root:not([data-theme]) {
    --nk-palette-success-content: var(--nk-teal-200);
  }
}
[data-theme="dark"] {
  --nk-palette-success-content: var(--nk-teal-200);
}
```

That override retints successful badges, alerts, and toasts together — and only
them; a decorative `green` badge stays green, and success fills elsewhere keep
following `--nk-color-success`. The paired `-content` role carries the
foreground, so change both to keep contrast in hand. Components tint at their
own strength — a Badge reads more strongly than an Alert — but they never
disagree about the hue.

### Color scales

Every color in the system samples these scales. The five neutral families —
slate, gray, zinc, neutral, and stone — and the seventeen chromatic families
each ship all eleven steps. Steps 50-200 are tints and surfaces, 400-600 are
accents and markers, and 700-950 are content colors. Scale steps are
appearance independent; the semantic roles above sample different steps per
appearance.

White and black anchor the poles. Overriding them retints every pure-white
surface and every overlay, for warm-paper or true-black themes:

| Token | Value |
| ----- | ----- |
| `--nk-white` | `#fff` |
| `--nk-black` | `#000` |

The default theme is zinc: `--nk-color-foreground` is `--nk-zinc-900`,
`--nk-color-border` is `--nk-zinc-200`, and so on. Swapping the neutral or the
accent means re-pointing roles at another family, not inventing values:

```css
/* A cooler, slate-based neutral in both appearances. */
:root,
[data-theme="light"] {
  --nk-color-foreground: var(--nk-slate-900);
  --nk-color-muted: var(--nk-slate-100);
  --nk-color-muted-foreground: var(--nk-slate-500);
  --nk-color-border: var(--nk-slate-200);
  --nk-color-neutral: var(--nk-slate-500);
  --nk-color-neutral-content: var(--nk-slate-700);
  --nk-palette-neutral: var(--nk-slate-400);
  --nk-palette-neutral-content: var(--nk-slate-700);
}

@media (prefers-color-scheme: dark) {
  :root:not([data-theme]) {
    --nk-color-canvas: var(--nk-slate-950);
    --nk-color-surface: color-mix(in oklab, var(--nk-slate-950) 45%, var(--nk-slate-900));
    --nk-color-elevated: var(--nk-slate-900);
    --nk-color-foreground: var(--nk-slate-100);
    --nk-color-muted: var(--nk-slate-800);
    --nk-color-muted-foreground: var(--nk-slate-400);
    --nk-color-border: var(--nk-slate-700);
    --nk-color-neutral: var(--nk-slate-400);
    --nk-color-neutral-content: var(--nk-slate-200);
    --nk-palette-neutral-content: var(--nk-slate-200);
  }
}

[data-theme="dark"] {
  --nk-color-canvas: var(--nk-slate-950);
  --nk-color-surface: color-mix(in oklab, var(--nk-slate-950) 45%, var(--nk-slate-900));
  --nk-color-elevated: var(--nk-slate-900);
  --nk-color-foreground: var(--nk-slate-100);
  --nk-color-muted: var(--nk-slate-800);
  --nk-color-muted-foreground: var(--nk-slate-400);
  --nk-color-border: var(--nk-slate-700);
  --nk-color-neutral: var(--nk-slate-400);
  --nk-color-neutral-content: var(--nk-slate-200);
  --nk-palette-neutral-content: var(--nk-slate-200);
}
```

A neutral swap is most visible in dark appearance, where canvas and surfaces
sit on the 800-950 steps and the families genuinely diverge — slate carries
many times the chroma of zinc there. In light appearance the default canvas
and surface are near-white customs with no family identity, so the swap shows
only in borders, muted fills, and text. For a light canvas that follows the
family too, add `--nk-color-canvas: var(--nk-slate-50)`.

An accent works the same way through the primary role:

```css
:root,
[data-theme="light"] {
  --nk-color-primary: var(--nk-indigo-600);
  --nk-color-primary-foreground: white;
  --nk-color-focus: var(--nk-indigo-600);
}

@media (prefers-color-scheme: dark) {
  :root:not([data-theme]) {
    --nk-color-primary: var(--nk-indigo-500);
    --nk-color-primary-foreground: var(--nk-indigo-50);
    --nk-color-focus: var(--nk-indigo-500);
  }
}

[data-theme="dark"] {
  --nk-color-primary: var(--nk-indigo-500);
  --nk-color-primary-foreground: var(--nk-indigo-50);
  --nk-color-focus: var(--nk-indigo-500);
}
```

Values mirror `src/stylesheets/nitro_kit/tokens.css`, which is authoritative.

#### Slate
  
| Token | Value |
| ----- | ----- |
| `--nk-slate-50` | `oklch(98.4% 0.004 247.3)` |
| `--nk-slate-100` | `oklch(96.8% 0.006 249.8)` |
| `--nk-slate-200` | `oklch(93.6% 0.013 252.5)` |
| `--nk-slate-300` | `oklch(85.9% 0.023 254.2)` |
| `--nk-slate-400` | `oklch(71.2% 0.038 255.7)` |
| `--nk-slate-500` | `oklch(55.7% 0.045 257.6)` |
| `--nk-slate-600` | `oklch(45% 0.045 257.1)` |
| `--nk-slate-700` | `oklch(36.4% 0.043 257.5)` |
| `--nk-slate-800` | `oklch(28.5% 0.042 260.9)` |
| `--nk-slate-900` | `oklch(20.6% 0.042 263.3)` |
| `--nk-slate-950` | `oklch(12.9% 0.042 265.8)` |
  
#### Gray
  
| Token | Value |
| ----- | ----- |
| `--nk-gray-50` | `oklch(98.5% 0.002 250.4)` |
| `--nk-gray-100` | `oklch(96.7% 0.002 260.5)` |
| `--nk-gray-200` | `oklch(93.6% 0.005 264.1)` |
| `--nk-gray-300` | `oklch(86.2% 0.011 259.5)` |
| `--nk-gray-400` | `oklch(71.4% 0.02 261.5)` |
| `--nk-gray-500` | `oklch(55.6% 0.027 261.6)` |
| `--nk-gray-600` | `oklch(44.9% 0.031 260.0)` |
| `--nk-gray-700` | `oklch(36.4% 0.033 256.9)` |
| `--nk-gray-800` | `oklch(28.6% 0.034 260.1)` |
| `--nk-gray-900` | `oklch(20.7% 0.033 261.5)` |
| `--nk-gray-950` | `oklch(13% 0.028 262.7)` |
  
#### Zinc
  
| Token | Value |
| ----- | ----- |
| `--nk-zinc-50` | `oklch(98.5% 0 none)` |
| `--nk-zinc-100` | `oklch(96.7% 0.001 286.4)` |
| `--nk-zinc-200` | `oklch(93% 0.003 286.3)` |
| `--nk-zinc-300` | `oklch(86.1% 0.007 286.3)` |
| `--nk-zinc-400` | `oklch(71.4% 0.013 286.1)` |
| `--nk-zinc-500` | `oklch(55.5% 0.017 285.9)` |
| `--nk-zinc-600` | `oklch(44.7% 0.016 285.8)` |
| `--nk-zinc-700` | `oklch(36% 0.012 285.9)` |
| `--nk-zinc-800` | `oklch(28.2% 0.008 285.9)` |
| `--nk-zinc-900` | `oklch(20.8% 0.005 285.9)` |
| `--nk-zinc-950` | `oklch(14% 0.005 285.8)` |
  
#### Neutral
  
| Token | Value |
| ----- | ----- |
| `--nk-neutral-50` | `oklch(98.5% 0 none)` |
| `--nk-neutral-100` | `oklch(97% 0 none)` |
| `--nk-neutral-200` | `oklch(93.2% 0 none)` |
| `--nk-neutral-300` | `oklch(86% 0 none)` |
| `--nk-neutral-400` | `oklch(71.6% 0 none)` |
| `--nk-neutral-500` | `oklch(55.7% 0 none)` |
| `--nk-neutral-600` | `oklch(44.7% 0 none)` |
| `--nk-neutral-700` | `oklch(36.1% 0 none)` |
| `--nk-neutral-800` | `oklch(27.8% 0 none)` |
| `--nk-neutral-900` | `oklch(20.7% 0 none)` |
| `--nk-neutral-950` | `oklch(14.3% 0 none)` |
  
#### Stone
  
| Token | Value |
| ----- | ----- |
| `--nk-stone-50` | `oklch(98.5% 0.001 114.2)` |
| `--nk-stone-100` | `oklch(97% 0.001 85.2)` |
| `--nk-stone-200` | `oklch(93.3% 0.003 64.5)` |
| `--nk-stone-300` | `oklch(85.9% 0.005 52.4)` |
| `--nk-stone-400` | `oklch(71.5% 0.01 56.1)` |
| `--nk-stone-500` | `oklch(55.7% 0.012 62.1)` |
| `--nk-stone-600` | `oklch(45% 0.012 71.1)` |
| `--nk-stone-700` | `oklch(36.4% 0.01 62.3)` |
| `--nk-stone-800` | `oklch(27.8% 0.007 44.5)` |
| `--nk-stone-900` | `oklch(21.1% 0.006 46.3)` |
| `--nk-stone-950` | `oklch(14.7% 0.004 51.8)` |
  
#### Red
  
| Token | Value |
| ----- | ----- |
| `--nk-red-50` | `oklch(97% 0.013 17.5)` |
| `--nk-red-100` | `oklch(93.9% 0.029 17.5)` |
| `--nk-red-200` | `oklch(88.4% 0.061 18.3)` |
| `--nk-red-300` | `oklch(80.2% 0.113 19.7)` |
| `--nk-red-400` | `oklch(71% 0.183 22.3)` |
| `--nk-red-500` | `oklch(63.6% 0.237 25.3)` |
| `--nk-red-600` | `oklch(57.5% 0.235 27.3)` |
| `--nk-red-700` | `oklch(50.7% 0.207 27.6)` |
| `--nk-red-800` | `oklch(45.3% 0.178 26.7)` |
| `--nk-red-900` | `oklch(38.6% 0.14 25.9)` |
| `--nk-red-950` | `oklch(26.8% 0.093 25.8)` |
  
#### Orange
  
| Token | Value |
| ----- | ----- |
| `--nk-orange-50` | `oklch(98.1% 0.015 73.9)` |
| `--nk-orange-100` | `oklch(95.2% 0.038 74.5)` |
| `--nk-orange-200` | `oklch(90.3% 0.075 71.7)` |
| `--nk-orange-300` | `oklch(83% 0.124 65.1)` |
| `--nk-orange-400` | `oklch(75.3% 0.173 56.1)` |
| `--nk-orange-500` | `oklch(70.5% 0.203 47.6)` |
| `--nk-orange-600` | `oklch(64.6% 0.212 41.1)` |
| `--nk-orange-700` | `oklch(55.3% 0.185 38.4)` |
| `--nk-orange-800` | `oklch(48% 0.158 37.7)` |
| `--nk-orange-900` | `oklch(39.8% 0.122 37.7)` |
| `--nk-orange-950` | `oklch(27.6% 0.079 36.7)` |
  
#### Amber
  
| Token | Value |
| ----- | ----- |
| `--nk-amber-50` | `oklch(98.8% 0.016 94.9)` |
| `--nk-amber-100` | `oklch(96% 0.069 96.5)` |
| `--nk-amber-200` | `oklch(92.4% 0.118 95.3)` |
| `--nk-amber-300` | `oklch(87.9% 0.167 92.1)` |
| `--nk-amber-400` | `oklch(82.8% 0.179 84.4)` |
| `--nk-amber-500` | `oklch(76.9% 0.178 70.1)` |
| `--nk-amber-600` | `oklch(66.6% 0.169 58.3)` |
| `--nk-amber-700` | `oklch(55.5% 0.153 49.1)` |
| `--nk-amber-800` | `oklch(48.1% 0.135 46.1)` |
| `--nk-amber-900` | `oklch(40.4% 0.112 45.4)` |
| `--nk-amber-950` | `oklch(28.9% 0.077 46.2)` |
  
#### Yellow
  
| Token | Value |
| ----- | ----- |
| `--nk-yellow-50` | `oklch(98.7% 0.021 102.2)` |
| `--nk-yellow-100` | `oklch(97.3% 0.071 103.1)` |
| `--nk-yellow-200` | `oklch(94.5% 0.13 101.7)` |
| `--nk-yellow-300` | `oklch(90.4% 0.175 97.8)` |
| `--nk-yellow-400` | `oklch(85.2% 0.189 91.9)` |
| `--nk-yellow-500` | `oklch(79.5% 0.174 86.0)` |
| `--nk-yellow-600` | `oklch(68.1% 0.152 75.8)` |
| `--nk-yellow-700` | `oklch(55.6% 0.125 66.6)` |
| `--nk-yellow-800` | `oklch(48.3% 0.111 61.5)` |
| `--nk-yellow-900` | `oklch(41.1% 0.094 57.5)` |
| `--nk-yellow-950` | `oklch(29.6% 0.067 54.1)` |
  
#### Lime
  
| Token | Value |
| ----- | ----- |
| `--nk-lime-50` | `oklch(98.6% 0.026 120.7)` |
| `--nk-lime-100` | `oklch(96.8% 0.076 122.4)` |
| `--nk-lime-200` | `oklch(93.8% 0.129 124.4)` |
| `--nk-lime-300` | `oklch(89.7% 0.195 126.6)` |
| `--nk-lime-400` | `oklch(84.1% 0.228 128.9)` |
| `--nk-lime-500` | `oklch(76.8% 0.223 130.8)` |
| `--nk-lime-600` | `oklch(64.8% 0.19 131.7)` |
| `--nk-lime-700` | `oklch(53.5% 0.147 131.5)` |
| `--nk-lime-800` | `oklch(46.2% 0.125 131.0)` |
| `--nk-lime-900` | `oklch(39.5% 0.1 131.1)` |
| `--nk-lime-950` | `oklch(28.4% 0.073 132.0)` |
  
#### Green
  
| Token | Value |
| ----- | ----- |
| `--nk-green-50` | `oklch(98.1% 0.017 155.9)` |
| `--nk-green-100` | `oklch(96.3% 0.046 156.6)` |
| `--nk-green-200` | `oklch(92.6% 0.088 156.1)` |
| `--nk-green-300` | `oklch(86.7% 0.151 154.3)` |
| `--nk-green-400` | `oklch(79.8% 0.204 151.8)` |
| `--nk-green-500` | `oklch(72.3% 0.209 149.6)` |
| `--nk-green-600` | `oklch(62.7% 0.184 149.2)` |
| `--nk-green-700` | `oklch(52.9% 0.145 150.0)` |
| `--nk-green-800` | `oklch(45.6% 0.121 151.4)` |
| `--nk-green-900` | `oklch(38.3% 0.094 152.4)` |
| `--nk-green-950` | `oklch(27.6% 0.066 153.1)` |
  
#### Emerald
  
| Token | Value |
| ----- | ----- |
| `--nk-emerald-50` | `oklch(97.9% 0.019 165.4)` |
| `--nk-emerald-100` | `oklch(95% 0.056 164.5)` |
| `--nk-emerald-200` | `oklch(90.6% 0.095 164.0)` |
| `--nk-emerald-300` | `oklch(84.2% 0.143 164.5)` |
| `--nk-emerald-400` | `oklch(76.7% 0.167 163.3)` |
| `--nk-emerald-500` | `oklch(69.6% 0.16 162.5)` |
| `--nk-emerald-600` | `oklch(59.6% 0.135 163.2)` |
| `--nk-emerald-700` | `oklch(50.8% 0.108 165.5)` |
| `--nk-emerald-800` | `oklch(44% 0.09 167.0)` |
| `--nk-emerald-900` | `oklch(36.9% 0.074 169.2)` |
| `--nk-emerald-950` | `oklch(27.1% 0.052 172.3)` |
  
#### Teal
  
| Token | Value |
| ----- | ----- |
| `--nk-teal-50` | `oklch(98.3% 0.011 180.8)` |
| `--nk-teal-100` | `oklch(95.5% 0.057 180.5)` |
| `--nk-teal-200` | `oklch(91.1% 0.097 180.6)` |
| `--nk-teal-300` | `oklch(85.2% 0.136 181.0)` |
| `--nk-teal-400` | `oklch(77.8% 0.142 181.9)` |
| `--nk-teal-500` | `oklch(70.3% 0.13 182.5)` |
| `--nk-teal-600` | `oklch(60.1% 0.108 184.6)` |
| `--nk-teal-700` | `oklch(51% 0.089 186.6)` |
| `--nk-teal-800` | `oklch(44.5% 0.077 187.6)` |
| `--nk-teal-900` | `oklch(37.6% 0.062 189.0)` |
| `--nk-teal-950` | `oklch(28.6% 0.047 192.0)` |
  
#### Cyan
  
| Token | Value |
| ----- | ----- |
| `--nk-cyan-50` | `oklch(98.3% 0.017 201.2)` |
| `--nk-cyan-100` | `oklch(95.8% 0.045 202.8)` |
| `--nk-cyan-200` | `oklch(91.8% 0.083 205.0)` |
| `--nk-cyan-300` | `oklch(86.2% 0.126 207.5)` |
| `--nk-cyan-400` | `oklch(78.9% 0.144 211.5)` |
| `--nk-cyan-500` | `oklch(71.5% 0.133 215.3)` |
| `--nk-cyan-600` | `oklch(61% 0.116 221.6)` |
| `--nk-cyan-700` | `oklch(52% 0.097 223.4)` |
| `--nk-cyan-800` | `oklch(45.5% 0.085 224.7)` |
| `--nk-cyan-900` | `oklch(38.8% 0.07 227.1)` |
| `--nk-cyan-950` | `oklch(30.9% 0.056 229.8)` |
  
#### Sky
  
| Token | Value |
| ----- | ----- |
| `--nk-sky-50` | `oklch(97.8% 0.011 237.7)` |
| `--nk-sky-100` | `oklch(94.9% 0.026 234.2)` |
| `--nk-sky-200` | `oklch(90% 0.059 232.1)` |
| `--nk-sky-300` | `oklch(82.7% 0.108 230.2)` |
| `--nk-sky-400` | `oklch(75.3% 0.153 232.8)` |
| `--nk-sky-500` | `oklch(68.5% 0.159 237.3)` |
| `--nk-sky-600` | `oklch(58.8% 0.148 242.0)` |
| `--nk-sky-700` | `oklch(50.1% 0.124 242.7)` |
| `--nk-sky-800` | `oklch(44.5% 0.104 241.2)` |
| `--nk-sky-900` | `oklch(38.1% 0.089 241.3)` |
| `--nk-sky-950` | `oklch(30.1% 0.067 242.7)` |
  
#### Blue
  
| Token | Value |
| ----- | ----- |
| `--nk-blue-50` | `oklch(96.8% 0.015 255.3)` |
| `--nk-blue-100` | `oklch(93.6% 0.03 254.3)` |
| `--nk-blue-200` | `oklch(88.2% 0.059 253.8)` |
| `--nk-blue-300` | `oklch(80.4% 0.101 252.6)` |
| `--nk-blue-400` | `oklch(70.9% 0.155 254.7)` |
| `--nk-blue-500` | `oklch(62.1% 0.205 259.4)` |
| `--nk-blue-600` | `oklch(54.9% 0.244 262.8)` |
| `--nk-blue-700` | `oklch(48.4% 0.239 264.6)` |
| `--nk-blue-800` | `oklch(43.2% 0.201 265.2)` |
| `--nk-blue-900` | `oklch(37% 0.15 266.0)` |
| `--nk-blue-950` | `oklch(28.8% 0.087 267.6)` |
  
#### Indigo
  
| Token | Value |
| ----- | ----- |
| `--nk-indigo-50` | `oklch(96.2% 0.018 272.3)` |
| `--nk-indigo-100` | `oklch(93% 0.033 272.8)` |
| `--nk-indigo-200` | `oklch(87% 0.063 273.7)` |
| `--nk-indigo-300` | `oklch(78% 0.112 275.2)` |
| `--nk-indigo-400` | `oklch(67.6% 0.173 276.7)` |
| `--nk-indigo-500` | `oklch(58.4% 0.23 277.2)` |
| `--nk-indigo-600` | `oklch(51.4% 0.257 277.0)` |
| `--nk-indigo-700` | `oklch(45.3% 0.241 277.0)` |
| `--nk-indigo-800` | `oklch(40.7% 0.196 277.4)` |
| `--nk-indigo-900` | `oklch(34.9% 0.146 278.8)` |
| `--nk-indigo-950` | `oklch(26.4% 0.088 281.2)` |
  
#### Violet
  
| Token | Value |
| ----- | ----- |
| `--nk-violet-50` | `oklch(96.8% 0.016 294.0)` |
| `--nk-violet-100` | `oklch(94.5% 0.027 293.9)` |
| `--nk-violet-200` | `oklch(89.2% 0.058 293.8)` |
| `--nk-violet-300` | `oklch(80.8% 0.106 293.4)` |
| `--nk-violet-400` | `oklch(70.3% 0.173 293.4)` |
| `--nk-violet-500` | `oklch(60.6% 0.24 292.7)` |
| `--nk-violet-600` | `oklch(54.2% 0.279 292.7)` |
| `--nk-violet-700` | `oklch(48.8% 0.269 292.7)` |
| `--nk-violet-800` | `oklch(43.8% 0.234 293.2)` |
| `--nk-violet-900` | `oklch(37.1% 0.192 292.8)` |
| `--nk-violet-950` | `oklch(28.8% 0.139 291.6)` |
  
#### Purple
  
| Token | Value |
| ----- | ----- |
| `--nk-purple-50` | `oklch(97.4% 0.014 308.2)` |
| `--nk-purple-100` | `oklch(95.2% 0.029 307.4)` |
| `--nk-purple-200` | `oklch(90.1% 0.061 306.7)` |
| `--nk-purple-300` | `oklch(82.1% 0.114 306.3)` |
| `--nk-purple-400` | `oklch(71.4% 0.193 305.5)` |
| `--nk-purple-500` | `oklch(62.7% 0.255 303.9)` |
| `--nk-purple-600` | `oklch(55.7% 0.286 302.3)` |
| `--nk-purple-700` | `oklch(49.6% 0.261 302.2)` |
| `--nk-purple-800` | `oklch(44.1% 0.22 303.7)` |
| `--nk-purple-900` | `oklch(37.3% 0.182 304.0)` |
| `--nk-purple-950` | `oklch(29.5% 0.145 303.3)` |
  
#### Fuchsia
  
| Token | Value |
| ----- | ----- |
| `--nk-fuchsia-50` | `oklch(97.7% 0.017 319.8)` |
| `--nk-fuchsia-100` | `oklch(95.2% 0.035 319.4)` |
| `--nk-fuchsia-200` | `oklch(90.3% 0.075 319.7)` |
| `--nk-fuchsia-300` | `oklch(82.9% 0.143 321.2)` |
| `--nk-fuchsia-400` | `oklch(74.3% 0.228 322.1)` |
| `--nk-fuchsia-500` | `oklch(66.5% 0.291 322.3)` |
| `--nk-fuchsia-600` | `oklch(59.1% 0.283 322.9)` |
| `--nk-fuchsia-700` | `oklch(51.8% 0.243 323.8)` |
| `--nk-fuchsia-800` | `oklch(45.9% 0.211 324.8)` |
| `--nk-fuchsia-900` | `oklch(39.1% 0.171 325.5)` |
| `--nk-fuchsia-950` | `oklch(30.1% 0.135 325.7)` |
  
#### Pink
  
| Token | Value |
| ----- | ----- |
| `--nk-pink-50` | `oklch(97.1% 0.015 343.1)` |
| `--nk-pink-100` | `oklch(94.9% 0.027 342.4)` |
| `--nk-pink-200` | `oklch(89.9% 0.062 343.3)` |
| `--nk-pink-300` | `oklch(81.7% 0.125 346.0)` |
| `--nk-pink-400` | `oklch(72.6% 0.196 349.7)` |
| `--nk-pink-500` | `oklch(65.2% 0.242 354.8)` |
| `--nk-pink-600` | `oklch(59.2% 0.239 0.2)` |
| `--nk-pink-700` | `oklch(52.5% 0.213 3.9)` |
| `--nk-pink-800` | `oklch(46.8% 0.188 3.7)` |
| `--nk-pink-900` | `oklch(39.8% 0.152 3.1)` |
| `--nk-pink-950` | `oklch(29.3% 0.109 3.2)` |
  
#### Rose
  
| Token | Value |
| ----- | ----- |
| `--nk-rose-50` | `oklch(96.9% 0.015 12.9)` |
| `--nk-rose-100` | `oklch(94.2% 0.027 11.4)` |
| `--nk-rose-200` | `oklch(89% 0.058 10.9)` |
| `--nk-rose-300` | `oklch(80.7% 0.112 11.2)` |
| `--nk-rose-400` | `oklch(71.3% 0.184 13.5)` |
| `--nk-rose-500` | `oklch(64.5% 0.244 16.2)` |
| `--nk-rose-600` | `oklch(58.6% 0.243 17.6)` |
| `--nk-rose-700` | `oklch(51.4% 0.212 16.9)` |
| `--nk-rose-800` | `oklch(46.4% 0.185 13.4)` |
| `--nk-rose-900` | `oklch(40% 0.157 10.9)` |
| `--nk-rose-950` | `oklch(28.1% 0.107 11.4)` |


### Tint palette

`Badge` carries two color vocabularies on one `color:` option. The semantic
families answer "what does this mean"; the seventeen decorative hues answer
"which color is this", for categorical labelling where meaning is not the
point. Both resolve through `--nk-palette-*` tint roles.

The distinction is deliberate: `color: :danger` follows `--nk-palette-danger`
and moves when an application rethemes its destructive tint, while `color:
:red` follows `--nk-palette-red` and stays red. By default the two agree —
each semantic family samples the same scale steps as its hue family, so
`danger` and `red` render identically until a theme separates them.

Each tint is appearance independent; the paired `-content` foreground resolves
per appearance so labels stay readable in both.

| Token | Role |
| ----- | ---- |
| `--nk-palette-neutral`                 | Neutral status tint; defaults to zinc. |
| `--nk-palette-neutral-content`         | Neutral status content on that tint.   |
| `--nk-palette-info`                    | Info status tint; defaults to blue.    |
| `--nk-palette-info-content`            | Info status content on that tint.      |
| `--nk-palette-success`                 | Success status tint; defaults to green. |
| `--nk-palette-success-content`         | Success status content on that tint.   |
| `--nk-palette-warning`                 | Warning status tint; defaults to amber. |
| `--nk-palette-warning-content`         | Warning status content on that tint.   |
| `--nk-palette-danger`                  | Danger status tint; defaults to red.   |
| `--nk-palette-danger-content`          | Danger status content on that tint.    |
| `--nk-palette-red`                     | Red tint and marker.                   |
| `--nk-palette-red-content`             | Red content on that tint.          |
| `--nk-palette-orange`                  | Orange tint and marker.                |
| `--nk-palette-orange-content`          | Orange content on that tint.       |
| `--nk-palette-amber`                   | Amber tint and marker.                 |
| `--nk-palette-amber-content`           | Amber content on that tint.        |
| `--nk-palette-yellow`                  | Yellow tint and marker.                |
| `--nk-palette-yellow-content`          | Yellow content on that tint.       |
| `--nk-palette-lime`                    | Lime tint and marker.                  |
| `--nk-palette-lime-content`            | Lime content on that tint.         |
| `--nk-palette-green`                   | Green tint and marker.                 |
| `--nk-palette-green-content`           | Green content on that tint.        |
| `--nk-palette-emerald`                 | Emerald tint and marker.               |
| `--nk-palette-emerald-content`         | Emerald content on that tint.      |
| `--nk-palette-teal`                    | Teal tint and marker.                  |
| `--nk-palette-teal-content`            | Teal content on that tint.         |
| `--nk-palette-cyan`                    | Cyan tint and marker.                  |
| `--nk-palette-cyan-content`            | Cyan content on that tint.         |
| `--nk-palette-sky`                     | Sky tint and marker.                   |
| `--nk-palette-sky-content`             | Sky content on that tint.          |
| `--nk-palette-blue`                    | Blue tint and marker.                  |
| `--nk-palette-blue-content`            | Blue content on that tint.         |
| `--nk-palette-indigo`                  | Indigo tint and marker.                |
| `--nk-palette-indigo-content`          | Indigo content on that tint.       |
| `--nk-palette-violet`                  | Violet tint and marker.                |
| `--nk-palette-violet-content`          | Violet content on that tint.       |
| `--nk-palette-purple`                  | Purple tint and marker.                |
| `--nk-palette-purple-content`          | Purple content on that tint.       |
| `--nk-palette-fuchsia`                 | Fuchsia tint and marker.               |
| `--nk-palette-fuchsia-content`         | Fuchsia content on that tint.      |
| `--nk-palette-pink`                    | Pink tint and marker.                  |
| `--nk-palette-pink-content`            | Pink content on that tint.         |
| `--nk-palette-rose`                    | Rose tint and marker.                  |
| `--nk-palette-rose-content`            | Rose content on that tint.         |

### Default button colors

| Token                                  | Role                                    |
| -------------------------------------- | --------------------------------------- |
| `--nk-button-default-background`       | Raised default-action fill.             |
| `--nk-button-default-hover-background` | Raised default-action interaction fill. |
| `--nk-button-default-foreground`       | Content on a raised default action.     |
| `--nk-button-default-border`           | Border around a raised default action.  |

The native file-input selector uses the same treatment. Ordinary inputs, selects, textareas, unchecked controls, cards, dialogs, and menus continue to use the general surface tokens.

### Application shell

| Token                                      | Role                                                                  |
| ------------------------------------------ | --------------------------------------------------------------------- |
| `--nk-app-shell-sidebar-width`             | Desktop sidebar width.                                                |
| `--nk-app-shell-topbar-height`             | Desktop and compact-header height.                                    |
| `--nk-app-shell-background`                | Shell canvas; derived from `--nk-color-canvas`.                       |
| `--nk-app-shell-sidebar-background`        | Sidebar surface; derived from `--nk-color-surface`.                   |
| `--nk-app-shell-sidebar-foreground`        | Sidebar content; derived from `--nk-color-foreground`.                |
| `--nk-app-shell-sidebar-accent`            | Current and hovered navigation fill; derived from `--nk-color-muted`. |
| `--nk-app-shell-sidebar-accent-foreground` | Content on the sidebar accent.                                        |
| `--nk-app-shell-border`                    | Shell chrome separators; derived from `--nk-color-border`.            |
