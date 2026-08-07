---
name: nitro-kit-ui
description: Build or refactor Rails interfaces with Nitro Kit 2's Phlex components, layouts, blocks, FormBuilder, and theme tokens. Use when an application has nitro_kit 2.x in its bundle, mentions Nitro Kit, or asks for a Rails interface that should follow the installed component contract instead of Nitro Kit 1.x helpers, custom markup, CSS overrides, or copied component code.
---

# Nitro Kit UI

Use the documentation shipped with the application's installed gem as the source of truth. Compose application-owned product UI from gem-owned components.

## Load the matching contract

1. Work from the Rails application root.
2. Confirm `nitro_kit` appears in `Gemfile.lock`.
3. Run `bundle show nitro_kit` and treat its output as `NITRO_KIT_ROOT`.
4. Read `NITRO_KIT_ROOT/docs/agent_guide.md` completely.
5. Read the relevant sections of `NITRO_KIT_ROOT/docs/component_contracts.md`. Read `customization.md` only for themes, tokens, or application composition.
6. For any interactive component or no-JavaScript claim, read the canonical
   classifications in `NITRO_KIT_ROOT/docs/browser_support.md`.
7. Inspect the installed component source when constructor or compound-slot details remain unclear. Never guess a component API from memory.

For a Nitro Kit 1.x migration, read
`NITRO_KIT_ROOT/docs/migration_1_to_2.md` before editing. Inventory product
flows, behavior, application-owned button classes and Rails button helpers,
joined controls, and the existing semantic color, focus, radius, density, and
typography tokens first. Capture representative wide and narrow screenshots.
If the Nitro Kit MCP catalog is available, search it by workflow rather than
old component name, then select high-level compositions before replacing
atoms.

If the gem is not installed, say that the skill requires Nitro Kit and follow the application's requested installation scope. Do not substitute APIs from an older Nitro Kit release.

## Build the interface

1. Reuse the highest-level Nitro block that matches the page region, then compose components inside it.
2. Include `NitroKit` once in the application's base Phlex component and use capitalized Kit methods such as `Button(...)` and `Card(...)`. Use `.new` only when another API needs a component object. Keep product-specific components under the application's namespace, commonly `UI::*`.
3. Use `NitroKit::FormBuilder` explicitly with Rails `form_with` for model-backed forms.
4. Keep routes, authorization, records, query policy, DOM IDs, Turbo boundaries, and response semantics in the application.
5. Translate the application's semantic theme into documented `--nk-*` properties instead of choosing similar raw palette values. Use `--nk-button-radius` when Button shape intentionally differs from inputs and surfaces.
6. Verify closed options and required compound declarations before rendering.
7. For authenticated CRUD, prefer a hybrid `AppShell` with a `Toolbar` that
   owns the route's single `h1` and basic actions. The shell main region owns
   one content gutter. Do not repeat that heading in `PageHeader`, or wrap each
   table, form, and detail region in another Card. At narrow widths, preserve
   the full title and persistent actions by stacking the trailing actions below
   the title rather than clipping either region.
8. For team administration and account settings, read
   `docs/patterns/application_foundation.md`. Put Settings after an
   `AppNavigation` spacer and use `SettingsLayout` with plain `SettingsSection`
   regions instead of a stack of Cards.

## Preserve the boundary

- Do not copy Nitro components into the application.
- During migration, replace an existing control only when the installed catalog
  provides a genuine semantic and behavioral equivalent. Otherwise keep or
  re-express it as application-owned Rails and semantic HTML, optionally inside
  a custom `form.field` composition. Preserve names, IDs, values, errors,
  accessibility, uploads, and browser behavior; report the missing equivalent
  as a Nitro Kit coverage gap.
- Never downgrade a specialized control to a generic Nitro control for visual
  consistency, and never retain copied Nitro Kit 1.x source as the fallback.
- Do not introduce `nk_*` helpers, a general ERB bridge, or generated variant helpers.
- Pass native attributes through each component method's documented `html:`, `aria:`, or `data:` boundary; for example, use `table.tr(html: { id: dom_id(record) })`, not `table.tr(id: ...)`. Do not pass `class:` or `style:`. Prefer component options, composition, wrappers, or theme tokens. Use `desperately_need_a_class:` only for a named external integration boundary that requires a class hook; it accepts Rails-style strings, symbols, nested arrays, and conditional hashes without manual joining.
- Give every icon-only Button, Dropdown trigger, and Sheet trigger an explicit `label:` or ARIA label. For custom `form.field` blocks, render an explicit field label instead of relying on an unused implicit model translation.
- Do not add application-specific behavior to Nitro-owned Stimulus controllers.
- Do not recreate a Nitro component with raw HTML unless the installed catalog cannot express the semantics.

## Verify

Run the smallest relevant application tests. For component rendering, assert semantic elements and owned `data-nk` or slot attributes rather than private implementation helpers. Exercise invalid and empty states when the UI accepts user input or collections.

For a migration, Doctor is an inventory, not visual proof. Run representative form and component rendering with `ActiveModel::Translation.raise_on_missing_translations` enabled when the application uses strict i18n. Compare the same representative flows in a browser at wide and narrow widths, exercise keyboard focus, and inspect computed styles for missing application classes, stacked Button content, broken compound corners, double focus rings, clipping, and theme drift. Re-audit rendered native buttons, Rails button helpers, and application-owned button classes before declaring the conversion complete. Search the whole application for `desperately_need_a_class:` and review every result, aiming for zero. Move layout and visual treatment to application-owned wrappers, remove generic class forwarding, accept incidental Nitro defaults, and keep unmatched product UI application-owned; retain only documented external-integration hooks.
