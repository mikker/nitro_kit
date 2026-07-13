# Nitro Kit 2.0 component style guide

Nitro Kit is a gem-owned, Phlex-only UI system for Rails. Its public surface is typed Ruby composition, self-describing markup, and static CSS driven by custom properties.

## Principles

- Prefer the smallest obvious Ruby API.
- Compose components directly with Phlex.
- Make invalid component vocabulary impossible to render silently.
- Keep state and component identity visible in markup.
- Preserve native HTML and Rails semantics.
- Let applications customize themes and compose product-specific UI without editing Nitro internals.
- Keep behavior minimal, progressive, and Turbo-safe.

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

Direct Phlex composition replaces the old template-aware `builder do` wrapper. Compound APIs should be ordinary Ruby methods that render into the current Phlex context.

Named leaf slots may accept arbitrary application content. That is normal composition, not an escape.

Do not add an untyped structural bypass. If a legitimate application-content boundary is missing, add the smallest named compound method supported by real composition evidence.

## Class escape

Nitro components never emit or depend on classes. The only exception is:

```ruby
desperately_need_a_class: "external-widget-hook"
```

It must produce both the class and `data-nk-escape="class"`. Blank or non-string values raise. Implement this once in the base component.

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

## Tokens and themes

Public `--nk-*` variables cover themeable decisions: semantic colors, paired foregrounds, typography, spacing, radii, control dimensions, shadows, borders, motion, and content widths.

Private `--_nk-*` variables coordinate component mechanics and are not a theme API.

Do not tokenize structural keywords, percentages, zero values, grid mechanics, or every media-query breakpoint.

The built-in light contract applies at `:root` and `[data-theme="light"]`. Dark themes use `[data-theme="dark"]`, override the same public tokens, and set `color-scheme: dark`. Derived hover/active values may use `color-mix()` while remaining explicitly overridable.

The optional `nitro_kit-tailwind-v4.css` adapter is a separate asset. Load it before Nitro Kit and compiled Tailwind CSS. Do not add Tailwind as a Nitro runtime dependency.

## Scoped baseline

Nitro CSS cannot rely on Tailwind Preflight. Add a small reset scoped to Nitro roots and owned parts for box sizing, form typography, borders, owned text/list margins, tables, SVGs, placeholders, hidden state, and native-control quirks actually used by Nitro.

Do not reset arbitrary content supplied by the application.

## Layout sizing

Parents own external placement and available width. Components own intrinsic geometry.

- Naturally stretchable: inputs, textareas, selects, tables, broad surfaces.
- Naturally intrinsic: buttons, badges, avatars, icons, switches.
- Layout primitives decide alignment, wrapping, the proven three-column grid, and available width through closed enumerations.

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

## Stimulus and Hotwire

Stimulus remains Nitro Kit 2.0's behavior layer.

- Use targets and values for declarative state.
- Reflect visible state through ARIA and `data-state`.
- Clean up every external listener, timer, observer, and other resource in `disconnect`.
- Avoid duplicate initialization through Turbo morphs.
- Prefer native controls and browser behavior.
- Test keyboard behavior and Turbo Drive/Frame/Stream/morph lifecycles.

## Interface quality

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
