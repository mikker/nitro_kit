# Nitro Kit 2.0 component style guide

Nitro Kit is a gem-owned, Phlex-only UI system for Rails. Its public surface is typed Ruby composition, self-describing markup, and static CSS driven by custom properties.

`NitroKit` extends `Phlex::Kit`. Applications should include it once in their
base Phlex component and use capitalized Kit methods as the primary composition
syntax:

```ruby
class ApplicationComponent < Phlex::HTML
  include NitroKit
end

class SaveButton < ApplicationComponent
  def view_template
    Button("Save", variant: :primary)
  end
end
```

The explicit `render NitroKit::Button.new(...)` form remains supported and is
required when constructing a component object for another API. Kit methods
render immediately and only work from a Phlex context; they do not work in ERB.

## Principles

- Prefer the smallest obvious Ruby API.
- Compose components directly with Phlex.
- Make invalid component vocabulary impossible to render silently.
- Keep state and component identity visible in markup.
- Preserve native HTML and Rails semantics.
- Let applications customize themes and compose product-specific UI without editing Nitro internals.
- Keep behavior minimal, progressive, and Turbo-safe.

## Browser compatibility

The public compatibility contract lives in
[`docs/browser_support.md`](docs/browser_support.md). Use modern standards while
keeping essential behavior usable for the overwhelming majority of people on
maintained browsers. The practical target is current stable and popular
evergreen Chrome, Edge, Firefox, macOS Safari, and iOS Safari releases from
roughly the previous two years. Treat Mobile Safari as a primary browser. The
dated release matrix sets the actual floor by release date and usage, not equal
major-version counts.

Prefer approved native standards even when their support is newer than the
window, but do not confuse standards adoption with baseline availability.
Feature-detect the preferred path and add the smallest Nitro-owned fallback
when its absence breaks core content, navigation, submission, disclosure, or
overlay operation. A simpler layout, placement, wrapping, or animation is an
acceptable fallback. Copying controllers into applications, requiring every
consumer to choose a polyfill, or silently leaving a control inert is not.

Record no-JavaScript behavior per interactive component. Test the native and
fallback paths, Turbo cache and reconnect lifecycles, keyboard behavior, and a
representative browser near the support-window floor. Chromium emulation alone
does not establish Safari or iOS compatibility.

Place a broadly supported CSS declaration before a newer visual enhancement,
or use a feature query when unsupported syntax would invalidate layout, color,
contrast, focus visibility, or interaction. Unsupported polish may disappear;
readability and operability may not.

## File layout

```text
app/components/nitro_kit/          # gem-owned atoms, layouts, blocks
app/javascript/controllers/nk/     # gem-owned Stimulus behavior
src/stylesheets/nitro_kit/         # plain CSS authoring sources
app/assets/stylesheets/            # generated browser-ready distribution CSS
test/components/                   # focused render/contract tests
test/dummy/app/components/gallery/ # Phlex gallery pages
test/integration/                  # catalog-driven route coverage
```

Do not add component helper modules or copied-component generators.

## Component anatomy

Use explicit public keywords and pass an internal attribute bundle to the base component:

```ruby
module NitroKit
  class Container < Component
    SIZES = %i[sm md lg xl].freeze

    def initialize(
      size:,
      id: nil,
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil
    )
      size = validate_choice!(:size, size, SIZES)

      super(
        component: :container,
        attributes: { id: }.compact,
        html:,
        aria:,
        data:,
        size:,
        desperately_need_a_class:
      )
    end

    def view_template
      div(**root_attributes) { yield if block_given? }
    end
  end
end
```

These base boundaries are settled for 2.0: explicit component options, deliberate native-attribute bags, reserved Nitro identity, validated closed vocabularies, and one centralized class escape hatch.

## Options and native attributes

Component semantics are explicit keywords. Do not use a broad `**attrs` or `**options` public argument.

Common element semantics can be first-class keywords when central to the component: `id:`, `href:`, `type:`, `name:`, `value:`, `disabled:`, `required:`, and similar.

Less common native attributes use:

- `html:` for ordinary attributes.
- `aria:` for ARIA attributes.
- `data:` for non-reserved application data and additive Stimulus controllers/actions.

Reject `class` and `style`, including nested in `html:`. Reject every spelling of Nitro-reserved data keys, including symbol/string and dashed/underscored forms.

Nitro-owned data cannot be replaced through the public boundary. Collisions raise, except user Stimulus `controller` and `action` values, which compose deterministically with Nitro-owned values.

`Component::COMPONENT_OWNED_DATA_ATTRIBUTES` lists the keys a component writes for itself through `attributes:` — `state`, `disabled`, `required`, `orientation`, `presentation`, `placement`, `layout`, and `field-type`. `Component::RESERVED_DATA_ATTRIBUTES` adds `nk`, `slot`, `variant`, `size`, `nk-escape`, and `enhanced`. Everything in the combined list is rejected from `data:`; the component-owned subset is the part a component may still set internally.

### Variant is an identity axis, not a style hook

A component root's `variant:` and `size:` are its identity axes, and only the base component emits them. Pass them through `super(variant:, size:)`; never write `data-variant` or `data-size` by hand on a root.

A slot may carry its own owned `data-variant` when the slot has variant identity of its own rather than merely inheriting the root's. Two precedents settle the shape:

- `Toast::Item` is a nested component. Its variant reaches `data-variant` through the ordinary root channel, and the parent attaches it to the `toast-item` slot.
- Dropdown `item` is a plain element, so it uses the base component's `slot_attributes(:item, variant:)` channel, which normalizes and owns the value exactly as a root does.

Use `slot_attributes(..., variant:)`; do not hand-merge a `variant` key into a slot's data bag. Both remain Nitro-owned: caller `data: { variant: }` is reserved and raises before it can reach a root or a slot. Do not introduce a slot `data-variant` that only restates the root's variant, and do not accept a public `variant:` on a slot that has no closed vocabulary of its own.

## Validation

Validate every closed vocabulary at construction time:

```ruby
@variant = validate_choice!(:variant, variant, VARIANTS)
```

Errors identify the invalid option or slot, the received value where useful, and the accepted vocabulary. Do not silently fall back.

Required slots and invalid slot combinations should raise as soon as the component can know them. Do not attempt to validate whole-page information architecture in the component kernel.

## Identity and slots

Every component root emits `data-nk`:

```html
<article data-nk="card"></article>
```

Every owned part has a component-qualified slot:

```html
<article data-nk="card">
  <h2 data-slot="card-title">...</h2>
  <div data-slot="card-body">...</div>
</article>
```

A nested component can have both identities:

```html
<input data-nk="input" data-slot="field-control" />
```

The parent supplies contextual slot identity. An atom such as `Label` must not globally identify itself as every parent's `label` slot.

Prefer direct-child contracts for component-owned structure. Do not style arbitrary application descendants merely because they appear inside a content slot.

## Compound components and content

Direct Phlex Kit composition replaces the old template-aware `builder do`
wrapper. Compound APIs should be ordinary Ruby methods that render into the
current Phlex context.

Named leaf slots may accept arbitrary application content. That is normal composition, not an escape.

When a fixed-order block exposes textual constructor keywords, expose matching deferred compound methods too:

```ruby
EmptyState(level: 3) do |empty|
  empty.title { plain "No records for "; strong { "Production" } }
  empty.description("Remove one or more filters and try again.")
end
```

Constructor text and the matching compound method are two forms of the same region. Accept either one, reject both or repeated declarations, and let required regions be satisfied by either form. Constructor values and compound-method text remain non-blank strings; a compound-method block may render arbitrary Phlex content. Collect these declarations before rendering so the component's owned DOM order does not depend on caller order.

Do not add an untyped structural bypass. If a legitimate application-content boundary is missing, add the smallest named compound method supported by real composition evidence.

## Internationalization

Nitro owns no hardcoded user-facing English. Every string a person can read or
hear — visible copy, ARIA names, live-region announcements, validation
messages — comes from `config/locales/en.yml`, which the engine loads
automatically and which is the single authoritative source of the shipped
copy.

Components call `I18n.t` with a fully qualified key and no `:default`:

```ruby
I18n.t("nitro_kit.dropzone.prompt")
```

Do not duplicate copy into a `default:` argument or a Ruby constant; the
locale file would drift from it. Keys live under one `nitro_kit:` namespace and
are grouped by component (`nitro_kit.<component>.<key>`), with nested `status:`
and `errors:` groups where a component has many. Counted strings use ordinary
`one`/`other` pluralization and `%{...}` interpolation.

Translated text that is a public option stays a public option. Resolve the
default in the keyword itself so an application override still wins:

```ruby
def initialize(label: I18n.t("nitro_kit.pagination.label"))
```

Stimulus controllers never contain user-facing English as behavior. The Ruby
component translates each string the controller needs and emits it through the
Stimulus values API:

```html
<div data-nk--dropzone-queued-value="Queued"></div>
```

The controller reads the value and keeps the shipped English literal only as an
inert fallback for markup assembled without the component. Runtime
interpolation uses the same `%{name}` placeholders the locale file declares, so
a translator sees one grammar in both languages.

## Class escape

Nitro components never emit or depend on classes. The only exception is:

```ruby
desperately_need_a_class: [
  "external-widget-hook",
  { "is-active": active? }
]
```

It accepts Rails `class_names` values—strings, symbols, nested arrays, and conditional hashes—and normalizes them into a deduplicated string. It must contain at least one class and produce both the class and `data-nk-escape="class"`. Implement this once in the base component. Tailwind applications may run a Tailwind-aware merger before passing classes when conflicting utilities need resolution; Nitro does not require one.

## CSS architecture

Author plain CSS in split source files and generate one committed `nitro_kit.css` distribution asset.

Declare deterministic layers:

```css
@layer nitro-kit.tokens,
  nitro-kit.reset,
  nitro-kit.base,
  nitro-kit.variant,
  nitro-kit.size,
  nitro-kit.state,
  nitro-kit.compound;
```

Every Nitro selector uses `:where()`:

```css
@layer nitro-kit.base {
  :where([data-nk="button"]) {
    background: var(--_nk-button-background);
  }
}
```

Variants assign private values and generic state consumes them:

```css
@layer nitro-kit.variant {
  :where([data-nk="button"][data-variant="primary"]) {
    --_nk-button-background: var(--nk-color-primary);
    --_nk-button-hover-background: var(--nk-color-primary-hover);
  }
}

@layer nitro-kit.state {
  @media (hover: hover) {
    :where([data-nk="button"]:hover) {
      background: var(--_nk-button-hover-background);
    }
  }
}
```

Never target an unqualified `[data-slot]`. Never use `transition: all`.

Interaction treatments respond to capability: hover effects sit under `@media (hover: hover)`, and Button extends an invisible touch target to the large control step under `@media (pointer: coarse)`, so taps meet the 44px minimum while the rendered size stays put. Control text keys to the width axis: data-entry controls read `--nk-text-base` below the `md` breakpoint, where a focused control under 16px zooms the viewport, and `--nk-text-sm` from `md` up; buttons read `--nk-text-sm` at every width.

Spacing multipliers on `--nk-space` come from the step set `0.5 1 1.5 2 2.5 3 4 5 6 7 8 10 12 16 24`. Panel and overlay maximums are viewport policy and stay literal rem values; everything a component owns rides a token or a step.

`z-index` has four tiers and no other values: `1`–`3` layer parts inside one component, `10`–`30` layer application-shell chrome, `50` lifts the floating overlays that are not top-layer elements, and `100` is the system tier for the toast column and the skip link. Native dialogs and popovers rely on the top layer instead of a z-index. An element that carries a z-index inside a component must also make its component a stacking context (`isolation: isolate`), or the index leaks into sibling components.

Translucency is mixed in `oklab`, never applied through `opacity`, so dimming cannot cascade into descendants; `opacity` is reserved for `--nk-disabled-opacity` and animating whole overlays. The mixing percentages are a fixed vocabulary: hairline rings and quiet borders mix `10%` of the foreground or black pole, hover washes mix `5%` in light and `15%` of white in dark, inset bevel highlights mix `15–20%` of white, status surfaces tint `12%` in light and `20%` in dark, status borders carry `45%` of their accent, and de-emphasized fills mix `40–65%` toward the surface. A new value in this list is a design decision, not a rounding choice.

Motion uses the one easing curve `--nk-ease` in both directions, deliberately: enter and exit stay interruptible and reversible, and a dedicated accelerate/decelerate pair is a future decision to make once, globally, not per component. Durations come from the three `--nk-duration-*` steps, and every transition and animation stands down under `prefers-reduced-motion`.

## Tokens and themes

Public `--nk-*` variables cover themeable decisions: semantic colors, paired foregrounds, typography, spacing, radii, control dimensions, shadows, borders, motion, and content widths.

Buttons and data-entry controls share control heights, the default radius scale, border geometry, focus treatment, and disabled treatment, but they do not share one surface role. `--nk-button-radius` may override only Button shape when an application deliberately distinguishes buttons from inputs and surfaces. Inputs, selects, textareas, and unchecked controls use the general surface tokens. The raised default Button uses the public `--nk-button-default-background`, `--nk-button-default-hover-background`, `--nk-button-default-foreground`, and `--nk-button-default-border` tokens. Button-like controls such as the native file selector may consume the same treatment; do not make ordinary data-entry surfaces depend on it.

Private `--_nk-*` variables coordinate component mechanics and are not a theme API.

The browser asset order is optional third-party base CSS (such as Lexxy) → optional Tailwind adapter → generated Nitro Kit CSS → compiled Tailwind CSS when present → unlayered application theme overrides. Without Tailwind, load Nitro Kit before application overrides. `AppearanceBootstrap` precedes every stylesheet. Never edit the generated distribution asset; keep the complete supported-token inventory and copyable recipes in [`docs/customization.md`](docs/customization.md).

Do not turn structural keywords, percentages, zero values, grid mechanics, or layout breakpoints into theme tokens. Responsive layout breakpoints are fixed component API, not customizable `--nk-*` values.

Before JavaScript connects, `:root` follows `prefers-color-scheme`. Explicit `[data-theme="light"]` and `[data-theme="dark"]` contracts override it, use the same public tokens, and set the matching `color-scheme`. `data-theme` always describes the resolved light or dark appearance; store a light, dark, or system preference separately. Render Nitro's appearance bootstrap in `head` before stylesheet links so persisted explicit choices do not flash. Its fixed, hashable script body owns one idempotent document-level runtime; defaults live in script data rather than interpolated JavaScript. The runtime validates and persists preference, resolves system appearance, listens for media and cross-tab storage changes even when no picker is present, and broadcasts changes. Any number of appearance pickers only request changes and subscribe. The bootstrap must support nonce- and hash-based host CSPs and tolerate unavailable storage.

Customization tools may read, preview, and export documented public tokens. Model customizer state as an immutable, explicitly versioned value object with closed named choices and readable URL parameters; never serialize an opaque arbitrary-token blob. Exports use stable selector and declaration ordering, cover light, dark, and system fallback, and contain only documented public variables. Structural preview choices may emit copyable component-composition examples, but never component implementations. Customization tools must not expose private `--_nk-*` values, edit the generated distribution asset, generate component copies, or turn arbitrary CSS into a Nitro contract.

The optional `nitro_kit-tailwind-v4.css` adapter is a separate asset. It may map Nitro values into Tailwind v4 theme variables, but Tailwind compilation, source detection, and utilities remain application concerns. Do not add Tailwind as a Nitro runtime dependency.

## Baseline

Nitro CSS never relies on Tailwind Preflight. Nitro ships its own global preflight in `src/stylesheets/nitro_kit/reset.css`, entirely inside the `nitro-kit.reset` cascade layer. It normalizes the whole page — box sizing, margins and padding, borders, root typography, headings, form-control typography and appearance, placeholders, tables, replaced elements, and native-control quirks — so arbitrary content inside a Nitro component behaves the same as Nitro's own markup.

Because it is layered, unlayered application CSS always wins without needing extra specificity.

Two deliberate exceptions to Preflight parity:

- `min-width: 0` applies only to `[data-nk]` roots and owned `[data-slot]` parts.
- `list-style: none` applies only to Nitro-owned lists. Prose lists keep real markers; `Typeset` states its own list styles in `nitro-kit.base`.

## Layout sizing

Parents own external placement and available width. Components own intrinsic geometry.

- Naturally stretchable: inputs, textareas, selects, tables, broad surfaces.
- Naturally intrinsic: buttons, badges, avatars, icons, switches.
- `Flex` decides direction, alignment, distribution, wrapping, and gap through closed responsive values.
- `Grid` decides a 1–12-column equal-track collection and gap through the same responsive grammar.
- `Container` decides available width through a closed size enumeration.

`VStack` and `HStack` are not public components. Use `Flex` with an explicit `dir:`:

```ruby
Flex(dir: :col, gap: 4, align: :stretch) do
  render ProfileForm.new
  render AccountActions.new
end

Flex(
  dir: "col md:row",
  gap: "3 md:6",
  align: "stretch md:center",
  justify: "start md:between"
) do
  render WorkspaceSummary.new
  render WorkspaceActions.new
end
```

Every responsive property accepts either one scalar or its own whitespace-separated string in the grammar `BASE sm:VALUE md:VALUE lg:VALUE xl:VALUE 2xl:VALUE`. The unprefixed base is required and applies mobile-first. Prefixes are fixed minimum widths: `sm` 40rem, `md` 48rem, `lg` 64rem, `xl` 80rem, and `2xl` 96rem. Reject duplicate prefixes, unknown prefixes, missing bases, and values outside the property's closed vocabulary. Normalize output to base then breakpoint order and mirror that exact string in the owned data attribute.

`Flex.new(dir:, gap: 4, align: :start, justify: :start, wrap: :nowrap)` accepts directions `row col row-reverse col-reverse`, alignments `start center end stretch baseline`, justifications `start center end between around evenly`, wraps `nowrap wrap wrap-reverse`, and gaps `0 1 2 3 4 5 6 8 10 12 16`. Responsive strings and rendered attributes use the hyphenated tokens; idiomatic scalar symbols use `:row_reverse`, `:col_reverse`, and `:wrap_reverse` and normalize to them. `Grid.new(cols:, gap: 4)` accepts columns `1..12` and the same gaps. Do not add a generic utility parser, Tailwind runtime, arbitrary/custom breakpoints, max/range/container prefixes, or property values outside these lists.

## Application shells

Application shells own responsive chrome, not application policy. Every shell has exactly one navigation tree and one main region, plus optional unique brand and topbar regions. Account actions compose inside the topbar. Navigation uses named header, body, section, footer, spacer, divider, and item parts. Keep product routes and current-destination policy in the caller, and use native navigation and landmark elements.

Nitro owns the shell breakpoint, fixed/sticky placement, overscroll background, independent navigation scrolling, and narrow-screen disclosure behavior. Sidebar places brand/navigation in a sticky desktop sidebar; topbar places brand/navigation/actions in a sticky desktop header; hybrid combines sidebar navigation with the header. All three reflow the one navigation tree into the narrow drawer. Do not add arbitrary breakpoint, sticky-region, or route-registry options. Reflect open state through ARIA and `data-state`; expose a skip link and labelled landmarks; trap, move, and restore focus for the narrow drawer; close on Escape, backdrop, outside activation, and Turbo navigation; and release inert state, scroll locks, and listeners on disconnect. Visible desktop navigation must not retain drawer semantics, `inert`, or `aria-hidden`. Keep shell-specific public tokens semantic and limited to canvas/sidebar colors, border, sidebar width, and topbar height.

## Rails forms

Use Rails `form_with` from Phlex with `NitroKit::FormBuilder`:

```ruby
form_with(model:, builder: NitroKit::FormBuilder) do |form|
  form.field(:email)
  form.submit
end
```

Keep Rails naming, IDs, values, CSRF, validations, multipart behavior, and error semantics. Refactor the builder for direct Phlex; do not restore `nk_form_with` or `nk_form_for`.

Default form composition uses `Fieldset` and `FieldGroup` where semantics call for them.

## Optional Rails integrations

Lexxy is Nitro Kit's preferred Action Text editor. `FormBuilder#field(as:
:rich_text)` must preserve Lexxy's native Action Text naming, hidden input,
attachments, prompts, validation, and editor behavior while providing the
ordinary Nitro Field label, description, error, theme, and layout contract.
Nitro does not fork Lexxy or own its JavaScript.

Active Storage components preserve native inputs and ordinary form submission without JavaScript. Keep upload limits and image sizes explicit and validated. File drops are an enhancement to a labelled, keyboard-operable native input; expose progress with native progress semantics and announce status and errors. Progressive images expose exactly one accessible image while placeholders remain decorative. Reflect asynchronous progress and errors through owned state and accessible native elements.

Do not add mandatory Dropzone.js, Ransack, or image-processing dependencies to Nitro Kit. A generic component may document an app-level or gallery adapter for an optional gem, but Nitro must not absorb that gem's query, route, or authorization policy.

## Stimulus and Hotwire

Native HTML and CSS own behavior when they already provide the required semantics. Stimulus adds the smallest missing enhancement.

- Prefer `details`/`summary` for disclosure, declarative `command`/`commandfor` for dialogs, native Popover for dropdown visibility, and CSS hover/focus for tooltips. Before making one authoritative, verify that it covers `docs/browser_support.md` or pair it with the smallest capability-detected fallback.
- Do not mirror browser-owned open state into `data-state`, `aria-expanded`, or hidden attributes. Use targets and values only for state Nitro genuinely owns.
- The exception is state HTML cannot express as an attribute at all. A checkbox's `indeterminate` is a DOM property with no markup form, so `Checkbox` mounts `nk--checkable` only when `indeterminate: true`, and that controller's whole scope is applying the property and owning the matching `data-state="indeterminate"`. Ordinary checked state stays native, with no controller and no mirrored `data-state`. Do not widen a controller past the one state the browser cannot express.
- Keep native state selectors such as `[open]` and `:popover-open` authoritative in CSS.
- Clean up every external listener, timer, observer, and other resource in `disconnect`.
- Avoid duplicate initialization through Turbo morphs.
- Test keyboard behavior and Turbo Drive/Frame/Stream/morph lifecycles.

## Interface quality

- Omit `variant:` for ordinary actions so `Button` uses its `:default` treatment. Reserve `:ghost` for deliberately low-emphasis interface chrome such as compact dismiss, pagination, toolbar, and shell-navigation controls; it is not a generic secondary-action style.
- Headings use balanced wrapping; short descriptions use pretty wrapping.
- Dynamic numeric columns use tabular numerals.
- Interactive hit areas are at least 40×40px without overlapping.
- Use concentric radii for closely nested surfaces.
- Prefer subtle layered shadows for elevated surfaces and borders for true separators/form outlines.
- Interactive transitions are interruptible and declare exact transitioned properties.
- Respect `prefers-reduced-motion`.
- Use `will-change` only after observing a compositing problem.

## Testing checklist

Every component includes:

- Direct-Phlex rendering coverage.
- Every option and invalid value.
- Reserved attribute rejection.
- Class escape output.
- Structural and component-specific accessibility assertions.
- A gallery combination page with meaningful permutations.
- Long, missing optional, disabled, validation/error, dark, and narrow-width examples where relevant.
- Behavior tests for interactive components.

The gallery uses explicit Phlex page classes and `Gallery::Catalog`. Do not add ERB component examples or infer routes from filenames. Every `Gallery::Example` pairs Preview and Code tabs. Keep the preview in the block passed to the gallery helper so `Gallery::SourceCode` can extract, highlight, and copy its executable Ruby body; use a concrete method source for inherited flow wrappers instead of duplicating snippets.

Complete application examples combine shells, navigation, forms, tables, uploads, images, and overlays in sidebar, topbar, and hybrid layouts. Appearance coverage includes zero, one, and multiple pickers; light, dark, cross-tab updates, and live system preference changes. Theme coverage proves the contract rather than a tool: the documented token set, the set declared in `tokens.css`, and the set the bundled stylesheet serves are the same set, component CSS consumes only declared public tokens, and scoped `--nk-*` overrides on an application-owned wrapper reach Nitro descendants through inheritance.

Ship a public customization guide and align the README and Rails integration docs whenever appearance, theme tokens, or shell composition changes. Document token load order, scoped light/dark overrides, CSP setup, customizer-export installation, and copyable Phlex examples; architecture notes alone are not user documentation.

Browser verification may live outside Minitest, but it must enumerate the explicit gallery catalog, prove code-source parity and escaping, and exercise interactive behavior through Turbo lifecycles.

## Component completion checklist

- Explicit public options.
- Enumerated options validated.
- Stable `data-nk` root.
- Component-qualified slots.
- Static CSS source and generated bundle updated.
- No internal class/style output.
- No Tailwind runtime assumption.
- Direct-Phlex tests and gallery examples.
- Rails/Hotwire behavior preserved where applicable.
- Relevant `tk` ticket updated with verification notes.
