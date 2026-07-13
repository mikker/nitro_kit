# Nitro Kit 2.0 — agent-native Phlex UI system

This is the canonical architecture specification for the Nitro Kit `2.0.0.pre.1` line. The delivery sequence and ticket map are retained in [`implementation_plan.md`](implementation_plan.md) as design history; `tk` is the source of truth for live work status.

Nitro Kit is a gem-owned, versioned UI system for Rails. Developers and coding agents compose application interfaces in Ruby with Phlex. Nitro Kit owns component behavior, rendered structure, and default aesthetics. Applications own product code and documented theme overrides, not copies of Nitro Kit internals.

## Product contract

### Nitro Kit owns the system

Nitro Kit owns and versions:

- Component Ruby and public initializer and compound-method APIs.
- Rendered `data-nk`, `data-slot`, state, and ARIA contracts.
- Static component CSS, the default themes, and public `--nk-*` tokens.
- Stimulus behavior and Rails engine integration.
- Layout primitives, blocks, the Auth shell, canonical examples, and tests.

Applications may:

- Override documented `--nk-*` custom properties.
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
2. **Structure** — Nitro-owned Phlex atoms, layouts, blocks, and Auth shell.
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

Native elements remain native. Visible state is reflected through ARIA and `data-state`. Slot selectors are scoped to their owner and use direct relationships where practical.

## Shipped structure vocabulary

The authoritative initializer, root, closed-option, and cardinality inventory lives in [`component_contracts.md`](component_contracts.md).

The prerelease contains 30 atoms and components:

- Actions, display, and navigation: Alert, Avatar, AvatarStack, Badge, Button, ButtonGroup, Icon, Pagination.
- Forms: Checkbox, CheckboxGroup, Datepicker, Field, FieldGroup, Fieldset, Input, Label, RadioButton, RadioButtonGroup, Select, Switch, Textarea.
- Structured content and interaction: Accordion, Card, Combobox, Dialog, Dropdown, Table, Tabs, Toast, Tooltip.

Four layout primitives were supported by repeated flow evidence:

- `VStack(gap:, align:)`
- `HStack(gap:, align:, justify:, wrap:)`
- `Grid(cols:)`, with only the proven three-column form.
- `Container(size:)`

Ten blocks and shells were extracted:

- `AuthShell`
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

Public `--nk-*` variables cover semantic colors, typography, spacing, radii, border and focus geometry, shadows, motion, control heights, and content widths. Private `--_nk-*` variables coordinate component mechanics and are not theme API.

The light contract applies at `:root` and `[data-theme="light"]`; `[data-theme="dark"]` supplies the dark contract and `color-scheme: dark`. Applications override the same public variables for their themes.

`nitro_kit-tailwind-v4.css` is an optional, separately versioned adapter. It loads before Nitro Kit and compiled Tailwind CSS to establish layer order and map theme variables. Tailwind remains an application concern, not a Nitro runtime dependency.

## Layout sizing

Parents own external placement and available width. Components own intrinsic geometry.

Inputs, textareas, selects, tables, and broad surfaces may stretch naturally. Buttons, badges, avatars, icons, and switches remain intrinsic unless an accepted layout explicitly stretches them.

## Rails and Hotwire

`NitroKit::FormBuilder` is selected through Rails `form_with` from Phlex. It preserves Rails naming, IDs, model values, values-before-type-cast, Active Model errors, multipart forms, checkbox hidden values, and captured select options.

Turbo Frames and Turbo Streams remain Rails helpers used directly from Phlex. Invalid submissions return 422; successful non-Turbo form submissions redirect with 303. The supported boundary and executable reference path are documented in [`rails_integration.md`](rails_integration.md).

The engine ships CSS assets and seven Stimulus controllers. When importmap is present it adds its pins automatically; the host still owns Stimulus and its normal controller loader. The engine boots without importmap, but this prerelease does not define a JavaScript-package entrypoint for automatic bundler registration.

Datepicker and Switch deliberately use native inputs rather than custom controllers. No third-party JavaScript runtime is vendored.

## Examples and verification

The dummy Rails application is the canonical example gallery. An explicit `Gallery::Catalog` drives routes for component pages, block pages, and realistic application flows. That catalog is documentation infrastructure, not a packaged public registry.

Examples cover closed options, content pressure, native state, validation, empty/error/loading/destructive states, light and dark themes, narrow and wide layouts, and interaction between forms, navigation, tables, and overlays.

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
- `AppShell`, `MarketingShell`, or `AuthenticationPanel` shells.
- `ProgressSteps` or speculative domain blocks.
- Card/Table density, radio-group orientation, arbitrary grid columns, or public breakpoint APIs.
- Theme marketplace/validation or visual-regression goldens.

These ideas require new evidence and a deliberate future API decision. Their appearance in design notes or historical plans does not make them public.

## Design history

The pivot was delivered in evidence-seeking stages: establish the kernel and representative vertical slice, migrate atoms, build atom-only product flows, record repeated friction, extract only proven layouts and blocks, expand the gallery, remove 1.x, then consolidate behavior, packaging, and documentation.

The evidence pass rejected more abstractions than it accepted. `Spacer`, `Split`, `Frame`, App/Marketing shells, AuthenticationPanel, and ProgressSteps stayed out because current flows did not establish a stable cross-domain responsibility. [`notes/block_candidates.md`](../notes/block_candidates.md) retains that reasoning.

## Definition of done

The 2.0 architecture is release-ready when:

- Core components are gem-owned and composed directly through Phlex.
- Generated copies, ERB component helpers, Tailwind Merge, and consumer Tailwind dependence are absent.
- Every visual component emits classless, self-describing markup and uses static Nitro CSS.
- Rails forms and Hotwire work through direct Phlex composition.
- The accepted layout and block vocabulary covers the canonical flows without escape markers.
- CSS, package, Ruby, Rails, and browser verification pass.
- Public documentation matches shipped APIs and clearly states the 1.x break.
