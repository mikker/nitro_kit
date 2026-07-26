# Nitro Kit 2.0 — agent-native Phlex UI system

This is the canonical architecture specification for the Nitro Kit 2.0 prerelease line. The delivery sequence and ticket map are retained in [`implementation_plan.md`](implementation_plan.md) as design history; `tk` is the source of truth for live work status. [`component_contracts.md`](component_contracts.md) records the shipped Ruby and integration contracts.

Nitro Kit is a gem-owned, versioned UI system for Rails. Developers and coding agents compose application interfaces in Ruby with Phlex. Nitro Kit owns component behavior, rendered structure, and default aesthetics. Applications own product code and documented theme overrides, not copies of Nitro Kit internals.

## Product contract

### Nitro Kit owns the system

Nitro Kit owns and versions:

- Component Ruby and public initializer and compound-method APIs.
- Rendered `data-nk`, `data-slot`, state, and ARIA contracts.
- Static component CSS, the default themes, and public `--nk-*` tokens.
- Light, dark, and system appearance selection and persistence.
- Stimulus behavior and Rails engine integration.
- Layout primitives, blocks, application shells, canonical examples, and tests.

Applications may:

- Override documented `--nk-*` custom properties.
- Select a Nitro-owned light, dark, or system appearance.
- Compose Nitro components into application-specific components.
- Subclass a component when composition is insufficient, accepting that private methods and internal records are not API.
- Use `desperately_need_a_class:` when an external integration genuinely requires a class.

Core components load from the gem. Generated-copy installation and the promise that applications should edit Nitro source are retired.

### Phlex is the composition language

Direct component construction is the canonical API:

```ruby
render NitroKit::Button.new("Save", variant: :primary)
```

Compound components expose ordinary Ruby methods:

```ruby
render NitroKit::Card.new do |card|
  card.title("Workspace")
  card.body { render WorkspaceSummary.new }
end
```

Fixed-order page blocks accept their textual regions in either concise constructor form or deferred compound form:

```ruby
render NitroKit::EmptyState.new(level: 3) do |empty|
  empty.title { plain "No records for "; strong { "Production" } }
  empty.description("Remove one or more filters and try again.")
end
```

The two forms are mutually exclusive for each region. Required content may be satisfied by either form, and deferred blocks may render arbitrary Phlex content without changing the component-owned DOM order.

Nitro Kit does not provide `nk_*` ERB helpers, generated variant helpers, `from_template`, conditional builder capture, or general template-buffer bridges.

Rails remains first-class where Rails owns meaningful semantics:

- Model-backed forms and `ActionView::Helpers::FormBuilder` behavior.
- Route and URL generation.
- DOM IDs, translations, assets, and Active Storage.
- Turbo Frames, Turbo Streams, and related Hotwire helpers.

Applications include the `Phlex::Rails::Helpers::*` adapters they actually use. Nitro Kit does not recreate Rails helpers under an `nk_*` namespace.

## Consistency boundary

The initial correctness layer is explicit Ruby APIs and immediate component validation, not a generalized page linter.

Components fail for:

- Unknown variants, sizes, placements, alignments, types, and other closed values.
- Missing required content or slots.
- Invalid slot combinations and cardinalities the component can know.
- Attempts to replace reserved Nitro identity or state attributes.
- Direct `class:` or `style:` arguments.

This guarantees use of Nitro Kit's public vocabulary. It does not claim to prove whole-page information architecture, aesthetics, heading quality, or emphasis.

### Public attributes

Common element semantics may be first-class keywords: `id:`, `href:`, `type:`, `name:`, `value:`, `disabled:`, `required:`, and similar.

Less common native attributes use explicit boundaries:

- `html:` for ordinary attributes.
- `aria:` for ARIA attributes.
- `data:` for non-reserved application data and additive Stimulus controllers/actions.

`data-nk`, `data-slot`, `data-variant`, `data-size`, `data-state`, and `data-nk-escape` are reserved. Application `data-controller` and `data-action` values compose with component-owned values; other owned-data collisions raise.

### Class escape hatch

Nitro components never emit or depend on classes. The only exception is:

```ruby
NitroKit::Button.new(
  "Third-party integration",
  desperately_need_a_class: "external-widget-trigger"
)
```

It emits both the requested class and `data-nk-escape="class"`. Blank and non-string values raise. Nitro-owned components, blocks, and examples do not use the escape. Legitimate application content enters through named compound methods or normal Phlex composition.

## Architecture

Nitro Kit has three ownership surfaces:

1. **Behavior** — Nitro-owned Stimulus controllers and native browser behavior.
2. **Structure** — Nitro-owned Phlex atoms, layouts, blocks, and application shells.
3. **Aesthetics** — Nitro-owned static CSS driven by public custom properties.

The surfaces are distinct but coordinated. Behavior and CSS rely on the rendered structure, while applications interact through Ruby constructors, compound methods, and theme variables.

### Self-describing markup

Every visual root has a stable identity:

```html
<button data-nk="button" data-variant="primary" data-size="md"></button>
```

Owned parts use component-qualified slots:

```html
<div data-nk="field">
  <label data-slot="field-label">Email</label>
  <input data-nk="input" data-slot="field-control" />
  <p data-slot="field-description">Used for receipts.</p>
</div>
```

Native elements remain native. Nitro reflects application-owned state through ARIA and `data-state`; it does not mirror state already owned by a native disclosure, dialog, or popover. Slot selectors are scoped to their owner and use direct relationships where practical.

## Shipped structure vocabulary

The authoritative initializer, root, closed-option, and cardinality inventory lives in [`component_contracts.md`](component_contracts.md).

The prerelease contains 36 atoms and components:

- Actions, display, and navigation: Alert, AppNavigation, Avatar, AvatarStack, Badge, Button, ButtonGroup, Icon, Pagination.
- Forms: AppearancePicker, Checkbox, CheckboxGroup, Datepicker, Dropzone, Field, FieldGroup, Fieldset, Input, Label, RadioButton, RadioButtonGroup, Select, Switch, Textarea.
- Structured content and interaction: Accordion, Card, Combobox, DetailsTable, Dialog, Dropdown, ProgressiveImage, Table, Tabs, Toast, Tooltip.

The non-visual `AppearanceBootstrap` installs the shared document appearance runtime.

### Native interaction authority

Nitro uses current evergreen HTML primitives as the source of truth before adding JavaScript:

- Accordion items are native `details`/`summary` disclosures. Single mode uses one shared `name`; it has no controller or disabled-item abstraction.
- Dialog declarations produce exactly one native panel in fixed order. `command="show-modal"` and `command="close"` controls target it through `commandfor`; `nonmodal: true` is the only server-rendered open mode. The component does not promise light dismiss.
- Dropdown visibility and invoker state belong to `popover="auto"`. Its small controller only supplies menu focus and keyboard navigation. CSS anchor positioning follows the trigger when supported and otherwise centers the menu safely in the viewport.
- Tooltip visibility belongs to CSS hover and focus selectors, including a hoverable bridge across the visual gap. Its controller only implements Escape dismissal and reset.

These components do not synchronize browser state into redundant `data-state` or explicit ARIA attributes. JavaScript fills semantic interaction gaps without replacing native ownership.

Three layout primitives are public:

- `Flex(dir:, gap: 4, align: :start, justify: :start, wrap: :nowrap)`
- `Grid(cols:, gap: 4)`
- `Container(size:)`

`Flex` replaces the former `VStack` and `HStack` components. `dir:` is required and accepts `row`, `col`, `row-reverse`, or `col-reverse`. Alignment accepts `start`, `center`, `end`, `stretch`, or `baseline`; justification accepts `start`, `center`, `end`, `between`, `around`, or `evenly`; wrapping accepts `nowrap`, `wrap`, or `wrap-reverse`. Responsive strings and rendered attributes use those hyphenated tokens; idiomatic Ruby scalar symbols use `:row_reverse`, `:col_reverse`, and `:wrap_reverse` and normalize to them. `Grid` accepts `1..12` columns. Both layouts accept gaps `0`, `1`, `2`, `3`, `4`, `5`, `6`, `8`, `10`, `12`, and `16`.

Every Flex and Grid property accepts a scalar or a property-scoped responsive string:

```ruby
render NitroKit::Flex.new(
  dir: "col md:row",
  gap: "3 md:6",
  align: "stretch md:center",
  justify: "start md:between"
) do
  render WorkspaceSummary.new
  render WorkspaceActions.new
end

render NitroKit::Grid.new(cols: "1 sm:2 lg:3", gap: "3 lg:6") do
  records.each { |record| render RecordCard.new(record) }
end
```

Each string follows `BASE sm:VALUE md:VALUE lg:VALUE xl:VALUE 2xl:VALUE`. The unprefixed base is required and applies mobile-first. The fixed minimum-width prefixes are `sm` 40rem, `md` 48rem, `lg` 64rem, `xl` 80rem, and `2xl` 96rem. Inputs normalize to base then breakpoint order; the corresponding `data-dir`, `data-gap`, `data-align`, `data-justify`, `data-wrap`, or `data-cols` attribute preserves that normalized string. Duplicate or unknown prefixes, missing base values, and values outside the property's closed vocabulary raise `ArgumentError`.

This is a small typed layout API, not a general utility language. Nitro does not parse Tailwind classes, require Tailwind at runtime, accept arbitrary or customizable breakpoints, support max/range/container prefixes, or expose arbitrary CSS values.

Eleven blocks and shells were extracted:

- `AuthShell`
- `AppShell`
- `SettingsLayout`
- `Toolbar`
- `PaginationBar`
- `PageHeader`
- `StatGrid`
- `DataSection`
- `FormSection`
- `DangerZone`
- `EmptyState`

These are intentionally a small vocabulary rather than a general page framework. Product state, routes, authorization, domain policy, and copy remain application-owned.

## Shipped 2.0 additions

The following additions ship in the 2.0 prerelease. Their exact public constructors and compound cardinalities are recorded in [`component_contracts.md`](component_contracts.md). Existing Nitro ownership, validation, classless markup, CSS, and testing rules apply without exception.

### Appearance

Nitro Kit owns the complete light, dark, and system appearance lifecycle. Applications render the bootstrap in `head` before stylesheet links, then place the appearance control wherever appearance is selected:

```ruby
render NitroKit::AppearanceBootstrap.new(
  default: :system,
  nonce: content_security_policy_nonce
)

render NitroKit::AppearancePicker.new(
  id: "workspace-appearance",
  label: "Appearance"
)
```

`AppearanceBootstrap` is a non-visual, gem-owned script component. Its `default:` accepts only `:light`, `:dark`, or `:system`; `nonce:` supports the host's Rails content-security policy. Its JavaScript body is fixed and hashable; `default` is read from a data attribute rather than interpolated into the body. The documented stable hash and the optional nonce therefore support the two ordinary Rails CSP strategies.

The bootstrap installs one idempotent document runtime before CSS-visible paint. That runtime reads and validates `nitro-kit-appearance`, writes `data-theme-preference` plus effective `data-theme="light|dark"`, owns the single `matchMedia` listener, listens for cross-tab storage changes, and broadcasts one appearance-change event. It exists when a page has zero pickers and is not duplicated when a page has several. Storage denial or malformed data falls back to `default:` without throwing or blocking the page.

`AppearancePicker` reads the initialized document preference. Segmented and radio presentations use a `fieldset`, select uses a labelled native `select`, and dropdown uses an icon-only sun or moon trigger with labelled Light, Dark, and System menu buttons. Its `nk--appearance` controller only requests preference changes and synchronizes controls from runtime events. Any number of pickers remain in sync. Native inputs remain labelled and operable without custom pointer behavior, the dropdown composes Nitro's native Popover menu, and each picker releases its subscription on disconnect.

CSS supplies a system-color fallback if the bootstrap cannot run. Appearance initialization must not flash a persisted explicit choice or leave an incorrect selection. Tests cover zero, one, and multiple pickers; system and cross-tab changes; repeated bootstrap execution; Turbo removal and reconnection; denied and malformed storage; and both documented CSP modes. Nitro does not synchronize preferences to a user record; applications may do that separately.

### Application shell and navigation

`AppShell` absorbs the former Pro Sidebar and Top Navigation concepts without copying an application layout:

```ruby
render NitroKit::AppShell.new(id: "workspace", layout: :sidebar) do |shell|
  shell.brand { render ProductMark.new }
  shell.navigation do
    render NitroKit::AppNavigation.new(label: "Primary") do |navigation|
      navigation.body do
        navigation.section do
          navigation.item("Dashboard", href: dashboard_path, current: true)
          navigation.item("Projects", href: projects_path)
        end
      end
    end
  end
  shell.topbar { render AccountActions.new }
  shell.main { render DashboardPage.new }
end
```

Every `AppShell` layout requires exactly one `navigation` and one `main`; `brand` and `topbar` are optional and unique. `:sidebar` places brand and navigation in a sticky, independently scrolling desktop sidebar and uses a compact mobile topbar for brand, disclosure, and optional topbar actions. `:topbar` places brand, the same navigation tree, and optional actions in a sticky desktop header, then reflows that navigation into the narrow drawer. `:hybrid` uses the sidebar placement plus a sticky desktop topbar. Product routes, authorization, current-destination policy, page titles, and copy remain application-owned.

The root is `div[data-nk="app-shell"][data-variant]`. Owned regions use the qualified slots `app-shell-skip-link`, `app-shell-header`, `app-shell-brand`, `app-shell-sidebar`, `app-shell-navigation`, `app-shell-topbar`, `app-shell-main`, `app-shell-backdrop`, `app-shell-mobile-trigger`, and `app-shell-mobile-close`. The semantic header groups brand, mobile disclosure, and topbar actions. The drawer wrapper is neutral because its nested `AppNavigation` is already the landmark. One navigation DOM tree is reflowed, never cloned. `AppNavigation` renders `nav[data-nk="app-navigation"]` with optional unique `header` and `footer` regions around one required `body`. The body preserves caller order across repeatable `section`, `divider`, and `item` entries and at most one `spacer`. A current item uses native `aria-current="page"` plus visible Nitro state.

The shell owns a minimum full-viewport canvas and overscroll color; sticky sidebar/topbar positioning; independent navigation overflow; and an unconstrained main region in which the application may render `Container`. The `nk--app-shell` controller owns only narrow-screen disclosure. Off-canvas hiding begins only after it marks the shell `data-enhanced`, so narrow no-JavaScript pages retain visible navigation. While open at narrow width, the neutral wrapper receives dialog semantics and an accessible label; its labelled close control, focus trap, and inert background chrome keep interaction bounded. It reflects open state through `data-state`, `aria-expanded`, and narrow-only `aria-hidden`. It closes on its control, Escape, backdrop activation, outside activation, and Turbo navigation, restores focus to the trigger, and releases the dialog label, narrow ARIA, inert state, listeners, and scroll locks on disconnect or desktop resize. Desktop navigation never retains drawer semantics or an inapplicable accessible name. Nitro owns the responsive breakpoint; no public arbitrary-breakpoint option is added.

Shells initially add `--nk-app-shell-sidebar-width`, `--nk-app-shell-topbar-height`, `--nk-app-shell-background`, `--nk-app-shell-sidebar-background`, `--nk-app-shell-sidebar-foreground`, `--nk-app-shell-sidebar-accent`, `--nk-app-shell-sidebar-accent-foreground`, and `--nk-app-shell-border`. Other styling consumes existing spacing, shadow, motion, and content-width tokens.

### Former Pro capabilities

Former Pro source is reference material, not migration input. Accepted capabilities are rebuilt as gem-owned Phlex components:

- `DetailsTable` composes the existing `Table`. `DetailsTable.new(record, route_base: nil)` exposes `field(attribute, label: nil, value: UNSET)` and `fields(*attributes)`. A field block receives the resolved value and owns its rendered value. Explicit `nil` is distinct from an omitted value. Automatic Rails value rendering is deterministic and tested; applications can always supply content explicitly.
- `ProgressiveImage.new(attachment:, alt:, size: :md, decorative: false)` accepts only `sm`, `md`, and `lg` sizes. It renders `div[data-nk="progressive-image"]` with qualified placeholder, image, and fallback slots and states `empty`, `loading`, `loaded`, and `error`. Non-decorative attached images require useful alt text. Its controller owns image decoding and load/error reflection, removes listeners on disconnect, and mutates state rather than classes.
- `Dropzone.new(id:, name:, title: "Upload files", description: nil, direct_upload: true, multiple: false, accept: nil, max_files: 1, max_bytes: nil, disabled: false, required: false)` renders a native file input inside `div[data-nk="dropzone"]`. It exposes idle, drag, uploading, success, error, and disabled states; qualified input, message, preview-list, progress, error, and remove-control slots; and ordinary form submission when JavaScript is unavailable. The Nitro controller integrates Active Storage direct uploads, cancellation, removal, form submission state, and Turbo teardown. Nitro does not ship or require Dropzone.js and does not expose a raw JavaScript options hash.
- `Table.new(sort: nil, direction: nil)` exposes sortable headers through `th(text = nil, sort:, href:, sort_data: {}, align: :left)`. Directions are `asc`, `desc`, or `nil`; the application supplies URLs and owns sort policy. The active header renders native `aria-sort` and a direction icon; sortable but inactive headers render `aria-sort="none"` and a neutral icon. The shipped gallery recipe adapts `Ransack::Search` to this API while keeping filter allowlists and pagination policy in application code; Ransack is a development/test dependency only, not a Nitro runtime dependency, and `NitroKit::RansackTable` is not a core contract.

`DetailsTable` and sortable `Table` headers require no Nitro JavaScript. `ProgressiveImage` requires Active Storage variants and the host application's configured image processor. `Dropzone` requires Active Storage direct-upload support. These integrations do not add mandatory Ransack, Dropzone.js, or image-processing gems to Nitro Kit itself.

The audited former-Pro catalog maps completely to the new architecture:

| Former surface                                           | 2.0 disposition                                                                                                                               |
| -------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| Sidebar and Top Navigation layouts                       | Rebuilt as `AppShell` layouts and gallery application compositions                                                                            |
| Details Table                                            | Rebuilt as `DetailsTable`                                                                                                                     |
| Dropzone                                                 | Rebuilt as native `Dropzone`; Dropzone.js is removed                                                                                          |
| Progressive Image                                        | Rebuilt as `ProgressiveImage`                                                                                                                 |
| Ransack Table                                            | Generic sortable `Table` plus an optional gallery Ransack recipe                                                                              |
| Currency Field                                           | Deliberately omitted: it was an unpublished stub with an unused `cents` option and no settled locale, precision, or submitted-value semantics |
| Download helpers, installers, and whole-layout templates | Removed; they contradict gem ownership and direct Phlex composition                                                                           |

### Customization and the wizard

The customization contract remains documented public custom properties. Applications override public `--nk-*` variables in their own CSS, scoped globally or beneath an application-owned theme root. They do not replace Nitro markup, edit generated distribution CSS, or depend on private `--_nk-*` variables.

The gallery ships an interactive customization wizard at `/gallery/customize`. Its immutable `Gallery::ThemePreset` value object has `VERSION = 1` and these closed choices: `accent` is `blue indigo violet rose amber emerald neutral` (default `blue`); `neutral` is `slate gray zinc neutral stone` (default `zinc`); `radius` is `none sm md lg` (default `md`); `density` is `compact comfortable` (default `comfortable`); `font` is `system humanist serif mono` (default `system`); and `shell` is `sidebar topbar hybrid` (default `sidebar`). It maps each choice deterministically to documented tokens and preview composition. Unknown versions or choices produce a visible validation error and fall back to defaults rather than evaluating arbitrary input.

Shareable URLs use the readable parameters `v`, `accent`, `neutral`, `radius`, `density`, `font`, and `shell`. Edits call `history.replaceState`; `popstate` restores controls and preview. A separate preview-appearance control selects light, dark, or live system resolution without changing the visitor's saved appearance and is not serialized into the preset. Reset restores the versioned defaults. Copy CSS emits `:root, [data-theme="light"]`, then the no-JavaScript system-dark scope `@media (prefers-color-scheme: dark) { :root:not([data-theme]) { … } }`, then explicit `[data-theme="dark"]`, with public declarations in stable lexical order and no unchanged or private tokens. Because `shell` is structural rather than a token, the wizard also generates a copyable `AppShell` Ruby composition for the selected layout.

The preview includes atoms, forms, overlays, tables, the application shell, and accepted former Pro components so token changes are evaluated as a system. Controls remain labelled and keyboard-operable; swatches include text; the preview precedes a compact horizontally scrollable control strip on narrow screens; and copy success or failure is announced through a polite live region.

The wizard and `Gallery::ThemePreset` are gallery documentation infrastructure, not packaged gem APIs, a public registry, a general token schema, a marketplace, an arbitrary CSS editor, or a component generator. They never write project files and never emit helpers, copied components, Tailwind configuration, or private tokens.

### Addition verification contract

Every addition receives direct Ruby contract tests, invalid-vocabulary tests, accessibility assertions, deterministic CSS coverage, and catalog-driven browser coverage. Interactive components exercise keyboard input, narrow and wide layouts, reduced motion, Turbo Drive/Frame/Stream/morph lifecycles, disconnect cleanup, and repeated connection. Appearance coverage begins at a cold document load and proves pre-paint restoration, nonce and hash CSP rendering, denied storage, malformed storage, persistence, zero and multiple pickers, cross-tab updates, and live system changes.

`Dropzone` associates its native input, description, errors, and live status; exposes native progress semantics; supports keyboard selection and `direct_upload: false`; and keeps ordinary form submission usable without JavaScript. `ProgressiveImage` exposes exactly one accessible image while its placeholder is decorative; its fallback communicates an actual empty or error state without duplicating alt text. `AppShell` supplies a skip link and one identifiable main landmark, labels navigation, gives the narrow drawer modal/inert semantics, and preserves a logical focus order.

The gallery includes, at minimum, sidebar, topbar, and hybrid application flows; appearance persistence and simulated system changes; every former Pro state; long and missing content; upload success, error, cancellation, and removal; progressive-image empty, loading, loaded, and failed states; and sortable-table gallery empty and populated results. Every example uses `Gallery::Example` Preview and Code tabs whose source is extracted from the executable Phlex block or concrete flow method. Combination pages deliberately mix shells, forms, tables, uploads, images, overlays, and all three appearances.

Public documentation includes `docs/customization.md` plus aligned README and Rails-integration sections. It catalogs supported tokens, stylesheet load order, global and scoped overrides, light/dark selectors, appearance bootstrap and picker setup, CSP nonce/hash configuration, installing wizard exports, shell composition, and complete copyable Rails examples.

`docs/agent_guide.md` is the packaged routing layer for coding agents. It points to version-matched Rails conventions, component contracts, Hotwire guidance, and recipes for queryable collections, resource forms, destructive actions, flash/toast feedback, and inline editing. The packaged plugin contains consumer Rails, UI, and Hotwire skills that resolve the installed gem before reading these docs. The setup generator installs the same thin routers into supported project-local skill directories and maintains a bounded `AGENTS.md` block. It does not duplicate the component registry or add an MCP server.

## CSS and themes

Nitro Kit ships `nitro_kit.css` as browser-ready plain CSS with no Tailwind requirement.

Internal cascade order is deterministic:

```text
nitro-kit.tokens
nitro-kit.reset
nitro-kit.base
nitro-kit.variant
nitro-kit.size
nitro-kit.state
nitro-kit.compound
```

Selectors use `:where()` for zero authored specificity. The reset is scoped to Nitro roots and owned parts and does not reset arbitrary application content.

Public `--nk-*` variables cover semantic colors, the component-specific raised default-button treatment, typography, spacing, radii, border and focus geometry, shadows, motion, control heights, and content widths. Private `--_nk-*` variables coordinate component mechanics and are not theme API.

The exact browser order is optional `nitro_kit-tailwind-v4.css`, generated `nitro_kit.css`, compiled Tailwind CSS when present, then unlayered application styles containing token overrides. Applications never edit the generated asset. [`customization.md`](customization.md) is the complete public token inventory and usage guide.

Before JavaScript connects, `:root` follows `prefers-color-scheme`; explicit `[data-theme="light"]` and `[data-theme="dark"]` contracts override it and set the matching `color-scheme`. `nk--appearance` keeps `data-theme` equal to the effective light or dark appearance and records the selected light, dark, or system preference separately. Applications override the same public variables for both theme contracts.

`nitro_kit-tailwind-v4.css` is an optional, separately versioned adapter. It establishes layer order and maps theme variables. Tailwind compilation, source detection, and utilities remain application concerns, not Nitro runtime dependencies.

## Layout sizing

Parents own external placement and available width. Components own intrinsic geometry.

Inputs, textareas, selects, tables, and broad surfaces may stretch naturally. Buttons, badges, avatars, icons, and switches remain intrinsic unless an accepted layout explicitly stretches them.

## Rails and Hotwire

`NitroKit::FormBuilder` is selected through Rails `form_with` from Phlex. It preserves Rails naming, IDs, model values, values-before-type-cast, Active Model errors, multipart forms, checkbox hidden values, and captured select options.

Turbo Frames and Turbo Streams remain Rails helpers used directly from Phlex. Invalid submissions return 422; successful non-Turbo form submissions redirect with 303. The supported boundary and executable reference path are documented in [`rails_integration.md`](rails_integration.md).

The engine ships CSS assets and Nitro-owned Stimulus controllers for enhancements that native HTML and CSS do not cover. When importmap is present it adds its pins automatically; the host still owns Stimulus and its normal controller loader. The engine boots without importmap: Accordion and Dialog remain complete, while enhanced interactions such as Dropdown keyboard navigation and Tooltip Escape dismissal require their pinned controllers. This prerelease does not define a JavaScript-package entrypoint for automatic bundler registration.

Datepicker and Switch deliberately use native inputs rather than custom controllers. No third-party JavaScript runtime is vendored.

## Examples and verification

The dummy Rails application is the canonical example gallery. An explicit `Gallery::Catalog` drives routes for component pages, block pages, and realistic application flows. That catalog is documentation infrastructure, not a packaged public registry.

Examples cover closed options, content pressure, native state, validation, empty/error/loading/destructive states, light and dark themes, narrow and wide layouts, and interaction between forms, navigation, tables, and overlays.

Examples also cover system appearance, complete application shells, the customization wizard, former Pro capabilities, and dense cross-component combinations. Previewed Ruby and copied Ruby remain the same executable source.

Primary verification remains:

- Direct-Phlex render and contract tests.
- Invalid vocabulary and reserved-attribute tests.
- Rails request/integration tests.
- Deterministic CSS build and package audits.
- Catalog-driven browser behavior and Turbo-lifecycle verification.

## Explicitly outside the prerelease

The following are not current contracts:

- Generated component copies or compatibility helpers.
- A public registry, JSON Schema, document linter, MCP server, or custom-element runtime.
- `Spacer`, `Split`, or `Frame` layout primitives.
- `MarketingShell` or `AuthenticationPanel` shells.
- `ProgressSteps` or speculative domain blocks.
- Card/Table density, radio-group orientation, arbitrary grid tracks, custom breakpoints, max/range/container queries, or a generic utility DSL.
- Theme marketplaces, remote preset registries, arbitrary CSS editing, or visual-regression goldens.
- Downloadable installers, generated helpers, copied components, or copied application layouts.
- `CurrencyField` in this expansion wave.

These ideas require new evidence and a deliberate future API decision. Their appearance in design notes or historical plans does not make them public.

## Design history

The pivot was delivered in evidence-seeking stages: establish the kernel and representative vertical slice, migrate atoms, build atom-only product flows, record repeated friction, extract only proven layouts and blocks, expand the gallery, remove 1.x, then consolidate behavior, packaging, and documentation.

The first evidence pass rejected more abstractions than it accepted. `Spacer`, `Split`, `Frame`, App/Marketing shells, AuthenticationPanel, and ProgressSteps stayed out because those flows did not establish a stable cross-domain responsibility. That pass initially extracted separate `VStack` and `HStack` components plus a fixed three-column Grid. The later responsive-layout consolidation superseded those APIs with unified `Flex` and responsive `Grid`; [`notes/block_candidates.md`](../notes/block_candidates.md) retains the original evidence as history. The application-layout mandate and the Sidebar and Top Navigation reference audit supplied enough repeated responsibility to approve `AppShell`; MarketingShell, AuthenticationPanel, and speculative layout primitives remain rejected.

## Definition of done

The 2.0 architecture is release-ready when:

- Core components are gem-owned and composed directly through Phlex.
- Generated copies, ERB component helpers, Tailwind Merge, and consumer Tailwind dependence are absent.
- Every visual component emits classless, self-describing markup and uses static Nitro CSS.
- Rails forms and Hotwire work through direct Phlex composition.
- The accepted layout and block vocabulary covers the canonical flows without escape markers.
- Light, dark, and system appearance remain correct across reloads, Turbo navigation, and system changes.
- AppShell and accepted former Pro capabilities satisfy their Ruby, DOM, accessibility, dependency, and teardown contracts.
- The customization wizard previews and exports only documented public tokens.
- CSS, package, Ruby, Rails, and browser verification pass.
- Public documentation matches shipped APIs and clearly states the 1.x break.
