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

Use `AppShell(layout: :hybrid)` for an authenticated product area. Put the
route's one `h1` and persistent actions in the topbar `Toolbar`. Child routes
place one compact Back link before the title. One wrapper inside `shell.main`
owns page padding; child pages add no outer gutter.

| Route                 | Composition                                                                                                             |
| --------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| Index                 | Optional short introduction, then Table or EmptyState and pagination. Use DataSection only for multiple named datasets. |
| New/Edit              | One `SettingsSection` and one shared form component. A toolbar submit targets the form's stable `form:` ID.             |
| Show                  | Status or metadata, then the resource. Keep lifecycle actions in the normal detail flow.                                |
| Edit destructive area | One `DangerZone` with a safe escape. Do not put permanent deletion on every show page.                                  |

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
