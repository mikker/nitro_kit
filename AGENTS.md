# Nitro Kit 2.0 agent guidance

Nitro Kit is a gem-owned, Phlex-only UI system for Rails. Read `docs/agent_native_spec.md`, `docs/component_contracts.md`, and `STYLE_GUIDE.md` before editing components. Read `docs/agent_guide.md` and the matching file under `docs/patterns/` before changing an application interaction convention. `docs/implementation_plan.md` is the delivery record; `tk` is the source of truth for live status.

The `2.0-agent-native` branch intentionally breaks the 1.x API. Do not preserve obsolete helpers, generated-copy installation, Tailwind class strings, or permissive component attributes for compatibility.

## Commands

Use the repository's `mise` environment:

```sh
mise exec -- bundle install
mise exec -- bin/rails test
mise exec -- bin/format
mise exec -- rake nitro_kit:css:build
mise exec -- rake nitro_kit:css:check
```

The dummy app runs on port 3031 with `mise exec -- bin/dev`.

## Ownership

Nitro Kit owns and versions component Ruby, rendered `data-nk` contracts, CSS, Stimulus behavior, layout primitives, blocks, and examples. Applications customize documented `--nk-*` properties and compose Nitro components into their own namespaces.

Composition is the stable extension path. Subclassing is possible, but private methods are not an API.

Core components are loaded from the gem. The setup generator may install
agent guidance and application-owned integration files; do not add or restore
generators that copy component source into applications.

## Public API

Direct Phlex composition is the only Nitro component API:

```ruby
render NitroKit::Button.new("Save", variant: :primary)
```

Do not create `nk_*` ERB helpers, automatic variant helper names, `from_template`, or template-buffer-aware builder wrappers.

Rails helpers remain welcome where Rails supplies real semantics: forms, routes, DOM IDs, translations, assets, and Turbo/Hotwire. Include only the `Phlex::Rails::Helpers::*` adapters a component or page actually uses.

## Component rules

- Public component options are explicit keywords. Do not add a catch-all `**options` that can swallow misspellings.
- Validate every enumerated option and raise `ArgumentError` for invalid values.
- Use a deliberate `html:`, `aria:`, and `data:` boundary for native attributes.
- `class:` and `style:` are forbidden.
- The only class escape is `desperately_need_a_class:`. It must also emit `data-nk-escape="class"`.
- Reserve `data-nk`, `data-slot`, `data-variant`, `data-size`, `data-state`, and `data-nk-escape` for Nitro.
- Every root emits `data-nk`. Owned parts use component-qualified `data-slot` values such as `field-control` or `card-title`.
- Keep application content slots flexible where the public compound API declares them. Do not invent an untyped structural bypass.
- Parents own external placement and available width. Atoms own intrinsic geometry.
- Use `Flex(dir:, gap: 4, align: :start, justify: :start, wrap: :nowrap)` and `Grid(cols:, gap: 4)` for layout; `VStack` and `HStack` are removed. Responsive properties use a required base plus fixed `sm md lg xl 2xl` overrides, never a generic utility or custom-breakpoint DSL.
- Preserve native elements and accessibility semantics.

## CSS rules

- Nitro components never emit or depend on classes.
- Author split plain CSS under `src/stylesheets/nitro_kit/`.
- Commit the generated browser-ready `app/assets/stylesheets/nitro_kit.css`.
- Target `data-nk`, qualified `data-slot`, variant, size, ARIA, and state attributes inside `:where()`.
- Scope slot selectors to their owner, using direct relationships where possible.
- Use documented `--nk-*` variables for themeable decisions and private `--_nk-*` variables for component mechanics.
- Nitro ships its own global, Preflight-style reset in `reset.css`, inside the `nitro-kit.reset` cascade layer. Because it is layered, unlayered application CSS always wins. Do not rely on Tailwind Preflight or consumer Tailwind configuration.
- The reset stays global except for `min-width: 0` and list-marker removal, which remain scoped to Nitro-owned elements so prose lists keep real markers.
- Keep the optional Tailwind v4 adapter separate from the main asset.
- Never use `transition: all`. Respect reduced motion and keep interactive transitions interruptible.

## Rails and Hotwire

- Retain and simplify `NitroKit::FormBuilder`; use it through `form_with` from Phlex.
- Exercise real ActiveModel validation, Rails naming, IDs, error rendering, multipart forms, and submit behavior.
- Keep Stimulus controllers small and state visible through ARIA and `data-state`.
- Remove listeners, observers, timers, and other external resources in `disconnect`.
- Test behavior through Turbo Drive, Frames, Streams, and morphing.

Importmap applications receive Nitro's controller pins from the engine, but the host application still owns Stimulus and its controller loader. Do not add vendored third-party JavaScript or assume a JavaScript-package entrypoint exists.

## Tests and examples

Every component needs:

- Direct-Phlex render tests.
- Invalid-option tests.
- Reserved attribute and escape-hatch coverage.
- Structural/accessibility assertions.
- A navigable gallery combination page.
- Meaningful variants, sizes, states, long content, disabled/error cases, dark mode, and narrow-width coverage.

The gallery is a real Phlex application driven by an explicit catalog. Do not add ERB test templates or filename-based template dispatch. Keep preview composition inside the block passed to `example`/`render_example`; `Gallery::SourceCode` extracts its executable Ruby body for the paired Code tab. Inherited flow wrappers may pass `SourceCode.from_method` for the concrete composition method. Do not duplicate snippets in heredocs.

Preserve these pre-existing behaviors when migrating their files:

- Button labels call `to_s` so non-string labels render correctly.
- `datetime-local` Field values normalize time-like values, while file fields never emit a value.

## Tickets

The 2.0 pivot is tracked with `tk` from the workspace root:

```sh
tk ready
tk show ID
tk start ID
tk add-note ID "..."
tk close ID
```

Work only on tickets whose dependencies are satisfied unless the orchestrating agent explicitly assigns preparatory work. Add notes for design decisions, risks, and verification results before closing a ticket.
