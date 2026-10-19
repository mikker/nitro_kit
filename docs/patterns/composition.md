# Page composition checklist

**Audience:** Coding agents composing a page from Nitro components, a catalog
pattern, or retrieved source. Run this checklist on every page you add or
change, in addition to the pattern's own verification.

## Summary

- Correct components do not make a coherent page; each rule below names one
  owner for a decision that otherwise ends up made twice or not at all.
- One application-owned element owns the page gutter, and one shell toolbar
  owns the page title.
- Keep at most one primary action per view and demote destructive actions out
  of row-level prominence.
- Verify populated, empty, invalid, and narrow states before calling a page
  done.

## Checklist

1. **One gutter owner.** Exactly one application-owned element inside
   `shell.main` (or the host layout's main region) owns page padding: 24px on
   desktop, 16px on narrow screens. Child pages, Cards, and Containers add no
   outer padding of their own. A page with no gutter is as wrong as a page with
   two. Tables fill the gutter; forms and reading content use a centered
   `Container(size: :md)` or `Container(size: :lg)` inside it.
2. **Clear action hierarchy.** At most one `primary` Button per view, normally
   in the shell `Toolbar`. Other actions use the default treatment, never
   ghost. Destructive actions are demoted out of row-level prominence:
   - Repeated table rows carry at most one or two plain actions such as View
     or Edit. Put deletion on the edit route's `DangerZone`, or behind a
     default-treatment Dialog trigger or a Dropdown item when a row really
     needs it (invitation revocation, member removal).
   - `variant: :destructive` belongs inside an edit route's `DangerZone` and
     on the confirming submit of a Dialog, never on repeated row triggers.
   - Index, list, and detail pages show no destructive-treatment button before
     the user has chosen to change or remove something.
3. **Every state is designed.** Render and inspect populated, empty
   (`EmptyState` with the creating action), invalid (422 with field errors and
   an error summary), and narrow (390px: no document overflow, title and
   persistent actions visible, Table scrolls inside its own wrapper) states.
   Long names and many rows are part of populated.
4. **One title scale.** The route has one `h1`, owned by the shell `Toolbar`
   or the host layout's page header, at the same size on every route. Section
   headings step down consistently (`SettingsSection`, `DataSection`, Card
   titles); do not repeat the route title in a `PageHeader` or Card, and do
   not invent per-page heading sizes.

## How to check

- Count padded ancestors between `main` and the first piece of content: there
  should be exactly one.
- Count `primary` and `destructive` Buttons visible on first render: at most
  one of each, and destructive ones only on routes the user opened to change
  or remove something.
- Load the empty collection, submit an invalid form, and resize to 390px
  before calling the page finished.
- Compare the `h1` size and position with a neighboring route.

See [Application foundation](application_foundation.md) for shell ownership,
[CRUD resource](crud_resource.md) for route composition, and
[Destructive action](destructive_action.md) for confirmation mechanics.
