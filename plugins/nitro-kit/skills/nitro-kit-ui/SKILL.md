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
6. Inspect the installed component source when constructor or compound-slot details remain unclear. Never guess a component API from memory.

If the gem is not installed, say that the skill requires Nitro Kit and follow the application's requested installation scope. Do not substitute APIs from an older Nitro Kit release.

## Build the interface

1. Reuse the highest-level Nitro block that matches the page region, then compose components inside it.
2. Include `NitroKit` once in the application's base Phlex component and use capitalized Kit methods such as `Button(...)` and `Card(...)`. Use `.new` only when another API needs a component object. Keep product-specific components under the application's namespace, commonly `UI::*`.
3. Use `NitroKit::FormBuilder` explicitly with Rails `form_with` for model-backed forms.
4. Keep routes, authorization, records, query policy, DOM IDs, Turbo boundaries, and response semantics in the application.
5. Use documented `--nk-*` properties for theming and Nitro layout primitives for layout.
6. Verify closed options and required compound declarations before rendering.
7. For authenticated CRUD, prefer a hybrid `AppShell` with a `Toolbar` that
   owns the route's single `h1` and basic actions. The shell main region owns
   one content gutter. Do not repeat that heading in `PageHeader`, or wrap each
   table, form, and detail region in another Card.

## Preserve the boundary

- Do not copy Nitro components into the application.
- Do not introduce `nk_*` helpers, a general ERB bridge, or generated variant helpers.
- Do not pass `class:` or `style:`. Prefer component options, composition, or theme tokens. Use `desperately_need_a_class:` only for a genuine external integration boundary.
- Do not add application-specific behavior to Nitro-owned Stimulus controllers.
- Do not recreate a Nitro component with raw HTML unless the installed catalog cannot express the semantics.

## Verify

Run the smallest relevant application tests. For component rendering, assert semantic elements and owned `data-nk` or slot attributes rather than private implementation helpers. Exercise invalid and empty states when the UI accepts user input or collections.
