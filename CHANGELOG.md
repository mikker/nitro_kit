# Changelog

## 2.0.0.pre.1

Nitro Kit 2.0 is a complete, intentionally incompatible rewrite around gem-owned Phlex composition.

### Breaking changes

- Replace generated editable component copies with versioned `NitroKit::*` classes loaded from the gem.
- Remove all `nk_*` ERB helpers, generated variant helpers, `from_template`, and template-buffer bridges.
- Remove copied-component generators, schema/variant metadata, and legacy installation paths.
- Add a setup-only generator, project-local Rails/Hotwire/UI skills, integration
  diagnostics, and an agent initialization prompt for Nitro Kit 2.
- Remove Tailwind Merge, consumer Tailwind requirements, old Tailwind assets, and internal component class strings.
- Replace permissive component attributes with explicit options and `html:`, `aria:`, and `data:` boundaries.
- Reject `class` and `style`; add the observable `desperately_need_a_class:` integration escape.
- Use Rails `form_with(..., builder: NitroKit::FormBuilder)` instead of `nk_form_with` or `nk_form_for`.
- Remove vendored Floating UI and combobox navigation runtimes and the obsolete Datepicker and Switch controllers.
- Remove `VStack` and `HStack` in favor of one explicit, responsive `Flex` component.

### Added

- Self-describing, classless `data-nk` roots and component-qualified `data-slot` contracts.
- Static zero-specificity CSS, light and dark theme tokens with a no-JavaScript system fallback, and a separate Tailwind CSS v4 adapter.
- Responsive Flex and Grid layouts with fixed mobile-first breakpoints, closed values, classless data contracts, and no Tailwind runtime; plus the constrained-width Container.
- Sortable `Table` headers with caller-owned URLs, native `aria-sort`, and an optional Ransack gallery recipe.
- Eleven blocks and shells: AuthShell, AppShell, SettingsLayout, Toolbar, PaginationBar, PageHeader, StatGrid, DataSection, FormSection, DangerZone, and EmptyState.
- AppNavigation, AppearancePicker, DetailsTable, Dropzone, and ProgressiveImage components, plus the non-visual AppearanceBootstrap runtime.
- Typed Choice values and direct-Phlex Rails FormBuilder integration with Active Model errors, native and direct uploads, and Turbo Frame/Stream examples.
- Direct optional Pagy integration through `Pagination(pagy:)`, with an explicit URL callable for caller-owned destinations.
- Optional Lexxy and Action Text integration through `form.field(..., as: :rich_text)`, preserving editor-native inputs, attachments, options, and behavior inside Nitro's Field contract.
- Gem-owned importmap pins and Stimulus behavior for Accordion, AppShell, AppearancePicker, Combobox, Dialog, Dropdown, Dropzone, ProgressiveImage, Tabs, Toast, and Tooltip.
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
