# Complete product resource

**Audience:** Coding agents and developers implementing a full Rails CRUD
resource with Nitro Kit.

## Summary

- Define the resource, tenant boundary, actor, lifecycle, visibility, and
  states before writing views.
- Build index, form, detail, destructive action, and tests as one product
  surface.
- Use one shell toolbar title and one application-owned page gutter; do not
  repeat hierarchy across nested components.
- Scope every lookup through the current tenant and model meaningful lifecycle
  transitions as noun resources.

## Resource map

Use `AppShell(layout: :sidebar)` for an authenticated product area. Put the
route's one `h1` and persistent actions in the topbar `Toolbar`. Child routes
place one compact Back link before the title. One layout element inside `shell.main`
owns page padding and vertical spacing; child pages add no outer gutter. For an inset treatment,
use [Inset workspace](inset_workspace.md) rather than adding padding to each
shell region. The shell owns gutters, not a universal maximum width. Let
indexes and tables fill the canvas; bound form or reading content locally with
a centered `Container(size: :md)` or `Container(size: :lg)` without extra padding.

| Route                 | Composition                                                                                                             |
| --------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| Index                 | Optional short introduction, then Table or EmptyState and pagination. Use DataSection only for multiple named datasets. |
| New/Edit              | One `SettingsSection` and one shared form component. A toolbar submit targets the form's stable `form:` ID.             |
| Show                  | Status or metadata, then the resource. Keep lifecycle actions in the normal detail flow.                                |
| Edit destructive area | One `DangerZone` with a safe escape. Do not put permanent deletion on every show page.                                  |

Keep all columns and View/Edit actions intact at 390px. Use Table's built-in
horizontal scroll wrapper as shown in [Queryable collection](queryable_collection.md).
Do not hide columns or stack row actions to squeeze the table into the viewport.

Use one primary action. Do not render the same Save or Create action in both
the toolbar and form body. Use Card only for a bounded object that benefits
from its own surface.

See [Resource form](resource_form.md),
[Destructive action](destructive_action.md), and
[Queryable collection](queryable_collection.md) for complete interaction
contracts.

## Lifecycle and responses

Scope lookups through `Current.team` or `Current.account`. Use
`Current.user` as actor. When state has timing, provenance, or behavior, model
it as a noun resource:

```ruby
resources :posts do
  resource :publication, only: %i[create destroy], module: :posts
end
```

Keep the main controller to REST actions. Successful mutations redirect with
`303 See Other`; invalid forms render the same model with `422 Unprocessable
Entity`. Public controllers query only publicly visible records.

## Acceptance checklist

Test tenant isolation, authorization, public visibility, lifecycle resources,
pagination, `303` redirects, and `422` validation. Protect the high-level
composition: one title, one primary action, the correct form association,
Table or EmptyState, and edit-owned destructive confirmation. Inspect
populated, empty, invalid, narrow, draft, published, and destructive states.

Avoid layout-only wrappers inside Toolbar.leading or Toolbar.trailing: these
regions already arrange their children. Render independent action Buttons
directly; use ButtonGroup only when the actions are intentionally a joined set.
