# Customizing Nitro Kit

Nitro Kit owns component Ruby, markup, behavior, and default CSS. Applications customize the system by overriding the public `--nk-*` custom properties, composing components into application UI, and occasionally creating a narrow subclass. Applications do not copy or edit Nitro components.

## Stylesheet order

Load browser styles in this order:

1. The optional `nitro_kit-tailwind-v4` adapter.
2. The generated `nitro_kit` distribution stylesheet.
3. The application's compiled Tailwind CSS, when present.
4. Application styles, including Nitro token overrides.

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

Raised default Buttons have their own tokens, so their dark treatment can change without recoloring cards, dialogs, menus, or data-entry controls:

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
- Radius changes should move `--nk-radius-xs` through `--nk-radius-xl` together. Leave `--nk-radius-full` alone unless pills and circular controls should stop being fully rounded.
- Density changes should coordinate `--nk-space` with all five control-height tokens. Changing one component's internal gap is not a public theme contract.
- Font changes normally set `--nk-font-sans`; set `--nk-font-mono`, text sizes, line heights, or weights only when the whole type system calls for it.

Check foreground pairs and focus indicators for contrast in both appearances. The semantic names describe use, not a fixed hue: `danger` can be a project-appropriate destructive color, but it should remain recognizably destructive everywhere it appears.

## Customization wizard

Run the repository gallery and open [`/gallery/customize`](/gallery/customize). The wizard offers these closed choices:

- Accent: `blue` (default), `indigo`, `violet`, `rose`, `amber`, `emerald`, or `neutral`.
- Neutral: `slate`, `gray`, `zinc` (default), `neutral`, or `stone`.
- Radius: `none`, `sm`, `md` (default), or `lg`.
- Density: `compact` or `comfortable` (default).
- Font: `system` (default), `humanist`, `serif`, or `mono`.
- Shell: `sidebar` (default), `topbar`, or `hybrid`.

Its shareable query string is readable and versioned in the fixed order `v`, `accent`, `neutral`, `radius`, `density`, `font`, and `shell`, for example:

```text
/gallery/customize?v=1&accent=violet&neutral=slate&radius=lg&density=comfortable&font=humanist&shell=hybrid
```

“Copy CSS” emits only changed public tokens, with deterministic light, system-fallback, and dark selectors. Paste it into an application-owned stylesheet such as `app/assets/stylesheets/nitro_theme.css`, then load that stylesheet after Nitro Kit and any compiled Tailwind CSS:

```erb
<%= stylesheet_link_tag \
  "nitro_kit", \
  "application", \
  "nitro_theme", \
  "data-turbo-track": "reload" %>
```

The wizard copies text to the clipboard. It does not download files, write into an application, or generate a component implementation. Its separate Ruby output is an `AppShell` composition for the selected layout. Preview appearance is intentionally temporary: it is neither serialized into the preset URL nor written to the visitor's Nitro appearance preference.

## Application composition

Composition is the default extension mechanism. Put product policy, routes, copy, and domain objects in application components while Nitro owns the visual components:

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

This registers Nitro's `controllers/nk/*` modules together with application controllers. Without importmap, Ruby and CSS still work, but a bundler-based application must expose and register those Stimulus modules itself. Nitro Kit ships no third-party JavaScript runtime and no JavaScript-package entrypoint in this prerelease.

## Optional Tailwind CSS v4 adapter

Nitro Kit does not require Tailwind, Tailwind configuration, or Preflight. The optional `nitro_kit-tailwind-v4.css` asset only establishes compatible cascade-layer order and maps Nitro tokens to common Tailwind v4 theme variables, including background, foreground, primary, destructive, radii, shadows, fonts, spacing, and transition defaults.

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

The following 84 variables are the complete public token set. Theme-independent tokens are declared on `:root`. Appearance tokens have light, dark, and system-fallback values. Derived tokens have defaults expressed in terms of other public tokens and remain overrideable.

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

| Token               | Role                                |
| ------------------- | ----------------------------------- |
| `--nk-radius-xs`    | Extra-small corner radius.          |
| `--nk-radius-sm`    | Small corner radius.                |
| `--nk-radius-md`    | Default control corner radius.      |
| `--nk-radius-lg`    | Large surface corner radius.        |
| `--nk-radius-xl`    | Extra-large overlay corner radius.  |
| `--nk-radius-full`  | Fully rounded pills and circles.    |
| `--nk-border-width` | Default border and separator width. |
| `--nk-focus-width`  | Focus-ring width.                   |
| `--nk-focus-offset` | Focus-ring offset.                  |

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
