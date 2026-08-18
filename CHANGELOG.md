# Changelog

## Unreleased

### Added

- Add collapsible `AppNavigation` sections: `section(label:, collapsible:
  true, expanded:)` renders native `details` and `summary` with an owned
  chevron, so groups disclose without JavaScript and open state stays on
  the native `open` attribute. Collapsible sections require a label.
- Assert the stylesheet conventions as tests. Spacing steps, geometry
  through tokens, the type and shadow scales, themeable opacity, guarded
  motion and hover, the four z-index tiers, and the destructive spellings
  are now nine architecture tests with no allowlist, so a new violation
  fails instead of accumulating. The conventions themselves are documented
  in the style guide: the spacing step set, the z-index tiers, the
  color-mix percentage vocabulary, and the single deliberate easing curve.
- Add `--nk-icon-size-{xs,sm,md,lg,xl}` and `--nk-avatar-size-{xs,sm,md,lg}`.
  The Icon and Avatar ladders were literals repeated across five files;
  AvatarStack duplicated the entire avatar ladder. Alert's status icon and
  Accordion's chevron now resolve through the icon axis, so an application
  retheming icon sizes moves every owned glyph with them.
- Document the size vocabularies: one contract table of the six size ramps
  and why each stops where it does, so a caller can predict which sizes a
  component accepts without trying them.
- Add `--nk-choice-size-{md,lg}` and derive every checkbox and radio
  dimension from them: box, glyph proportions, description indent, and the
  native input sizes. The two sizes are one rule apart, the large radio dot
  finally scales with its control, and both indicators share one guarded
  transition.
- Add `--nk-control-padding-inline`. Buttons, inputs, selects, and textareas
  share one inline padding instead of two nearby values.
- Add the full color scales as public tokens: `--nk-{family}-{50..950}` for all
  twenty-two families — the five neutrals slate, gray, zinc, neutral, and stone,
  plus seventeen chromatic hues. Every semantic role and badge color samples
  these scales, so swapping the neutral or the accent means re-pointing roles at
  another family rather than inventing values. Scale values are Nitro's own
  harmonized ramps: smooth lightness, chroma, and hue curves fitted through the
  familiar palette, bounded to an imperceptible perceptual distance per value.
  The customization guide documents every step and ships neutral-swap and
  accent recipes.
- Add `--nk-white` and `--nk-black`. The surface, foreground, and overlay
  roles that used raw white and black resolve through them, so warm-paper and
  true-black themes are two overrides.
- Add the public tint palette: `--nk-palette-*` roles for all twenty-two
  badge colors — the five semantic families and the seventeen decorative hues —
  so `Badge`'s colors are themeable like every other part of the system. Each
  resolves to a scale step: the 400 tint with a 700-800 foreground in light and
  the 200 foreground in dark. Semantic families default to the same steps as
  their hue families, so an `info` badge renders exactly like a `blue` badge
  and a `warning` alert is amber in both appearances, until a theme separates
  them.
- Add the title scale: `--nk-title-{page,section,surface,compact}-{size,weight}`.
  Every owned title and legend resolves through one of four roles instead of
  fifteen components choosing among six sizes and two weights. Fieldset
  legends join the other surface titles at bold, and Alert titles match
  Toast titles, which the shared status palette already made visual twins.
- Add `--nk-disabled-opacity` and `--nk-shadow-xs`, and resolve every
  disabled control and Button's raised shadow through them. Disabled state
  was four different opacities; Button drew its shadows by hand.

### Breaking changes

- Settle the destructive vocabulary on two deliberate spellings. Actions and
  Alert say `destructive`: Button and Dropdown items keep their variant,
  and Alert renames its `:error` variant to `:destructive`. Toast items
  keep `:error`, the announcement spelling, and both resolve to the same
  tint family in the shared palette. Badge and AppNavigation rename their
  `danger` semantic color to `destructive`, and the tokens follow:
  `--nk-color-danger*` becomes `--nk-color-destructive*` and
  `--nk-palette-danger*` becomes `--nk-palette-destructive*`. Form and
  field error semantics are unchanged.
- Remove `Alert::VARIANT_PALETTE`. Alert variants resolve through the shared
  semantic palette instead of mapping to hue families.
- Remove `zinc` from `Badge`'s color vocabulary; use `neutral`, which renders
  the same by default and follows an application's neutral theme. A gray badge
  frozen to one gray family had no categorical job the semantic name does not
  do better.
- Change `Badge`'s default color from `:zinc` to `:neutral`. Both render the
  same way; the semantic name is now the default because it follows an
  application's theme.

### Changed

- Lower the default control height from 40px to 36px:
  `--nk-control-height-md` is now `2.25rem`, so medium buttons, inputs,
  selects, menu rows, and the choice controls' hit areas tighten together.
  Coarse pointers still adopt the 44px large step.
- Meet the 44px touch target on coarse pointers: `--nk-control-height-md`
  adopts the large step there, so default buttons, inputs, selects, menu
  rows, and the choice controls' hit areas all reach 44px on touch screens
  while explicit smaller and larger sizes keep their own scale. This pairs
  with the existing pointer text contract and is asserted by the same
  touch-emulation system test.
- Derive the remaining owned geometry from the token system. Switch is now
  four declared inputs — block heights ride the control ramp, the track is
  the block plus the handle's travel — so density presets finally reach
  switches, and Textarea's minimum height rides `--nk-space`. The
  AppearancePicker control resolves through `--nk-choice-size-md` and the
  Accordion trigger through `--nk-control-height-lg`, the values they
  already rendered. Every dimension was verified pixel-identical.
- Widen the Select chevron gutter from 36px to 40px. The gutter is now
  derived — inline padding, icon, inline padding — so the chevron sits
  symmetrically instead of at an arbitrary offset.
- Tighten extra-small Badge inline padding from 5px to 4px, making the
  badge padding ramp an even 4/6/8.
- Size fixed overlays with `100%` instead of `100vw`. Dropdown menus, the
  combobox listbox, the toast column, and the app shell drawer capped
  themselves against `100vw`, which includes the scrollbar, so classic
  scrollbars pushed them past the visible viewport. Percentages resolve
  against the initial containing block, which excludes it. Tooltip keeps
  `100vw` deliberately and documents why.
- Finish the logical-property pass: the remaining physical `width`,
  `height`, and `min-/max-` declarations now use their logical forms, so
  every component behaves in vertical writing modes.
- Dim Table's sort indicator through the color channel instead of a raw
  `opacity`, and guard the remaining control transitions and the
  DetailsTable hover for reduced motion and touch.
- Dress the AvatarStack overflow chip as one of the heads: the same neutral
  fill as the avatar fallbacks and the same hairline ring, instead of an
  elevated fill with no ring.
- Read data-entry controls and the default Button at `--nk-text-sm` on fine
  pointers and `--nk-text-base` on coarse ones, where iOS Safari zooms a
  focused control below 16px. The pair stays matched in both modes; Select
  and Textarea follow the same rules instead of inheriting the page font.
- Even the control height ramp: `--nk-control-height-sm` is the 2rem small
  Button already rendered, and Button consumes the token, so the theme
  customizer's density exports reach small buttons instead of being
  silently ignored.
- Resolve `Badge`, `Alert`, and `Toast::Item` colors from public tokens through
  one shared palette. Badge colors were previously hardcoded in private
  `--_nk-*` variables, which are not a theme API, so badge color was the one
  thing in the library an application could not rebrand.
- Separate `Badge`'s two color axes. Semantic families follow the
  `--nk-palette-{family}` tint roles and move with an application's brand;
  decorative hues follow the `--nk-palette-{hue}` roles and stay the color they
  name. `red` and `danger` previously resolved to identical CSS and are now
  independently themeable.

- Soften the toast shadow from the dialog tier to the floating-element tier,
  matching dropdowns and comboboxes. It carried the strongest shadow in the
  system on a card-radius surface, fitting no rung of the elevation ladder.

### Fixed

- Stop Avatar rings from painting through overlapping stack siblings. The
  ring pseudo-element carries a z-index but the avatar root was not a
  stacking context, so in an AvatarStack every ring floated above every
  neighboring avatar's fill and the stack looked translucent. Avatars are
  now isolated, so each one paints atomically and covers the ring beneath
  it.
- Render an `Alert` and a `Toast::Item` of the same variant identically. Both
  declare the same variant vocabulary but resolved it from different sources, so
  one "success" appeared as two different greens and rethemeing a semantic token
  moved only the toast.
- Raise the orange badge foreground so it clears WCAG AA against its own tint.
  It rendered at 4.31:1 in light appearance. Every semantic family and hue is
  now asserted at 4.5:1 or better in both appearances.

## 2.0.0.alpha.3

### Added

- Add a dated browser verification matrix with full Chrome coverage, focused
  Firefox and macOS Safari lanes, and explicit Android, iOS, and near-floor
  release checks.
- Add `--nk-button-radius` so applications can preserve a button-specific shape without changing inputs and surfaces.
- Add structured JSON output to `nitro_kit:doctor` for migration automation.

### Changed

- Accept Rails-style nested and conditional class values through `desperately_need_a_class:`, normalizing retained external-integration hooks without manual string formatting, while directing migrations to review every use and aim for zero.
- Make migration diagnostics surface usages of application-owned button treatments and provable 2.0 Table/Button runtime contract errors, and require semantic theme translation plus wide and narrow browser comparison.
- Recognize explicit Stimulus controller registration used by JavaScript bundlers.
- Explain the purpose and limits of generated host-integration smoke tests in each generated file.

### Documentation

- Define the rolling evergreen browser-support policy, with Mobile Safari as a
  first-class target and standards-first, feature-detected fallbacks for core
  behavior.
- Classify every interactive component's no-JavaScript baseline as full,
  reduced, or unavailable.
- Document native month and week inputs as progressive enhancement, including
  server-side ISO validation and bounded Select guidance.
- Document Accordion's reduced single-group behavior where named details are
  unavailable instead of adding a compatibility controller.

### Fixed

- Keep Dialog, Sheet, and CommandPalette controls working when Invoker Commands
  are unavailable while preserving the native declarative path and consistent
  focus restoration in Safari.
- Stack AppShell toolbar actions below the title on narrow screens instead of
  clipping child-route titles when a Back affordance and several actions share
  the header.
- Restore Dropdown outside-tap dismissal on affected Mobile Safari Popover
  implementations and keep its reduced placement inside the viewport.
- Provide readable Typeset styling in Firefox versions without CSS `@scope`.
- Keep settled progressive images visible when Turbo restores a cached page.
- Keep arbitrary multi-element Button content aligned inside the label slot.
- Keep the command palette at a stable height while filtering destinations.
- Use a neutral elevated surface instead of the primary accent for tooltips.
- Resolve implicit FormBuilder labels only when rendered, so custom field blocks work under strict i18n.
- Allow generated upgrade smoke tests to coexist with host catch-all routes while still rejecting exact route collisions.

## 2.0.0.alpha.2

This alpha keeps the 2.0 API experimental while incorporating the first full
catalog-pattern and external-agent testing pass.

### Changed

- Add the setup-only installer, project-local agent guidance, diagnostics, and
  initialization prompt used by new and existing Rails applications.
- Align desktop page-header actions with the title edge and improve nested
  table and responsive dropzone composition.
- Exercise desktop pointer capabilities in browser CI with environment-matched
  Chrome tooling.

### Fixed

- Improve warning, destructive, form-error, and dark-mode contrast.
- Preserve native list and fieldset semantics in form errors and grouped
  controls.
- Fix table-cell alignment leakage and cramped upload actions at narrow widths.

## 2.0.0.alpha.1

Nitro Kit 2.0 alpha is a ground-up, intentionally incompatible rebuild around gem-owned Phlex composition. It replaces the generated, helper-driven 1.x architecture with a versioned component system owned by the gem.

### Breaking changes

#### Packaging and API surface

- Replace generated editable component copies with versioned `NitroKit::*` classes loaded from the gem.
- Remove all `nk_*` ERB helpers, generated variant helpers, `from_template`, and template-buffer bridges.
- Remove copied-component generators, schema/variant metadata, and legacy installation paths.
- Add a setup-only generator, project-local Rails/Hotwire/UI skills, integration
  diagnostics, and an agent initialization prompt for Nitro Kit 2.
- Remove Tailwind Merge, consumer Tailwind requirements, old Tailwind assets, and internal component class strings.
- Use Rails `form_with(..., builder: NitroKit::FormBuilder)` instead of `nk_form_with` or `nk_form_for`.
- Remove vendored Floating UI and combobox navigation runtimes and the obsolete Datepicker and Switch controllers.

#### Attribute boundary

- Replace permissive component attributes with explicit options and `html:`, `aria:`, and `data:` boundaries.
- Reject `class` and `style`; add the observable `desperately_need_a_class:` integration escape.
- Reserve a named set of data keys instead of an ad hoc list. `Component::COMPONENT_OWNED_DATA_ATTRIBUTES` is `state`, `disabled`, `required`, `orientation`, `presentation`, `placement`, `layout`, and `field-type`; `Component::RESERVED_DATA_ATTRIBUTES` adds `nk`, `slot`, `variant`, `size`, `nk-escape`, and `enhanced`. Passing any of them through `data:` now raises. `data-controller` and `data-action` remain additive.
- Settle the variant axis: `variant:` and `size:` on a root are the component's identity axes and are emitted only by the base component. A slot may carry its own owned `data-variant` when it has variant identity of its own, as `Toast::Item` and Dropdown items do; caller `data: { variant: }` stays reserved either way.

#### Removed components and options

- Remove `VStack` and `HStack` in favor of one explicit, responsive `Flex` component.
- Remove the Datepicker component entirely. `Input`'s `type: :date` is the only date control, and `Field`/`FormBuilder` reach it through `as: :date`.
- Remove the separate sortable-table component. Sorting lives on `Table` through `Table.new(sort:, direction:)` and `th(sort:, href:, sort_data:)`; `NitroKit::RansackTable` is not a core contract.
- Remove `Combobox::Option` in favor of the shared, validated `NitroKit::Choice` value.
- Remove `Alert`'s second palette axis. `Alert` now has one semantic `variant:` axis of `default info success warning error`, matching `Toast::Item`, with the tint driven by the Alert-owned `VARIANT_PALETTE`. There is no `color:` option; the `color:` palette belongs to `Badge` alone.

#### Renamed and reshaped options

- Rename Button's trailing-icon keyword to `icon_end:`, matching the `button-icon-end` slot. `icon_right:` is gone. `Dropdown#trigger` and `Tooltip#trigger` forward the same `icon:`/`icon_end:` pair.
- Add `icon:` to `Dropdown#item` alongside its owned `data-variant` for `default` and `destructive` items.
- Replace Dialog's ad hoc content declarations with exactly one required `panel(title:, description: nil, nonmodal: false)`. Nitro renders close button, title, description, then application content, so a sticky close control survives long panels. `dismissible: false` renders no close button and declaring one raises.
- Rename `Dropzone`'s visible prompt keyword from `title:` to `label:`, and move its remaining user-facing strings into the `nitro_kit.dropzone.*` locale scope.
- Require `label:` on `AvatarStack` to name the group, add `max:` to bound visible avatars and derive the `+N` indicator, and reject `aria: { label: }` and combining `max:` with an explicit `overflow`.
- Give `AppShell` a `layout:` axis rather than a variant. The root is now `div[data-nk="app-shell"][data-layout]`, and the narrow drawer is a real modal `dialog` so the browser owns focus containment, inertness, and Escape.
- Make `AppNavigation`'s body a real `ul`, with every entry an `li` and items rendering `li > a[data-slot="app-navigation-item-link"]` that carry their own attribute bags. `SettingsLayout` navigation uses the same `nav > ul > li > a` shape.
- Reshape `Toast`. The list is `ol[data-slot="toast-list"]` whose id is the toast id plus `-list`, so a Turbo Stream can append `Toast::Item` directly to `nk-toast-list`. Items carry `role="status"`, or `role="alert"` for the error variant, and every item is `data-turbo-temporary` while the region and list survive. `dismissible: false` items are never auto-dismissed.
- Scope checkable behavior to the one state HTML cannot express. `Checkbox` mounts `nk--checkable` only for `indeterminate: true`; ordinary checked state, `Switch`, and `RadioButton` mount no controller and mirror no `data-state`. A `Checkbox` description now requires a non-blank String `id:`.
- Require `id:`, `name:`, `label:`, and `options:` on `Combobox`, validate the value against the declared options, and accept `label: false` only with `control_aria: { label: }` or `{ labelledby: }`. `Field` gains `as: :combobox`, `as: :rich_text`, and `as: :radio_group`, and rejects `label: false` for radio groups.

### Added

- Add `CommandPalette`, a native-dialog destination search with a declarative link baseline, optional Command-K or Control-K shortcut, local or server-rendered Turbo Frame results, result announcements, and Turbo-safe reset behavior.
- Self-describing, classless `data-nk` roots and component-qualified `data-slot` contracts.
- Static zero-specificity CSS, light and dark theme tokens with a no-JavaScript system fallback, and a separate Tailwind CSS v4 adapter.
- Responsive Flex and Grid layouts with fixed mobile-first breakpoints, closed values, classless data contracts, and no Tailwind runtime; plus the constrained-width Container.
- Sortable `Table` headers with caller-owned URLs, native `aria-sort`, and an optional Ransack gallery recipe.
- Eleven blocks and shells: AuthShell, AppShell, SettingsLayout, Toolbar, PaginationBar, PageHeader, StatGrid, DataSection, SettingsSection, DangerZone, and EmptyState.
- AppNavigation, AppearancePicker, DetailsTable, Dropzone, and ProgressiveImage components, plus the non-visual AppearanceBootstrap runtime.
- Typed Choice values and direct-Phlex Rails FormBuilder integration with Active Model errors, native and direct uploads, and Turbo Frame/Stream examples.
- Direct optional Pagy integration through `Pagination(pagy:)`, with an explicit URL callable for caller-owned destinations.
- Optional Lexxy and Action Text integration through `form.field(..., as: :rich_text)`, preserving editor-native inputs, attachments, options, and behavior inside Nitro's Field contract.
- Gem-owned importmap pins and Stimulus behavior for AppShell, AppearancePicker, Avatar, Button submission feedback, Checkbox (`nk--checkable`), Combobox, CommandPalette, Dialog, Dropdown, Dropzone, ProgressiveImage, Tabs, Toast, and Tooltip. Accordion needs no JavaScript at all.
- `Typeset` for semantic rich content and `RichTextArea` for the host application's rich-text editor output.
- A `nitro_kit.*` locale scope so component copy is translatable; Dropzone additionally hands its runtime strings to `nk--dropzone` as Stimulus values so no user-facing English lives in JavaScript.
- A catalog-driven Phlex gallery covering components, blocks, broad application flows, complete application shells, responsive states, and light, dark, and system appearance.
- A public customization guide and gallery wizard for documented tokens, deterministic CSS exports, and copyable AppShell composition.

### License metadata

- Mark the gem's existing custom NitroKit License as nonstandard and include `LICENSE` in the package. The license terms are unchanged.

## 0.9.0

### Added

- Include assets in the gem package
- Add integration test coverage for core components

### Changed

- Update pagination helper for the latest Pagy API
- Resolve schema builder dependencies transitively

### Fixed

- Apply combobox root class correctly
- Fix rendering NitroKit components inside NitroKit components
- Fix Select prompt handling
- Fix dropdown destructive item helper argument handling
- Handle missing Pagy dependency gracefully

## 0.8.0

### Changed

- Reformat as Rails Omakase rubocop style
- Update Avatar component rendering for improved consistency
- Add formatting tools and minor cleanup improvements

### Fixed

- Fix Select component empty rendering issue
- Add missing `select` method to FormBuilder
- Fix toast controller initialization timing issues
- Add Table wrapper parameter
- Remove default whitespace-nowrap from table cells

## 0.7.0

### Changed

- Migrate from `builder_method` to `from_template` pattern
- Update Input focus styling to use `focus-visible` for better accessibility
- Improve `text_or_block` method with SafeBuffer handling
- Remove I18n dependency from FormBuilder

### Added

- XL size option for Button component
- `radio_button` method to FormBuilder
- `nk_avatar_stack` helper and component
- Pass options to Combobox in `combobox` method
- Support for rendering fields as custom component classes

### Fixed

- Remove duplicate id from field checkbox hidden field
- Fix checkbox field and textarea rendering
- Add spacing between consecutive fieldsets
- Improve dropdown functionality

## 0.6.0

NB: Nitro Kit has been re-licensed to disallow reselling as is. It is still free to use in your projects you just can't sell copies of it.

### Breaking changes

- Update color definitions and add some more. **You'll need to update the color definitions in your CSS file.** See [Getting Started](https://nitrokit.dev/getting_started)

### Changed

- Update `phlex` and `phlex-rails` dependencies
- Increase button[size=sm] size

### Added

- Badge colors!
- Support for `as:` prop in Dialog
- `align:` prop for table cells

## 0.5.2

Start of this document
