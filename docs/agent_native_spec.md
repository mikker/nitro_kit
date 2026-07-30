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

Two lists in `NitroKit::Component` define the boundary. `COMPONENT_OWNED_DATA_ATTRIBUTES` is `state`, `disabled`, `required`, `orientation`, `presentation`, `placement`, `layout`, and `field-type` — keys a component sets for itself through its internal `attributes:` bag. `RESERVED_DATA_ATTRIBUTES` adds `nk`, `slot`, `variant`, `size`, `nk-escape`, and `enhanced`; applications may not pass any entry in that combined list through `data:`.

Application `data-controller` and `data-action` values compose with component-owned values; other owned-data collisions raise.

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

The prerelease contains 40 atoms and components:

- Actions, display, and navigation: Alert, AppNavigation, Avatar, AvatarStack, Badge, Button, ButtonTo, ButtonGroup, CommandPalette, Icon, Pagination.
- Forms: AppearancePicker, Checkbox, CheckboxGroup, ControlGroup, Dropzone, Field, FieldGroup, Fieldset, Input, Label, RadioButton, RadioButtonGroup, RichTextArea, Select, Switch, Textarea.
- Structured content and interaction: Accordion, Card, Combobox, DetailsTable, Dialog, Dropdown, ProgressiveImage, Sheet, Table, Tabs, Toast, Tooltip, Typeset.

The non-visual `AppearanceBootstrap` installs the shared document appearance runtime, and `NitroKit::Choice` is the typed option value shared by the choice controls.

There is no Datepicker component and no date controller. `Input`'s `type: :date` is the only date control; `Field` and `FormBuilder` reach it through `as: :date`, and their CSS inherits the Safari date-editor alignment fix. `Combobox::Option` is likewise gone in favor of `Choice`.

### Native interaction authority

Nitro uses current evergreen HTML primitives as the source of truth before adding JavaScript:

- Accordion items are native `details`/`summary` disclosures. Single mode uses one shared `name`; it has no controller or disabled-item abstraction.
- Dialog declarations produce exactly one native panel through the required `panel(title:, description: nil, nonmodal: false)` declaration, and Nitro renders close button, title, description, then application content inside it. `command="show-modal"` and `command="close"` controls target the panel through `commandfor`; `nonmodal: true` is the only server-rendered open mode and cannot be combined with a trigger. `nk--dialog` adds only backdrop light dismissal and, for `dismissible: false`, Escape suppression.
- Dropdown visibility and invoker state belong to `popover="auto"`. `trigger` forwards `icon:`, `icon_end:`, and `label:` to Button, and `item` accepts its own `icon:`. Its small controller supplies menu focus, arrow/Home/End navigation, and focus restoration to the trigger when the popover closes with focus still inside it. CSS anchor positioning follows the trigger when supported and otherwise centers the menu safely in the viewport.
- CommandPalette uses one native dialog, a declarative search-shaped trigger, and native destination links. Its controller adds the optional Command-K/Control-K shortcut, local filtering, result announcements, and Turbo cleanup without replacing link navigation or retaining hidden application policy. With `search_url:`, the same input submits debounced GET requests into the owned Turbo Frame; the endpoint returns `CommandPalette::Results` HTML and remains responsible for authorization.
- Tooltip visibility belongs to CSS hover and focus selectors, including a hoverable bridge across the visual gap. Button triggers cover ordinary buttons and links; `as: :custom` forwards owned HTML, ARIA, and data to an existing focusable mutation or compound trigger. Its controller only implements Escape dismissal and reset.

These components do not synchronize browser state into redundant `data-state` or explicit ARIA attributes. JavaScript fills semantic interaction gaps without replacing native ownership.

### Variant axes

`variant:` and `size:` on a component root are its identity axes, emitted as `data-variant` and `data-size` by the base component. A slot may carry its own owned `data-variant` when the slot has variant identity of its own: `Toast::Item` is a nested component with its own root variant, and Dropdown `item` is a plain element that takes `slot_attributes(:item, variant:)`, the base component's owned slot-variant channel. Caller `data: { variant: }` stays reserved in both cases.

Each component has exactly one variant axis. `Alert` variants are `default info success warning error`, the same vocabulary as `Toast::Item`, and the tint comes from the Alert-owned `VARIANT_PALETTE`; there is no `color:` option on Alert. `Badge` keeps a separate `color:` palette axis alongside its `default outline` variants, and that palette is Badge's alone.

`Button` icons are `icon:` and `icon_end:`, matching the `button-icon` and `button-icon-end` slots. There is no `icon_right:`.

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

`AppearancePicker` reads the initialized document preference, and `preference:` renders a server-persisted choice as the initial `data-state`, checked radio, selected option, and trigger icon so a stored preference does not flash. Its root varies with `presentation:`: segmented and radio presentations render `fieldset[data-nk="appearance-picker"]`, select renders `label[data-nk="appearance-picker"]` wrapping a native `select`, and dropdown renders `div[data-nk="appearance-picker"]` around an icon-only sun, moon, or monitor trigger with icon-led Light, Dark, and System menu buttons. Its `nk--appearance` controller only requests preference changes and synchronizes controls from runtime events. Any number of pickers remain in sync. Native inputs remain labelled and operable without custom pointer behavior, the dropdown composes Nitro's native Popover menu, and each picker releases its subscription on disconnect.

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

The root is `div[data-nk="app-shell"][data-layout]`; `layout:` is the shell's structural axis and the shell has no `variant:`. Owned regions use the qualified slots `app-shell-skip-link`, `app-shell-header`, `app-shell-brand`, `app-shell-mobile-trigger`, `app-shell-topbar`, `app-shell-sidebar`, `app-shell-navigation`, `app-shell-dialog`, `app-shell-mobile-close`, and `app-shell-main`. The semantic header groups brand, mobile disclosure, and topbar actions. The narrow drawer is a real `dialog[data-slot="app-shell-dialog"]` rendered beside the sidebar, so the browser owns modal semantics; the desktop navigation wrapper stays neutral because its nested `AppNavigation` is already the landmark. One navigation DOM tree moves between the two, never cloned.

`AppNavigation` renders `nav[data-nk="app-navigation"][aria-label]` with optional unique `header` and `footer` regions around one required `body`. The body is a `ul[data-slot="app-navigation-body"]` and every entry is an `li`: `section(label: nil)` renders `li > span[data-slot="app-navigation-section-label"] + ul`, while `divider` and `spacer` each render an aria-hidden `li`. `item(text, href:, icon: nil, badge: nil, badge_color: :neutral, current: false, ...)` renders `li > a[data-slot="app-navigation-item-link"]` and carries the item's own `html:`, `aria:`, `data:`, and class escape onto that link. The body requires at least one item, at most one item is current, and a current item uses native `aria-current="page"` plus `data-state="current"` on the link.

`SettingsLayout` uses the same item vocabulary at a smaller scale: exactly one `navigation(label:)` and one `content`, where the navigation requires at least one `item(text, href:, current: false)` and renders `nav > ul[data-slot="settings-layout-items"] > li > a[data-slot="settings-layout-item-link"]`. It has no sections, dividers, spacers, icons, or badges.

The shell owns a minimum full-viewport canvas and overscroll color; sticky sidebar/topbar positioning; independent navigation overflow; and an unconstrained main region in which the application may render `Container`. The `nk--app-shell` controller owns only narrow-screen disclosure. Off-canvas hiding begins only after it marks the shell `data-enhanced`, so narrow no-JavaScript pages retain visible navigation. Opening at narrow width moves the navigation subtree into the shell's `dialog` and calls `showModal()`, so focus containment, background inertness, Escape, and the top layer are the browser's. The controller reflects open state through the root's `data-state` and the trigger's `aria-expanded` and swapped `aria-label`, and it closes on the close control, dialog cancel, backdrop activation, and Turbo navigation, returning the navigation subtree to the desktop wrapper and focus to the trigger. Disconnect and desktop resize restore the no-JavaScript tree and drop `data-enhanced`. Desktop navigation never retains drawer semantics or an inapplicable accessible name. Nitro owns the responsive breakpoint; no public arbitrary-breakpoint option is added.

Shells initially add `--nk-app-shell-sidebar-width`, `--nk-app-shell-topbar-height`, `--nk-app-shell-background`, `--nk-app-shell-sidebar-background`, `--nk-app-shell-sidebar-foreground`, `--nk-app-shell-sidebar-accent`, `--nk-app-shell-sidebar-accent-foreground`, and `--nk-app-shell-border`. Other styling consumes existing spacing, shadow, motion, and content-width tokens.

### Former Pro capabilities

Former Pro source is reference material, not migration input. Accepted capabilities are rebuilt as gem-owned Phlex components:

- `DetailsTable` composes the existing `Table`. `DetailsTable.new(record, route_base: nil)` exposes `field(attribute, label: nil, value: UNSET)` and `fields(*attributes)`. A field block receives the resolved value and owns its rendered value. Explicit `nil` is distinct from an omitted value. Automatic Rails value rendering is deterministic and tested; applications can always supply content explicitly.
- `ProgressiveImage.new(attachment:, alt:, size: :md, decorative: false)` accepts only `sm`, `md`, and `lg` sizes. It renders `div[data-nk="progressive-image"]` with qualified placeholder, image, and fallback slots and states `empty`, `loading`, `loaded`, and `error`. Non-decorative attached images require useful alt text. Its controller owns image decoding and load/error reflection, removes listeners on disconnect, and mutates state rather than classes.
- `Dropzone.new(id:, name:, label:, description: nil, direct_upload: true, multiple: false, accept: nil, max_files: 1, max_bytes: nil, disabled: false, required: false)` renders a native file input inside `div[data-nk="dropzone"]`. `label:` is the visible prompt and defaults from the `nitro_kit.dropzone` locale scope; it replaced the former `title:` keyword. It exposes idle, drag, uploading, success, error, and disabled states; qualified input, message, preview-list, progress, error, and remove-control slots; and ordinary form submission when JavaScript is unavailable. The Nitro controller integrates Active Storage direct uploads, cancellation, removal, form submission state, and Turbo teardown. Nitro does not ship or require Dropzone.js and does not expose a raw JavaScript options hash.
- Sorting is part of `Table` itself; there is no separate `SortableTable` component. `Table.new(sort: nil, direction: nil)` exposes sortable headers through `th(text = nil, align: :left, scope: :col, sort: nil, href: nil, sort_data: {})`. `sort:` and `direction:` are both set or both nil, directions are `asc` or `desc`, sort keys must be unique, `href:` requires `sort:`, and an omitted header text falls back to the humanized sort key. The application supplies URLs and owns sort policy. The active header renders native `aria-sort` and a direction icon; sortable but inactive headers render `aria-sort="none"` and a neutral icon. The shipped gallery recipe adapts `Ransack::Search` to this API while keeping filter allowlists and pagination policy in application code; Ransack is a development/test dependency only, not a Nitro runtime dependency, and `NitroKit::RansackTable` is not a core contract.

`DetailsTable` and sortable `Table` headers require no Nitro JavaScript. `ProgressiveImage` requires Active Storage variants and the host application's configured image processor. `Dropzone` requires Active Storage direct-upload support. These integrations do not add mandatory Ransack, Dropzone.js, or image-processing gems to Nitro Kit itself.

The audited former-Pro catalog maps completely to the new architecture:

| Former surface                                           | 2.0 disposition                                                                                                                               |
| -------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| Sidebar and Top Navigation layouts                       | Rebuilt as `AppShell` for whole-application navigation and `Sheet` for contextual narrow panels                                                |
| Details Table                                            | Rebuilt as `DetailsTable`                                                                                                                     |
| Dropzone                                                 | Rebuilt as native `Dropzone`; Dropzone.js is removed                                                                                          |
| Progressive Image                                        | Rebuilt as `ProgressiveImage`                                                                                                                 |
| Ransack Table                                            | Generic sortable `Table` plus an optional gallery Ransack recipe                                                                              |
| Currency Field                                           | Deliberately omitted: it was an unpublished stub with an unused `cents` option and no settled locale, precision, or submitted-value semantics |
| Download helpers, installers, and whole-layout templates | Removed; they contradict gem ownership and direct Phlex composition                                                                           |

### Customization

The customization contract remains documented public custom properties. Applications override public `--nk-*` variables in their own CSS, scoped globally or beneath an application-owned theme root. They do not replace Nitro markup, edit generated distribution CSS, or depend on private `--_nk-*` variables.

The interactive theme customizer is documentation-site software, not gallery or gem software. The gallery proves the theming contract itself: the documented token set in `docs/customization.md`, the set declared in `src/stylesheets/nitro_kit/tokens.css`, and the set served by the bundled stylesheet are asserted to be the same set; component CSS is asserted to consume only declared public tokens; and scoped `--nk-*` overrides on an application-owned wrapper are proven to reach Nitro descendants through inheritance.

### Addition verification contract

Every addition receives direct Ruby contract tests, invalid-vocabulary tests, accessibility assertions, deterministic CSS coverage, and catalog-driven browser coverage. Interactive components exercise keyboard input, narrow and wide layouts, reduced motion, Turbo Drive/Frame/Stream/morph lifecycles, disconnect cleanup, and repeated connection. Appearance coverage begins at a cold document load and proves pre-paint restoration, nonce and hash CSP rendering, denied storage, malformed storage, persistence, zero and multiple pickers, cross-tab updates, and live system changes.

`Dropzone` associates its native input, description, errors, and live status; exposes native progress semantics; supports keyboard selection and `direct_upload: false`; and keeps ordinary form submission usable without JavaScript. `ProgressiveImage` exposes exactly one accessible image while its placeholder is decorative; its fallback communicates an actual empty or error state without duplicating alt text. `AppShell` supplies a skip link and one identifiable main landmark, labels navigation, gives the narrow drawer modal/inert semantics, and preserves a logical focus order.

The gallery includes, at minimum, sidebar, topbar, and hybrid application compositions; appearance persistence and simulated system changes; every former Pro state; long and missing content; upload success, error, cancellation, and removal; progressive-image empty, loading, loaded, and failed states; and sortable-table gallery empty and populated results. Every example uses `Gallery::Example` Preview and Code tabs whose source is extracted from the executable Phlex block or concrete composition method. Combination pages deliberately mix shells, forms, tables, uploads, images, overlays, and all three appearances.

Public documentation includes `docs/customization.md` plus aligned README and Rails-integration sections. It catalogs supported tokens, stylesheet load order, global and scoped overrides, light/dark selectors, appearance bootstrap and picker setup, CSP nonce/hash configuration, shell composition, and complete copyable Rails examples.

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

Selectors use `:where()` for zero authored specificity. Nitro ships its own global, Preflight-style reset in the `nitro-kit.reset` layer and never depends on Tailwind Preflight. It normalizes the whole page, so arbitrary content inside a component gets the same baseline as Nitro's own markup, and because it is layered, unlayered application CSS always wins. `min-width: 0` and list-marker removal stay scoped to Nitro-owned elements so prose lists keep real markers.

Public `--nk-*` variables cover semantic colors, the component-specific raised default-button treatment, typography, spacing, radii, border and focus geometry, shadows, motion, control heights, and content widths. Private `--_nk-*` variables coordinate component mechanics and are not theme API.

The exact browser order is optional third-party base CSS such as Lexxy, optional `nitro_kit-tailwind-v4.css`, generated `nitro_kit.css`, compiled Tailwind CSS when present, then unlayered application styles containing token overrides. `AppearanceBootstrap` precedes every stylesheet. Applications never edit the generated asset. [`customization.md`](customization.md) is the complete public token inventory and usage guide.

Before JavaScript connects, `:root` follows `prefers-color-scheme`; explicit `[data-theme="light"]` and `[data-theme="dark"]` contracts override it and set the matching `color-scheme`. `nk--appearance` keeps `data-theme` equal to the effective light or dark appearance and records the selected light, dark, or system preference separately. Applications override the same public variables for both theme contracts.

`nitro_kit-tailwind-v4.css` is an optional, separately versioned adapter. It establishes layer order and maps theme variables. Tailwind compilation, source detection, and utilities remain application concerns, not Nitro runtime dependencies.

## Layout sizing

Parents own external placement and available width. Components own intrinsic geometry.

Inputs, textareas, selects, tables, and broad surfaces may stretch naturally. Buttons, badges, avatars, icons, and switches remain intrinsic unless an accepted layout explicitly stretches them.

## Rails and Hotwire

`NitroKit::FormBuilder` is selected through Rails `form_with` from Phlex. It preserves Rails naming, IDs, model values, values-before-type-cast, Active Model errors, multipart forms, checkbox hidden values, and captured select options.

Turbo Frames and Turbo Streams remain Rails helpers used directly from Phlex. Invalid submissions return 422; successful non-Turbo form submissions redirect with 303. The supported boundary and executable reference path are documented in [`rails_integration.md`](rails_integration.md).

Server-rendered feedback is the Rails flash. `Toast` renders `section[data-nk="toast"][role="region"]` wrapping `ol[data-slot="toast-list"]`, whose id is the toast id plus `-list`, so the default region is addressable as `nk-toast-list` and a Turbo Stream can append `NitroKit::Toast::Item` to it directly. Items carry `role="status"`, or `role="alert"` for the error variant, so a server-rendered item announces without waiting for a DOM mutation, and every item is `data-turbo-temporary` so a cached page never replays stale feedback while the region and list survive. `Toast::FlashMessages` maps an enumerable Rails flash onto the same items. Nitro does not add a client-side notification store.

The engine ships CSS assets and Nitro-owned Stimulus controllers for enhancements that native HTML and CSS do not cover. When importmap is present it adds its pins automatically; the host still owns Stimulus and its normal controller loader. The engine boots without importmap: Accordion is complete with no controller at all and Dialog still opens and closes through declarative `command`/`commandfor`, while enhanced interactions such as Dropdown keyboard navigation, Tooltip Escape dismissal, and Dialog backdrop light dismissal require their pinned controllers. This prerelease does not define a JavaScript-package entrypoint for automatic bundler registration.

Date inputs, Switch, and ordinary checked state deliberately use native inputs rather than custom controllers. The one exception is `indeterminate:`, which HTML cannot express as an attribute: `Checkbox` mounts `nk--checkable` only in that case, and the controller's whole job is to apply the native DOM property and own the matching `data-state="indeterminate"`. No third-party JavaScript runtime is vendored.

## Examples and verification

The dummy Rails application is the canonical example gallery. An explicit `Gallery::Catalog` drives routes for component pages and realistic application compositions. Components carry a subcategory (layout, navigation, forms, data, feedback, actions) that groups the sidebar; compositions are the executable whole-system tests. That catalog is documentation infrastructure, not a packaged public registry.

Examples cover closed options, content pressure, native state, validation, empty/error/loading/destructive states, light and dark themes, narrow and wide layouts, and interaction between forms, navigation, tables, and overlays.

Examples also cover system appearance, complete application shells, former Pro capabilities, and dense cross-component combinations. Previewed Ruby and copied Ruby remain the same executable source.

The gallery's three top-level pages are audience-oriented. Introduction states what the gallery is and who each surface serves. The agent guide at `/gallery/agent-guide` is the machine entry point: the composition model, how every component page is self-contained, why the system refuses `class:` and catch-all options, and the same `Gallery::AgentRules` rules every component page renders. The human guide at `/gallery/guide` explains how to read a component page, what the compositions are, and theming basics, and points to nitrokit.dev for guides, the theme customizer, and Pro. `/llms.txt` serves the agent guide as `text/plain`, rendered by `Gallery::LlmsText` from `Gallery::AgentGuide`, `Gallery::AgentRules`, and `Gallery::Catalog` — never a second copy of the text.

Every component page is self-contained for an agent that fetches only that page. After the examples it renders three reference sections outside every example canvas: the component's own row from `docs/component_contracts.md`, inline summaries of the `docs/patterns/*.md` conventions the catalog maps to that page, and the shared system rules. Each section is source-referenced and render-inlined — one copy in the source, one copy on every page. `Gallery::AgentRules` owns the rules text and reads `NitroKit::Component::RESERVED_DATA_ATTRIBUTES` and its neighbours at render time, `Gallery::Contracts` parses the shipped contract table, `Gallery::Patterns` reads each pattern document's leading `## Summary` section, and `Gallery::Catalog::PATTERNS` declares which patterns a page carries.

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

The pivot was delivered in evidence-seeking stages: establish the kernel and representative vertical slice, migrate atoms, build atom-only product flows, record repeated friction, extract only proven layouts and page sections, expand the gallery, remove 1.x, then consolidate behavior, packaging, and documentation.

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
- The documented public token set is the only theming contract, and it is verified end to end.
- CSS, package, Ruby, Rails, and browser verification pass.
- Public documentation matches shipped APIs and clearly states the 1.x break.
