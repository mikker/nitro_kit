# Building applications with Nitro Kit

This is the routing guide for coding agents working in a Rails application that uses Nitro Kit. It describes how to find the installed contract, select components, and apply the same Rails and Hotwire conventions across features.

## Start from the installed version

From the application root, run:

```sh
bundle show nitro_kit
```

Read this guide from that directory, then consult only the reference needed for the task:

| Task                                        | Read next                                 |
| ------------------------------------------- | ----------------------------------------- |
| Rails models, routes, CRUD, and tests       | `docs/rails_conventions.md`               |
| Authentication, teams, shell, and settings  | `docs/patterns/application_foundation.md` |
| Build a complete product resource           | `docs/patterns/crud_resource.md`          |
| Choose or compose UI                        | `docs/component_contracts.md`             |
| Rails assets, forms, and application shells | `docs/rails_integration.md`               |
| Turbo, Frames, Streams, morphs, or Stimulus | `docs/hotwire.md`                         |
| Browser support or progressive fallback     | `docs/browser_support.md`                 |
| Theme tokens and application composition    | `docs/customization.md`                   |
| Upgrade an existing Nitro Kit 1.x app       | `docs/migration_1_to_2.md`                |
| Query, sort, filter, or paginate            | `docs/patterns/queryable_collection.md`   |
| Create, update, and show validation         | `docs/patterns/resource_form.md`          |
| Delete, revoke, archive, or confirm         | `docs/patterns/destructive_action.md`     |
| Flash messages and notifications            | `docs/patterns/flash_and_toast.md`        |
| Edit and cancel inside a page               | `docs/patterns/inline_edit.md`            |

The installed component source is the final authority for constructor and compound-method details. This guide describes Nitro Kit 2.x. Do not use an API remembered from Nitro Kit 1.x or another installed version.

Before changing a Nitro Kit 1.x application, read the dedicated
[`1.x to 2.x migration guide`](migration_1_to_2.md).

## Choose the application view architecture deliberately

In a greenfield application, install Phlex before building the interface:

```sh
bin/rails generate phlex:install
```

Use Phlex as the primary view layer: keep the application layout, route-level
views, and reusable UI in Phlex rather than adding ERB wrappers whose only job
is to render a component. Render route-level `Views::*` objects from
controllers and keep shared product UI in the application's component
namespace.

An established application is one that already has meaningful views and layout
conventions, regardless of its Rails version or chronological age. Preserve
that architecture. Introduce Phlex and Nitro Kit at the requested boundary and
expand them incrementally; do not convert the application layout or unrelated
views unless an application-wide migration is explicitly authorized. When an
application is already Phlex-first, continue using Phlex for new layouts and
route views.

## Select the highest-level matching component

Prefer the component that owns the whole region, then compose smaller components inside it.

| Product need                     | Begin with                                                    |
| -------------------------------- | ------------------------------------------------------------- |
| Application chrome               | `AppShell`, `AppNavigation`, `CommandPalette`                 |
| Authentication page              | `AuthShell`                                                   |
| Settings navigation              | `SettingsLayout`                                              |
| Team or account administration   | `AppShell`, `Toolbar`, `Table`, `SettingsSection`             |
| App page title and basic actions | `AppShell`, then `Toolbar`                                    |
| Content-led page introduction    | `PageHeader`                                                  |
| Data region                      | `DataSection`, then `Table` or `EmptyState`                   |
| Queryable tabular data           | `Table`, `Toolbar`, `PaginationBar`                           |
| Model-backed form                | `SettingsSection`, Rails `form_with`, `NitroKit::FormBuilder` |
| Destructive settings             | `DangerZone`, optionally `Dialog`                             |
| Transient server feedback        | `Toast::FlashMessages`                                        |
| Rendered Markdown or rich text   | `Container`, then `Typeset`                                   |
| General grouping                 | `Card`, `Flex`, `Grid`, `Container`                           |

Application-specific product UI belongs under the application's namespace and composes Nitro components. Nitro owns component markup, styles, accessibility structure, and narrowly scoped progressive behavior. The application owns product policy, records, routes, authorization, queries, DOM IDs, and server responses.

For admin CRUD, treat the starter and entitled flows as complete compositions:
use toolbar Back links on child routes, keep deletion on edit, keep status in
the details flow, implement full invitation and membership management, and use
native links for settings destinations. Do not stop after rendering a screen
that only looks structurally similar.

## Use one interaction grammar

Choose the smallest primitive that completes the interaction:

1. Ordinary Rails links and forms under Turbo Drive.
2. A Turbo Frame for one independently navigable or replaceable region.
3. A request-scoped Turbo Stream response when one action changes multiple regions.
4. A broadcast only when other sessions must receive the change.
5. Application Stimulus only for browser-only behavior the preceding layers cannot express.

Successful non-GET HTML submissions redirect with `303 See Other`. Invalid form submissions render the same invalid model with `422 Unprocessable Entity`. GET parameters remain the source of truth for queryable collections. Frame identifiers come from `dom_id` or one named constant shared by rendering, responses, and tests.

## Stay inside the public boundary

- Include `NitroKit` once in the application's base Phlex component and use
  capitalized Kit methods such as `Button(...)` and `Card(...)`.
- Use the scoped `NitroKit::Button(...)` form when inclusion is not appropriate.
- Use an explicit constructor such as `Button.new(...)` only when another API
  needs a component object; Kit methods render immediately.
- Select `NitroKit::FormBuilder` explicitly from Rails `form_with`.
- Put a standalone form's visible fields, submit control, and related links
  inside `form.group`; hidden fields may remain before the group.
- Parents own rhythm. Wrap stacked fields in `FieldGroup` — as
  `render NitroKit::FieldGroup.new { ... }`, or `form.group` inside a
  `form_with` block. Two Fields, or a Field and its submit Button, rendered as
  bare siblings of a `form` or a plain `div` have no gap between them at all.
  Use `Flex` or `Grid` instead only when the arrangement is deliberately
  inline or multi-column.
- Use component options, compound declarations, layouts, and documented `--nk-*` theme properties.
- Keep an HTML fallback for every Turbo form flow.
- Treat that HTML response as a Turbo transport fallback, not automatically a
  JavaScript-free interaction; use `docs/browser_support.md` for the canonical
  component classifications.
- Test semantic output and stable owned attributes.

Do not copy component source, add `nk_*` helpers, invent a general ERB bridge, mutate Nitro-owned Stimulus controllers, or pass `class:` and `style:`. The intentionally loud `desperately_need_a_class:` escape exists only for external integrations that require a class hook.

## Application `AGENTS.md`

Install the durable project instruction and local skills from the consuming
application root:

```sh
bin/rails generate nitro_kit:install
```

The installer preserves application-owned content around a bounded Nitro Kit 2
block in `AGENTS.md` and adds project-local Rails, Hotwire, and UI skills for
supported agents. The skills deliberately resolve the installed gem first, so
upgrading the gem upgrades the instructions they use. Re-run the generator
after an upgrade; it never copies component or controller source.
