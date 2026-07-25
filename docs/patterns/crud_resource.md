# A complete product resource

Build CRUD as one coherent product surface, not independent generated screens.
Before writing the views, name the resource, tenant boundary, actor, lifecycle,
visibility rules, and states. Implement index, form, detail, destructive action,
and their tests together.

## Use the hybrid application frame

An authenticated admin area defaults to `AppShell(layout: :hybrid)`. Nitro Kit
owns the desktop sidebar, mobile menu button, navigation dialog, focus behavior,
and responsive transition. The application provides destinations and current
state.

Put a `Toolbar` in `shell.topbar`. Its leading region contains the route's one
`h1`; its trailing region contains basic actions such as New, Edit, Cancel,
Save, Publish, or View. A Button outside a form can submit it through the
native `form:` attribute. This keeps the same action hierarchy on narrow and
wide screens without custom JavaScript.

```ruby
AppShell(id: "admin", layout: :hybrid) do |shell|
  shell.navigation { render admin_navigation }
  shell.topbar do
    Toolbar do |toolbar|
      toolbar.leading { h1 { page_title } }
      toolbar.trailing do
        Button(
          "Save",
          type: :submit,
          form: dom_id(@post, :form),
          variant: :primary
        )
      end
    end
  end
  shell.main do
    div(data: { ui: "admin-main" }) do
      Container(size: :xl) { render page }
    end
  end
end
```

Child routes add one compact Back link before the title. Prefer an icon-only
Button with an explicit label such as `aria: { label: "Back to projects" }`.
Do not repeat that navigation as a trailing Cancel action.

The application stylesheet gives `admin-main` one responsive padding rule.
Child pages do not add another outer gutter. `Container` constrains measure;
it does not own page padding.

Do not add viewport height or another outer padding rule to `admin-main`; the
shell owns viewport geometry and the wrapper owns the one page gutter. Use the
same shell and gutter on team administration and settings routes.
Place a bottom-anchored Settings destination after `AppNavigation#spacer`, then
compose settings subsections with `SettingsLayout` and plain `FormSection`
regions. Settings destinations are links with `aria-current`, not action
Buttons. Read `application_foundation.md` for the complete application frame.

## Spend hierarchy once

- One route, one `h1`, normally in the shell toolbar.
- Add an `h2` only for a genuinely separate region.
- Do not repeat “Posts” in the toolbar, `PageHeader`, `DataSection`, Card, and
  visible table caption.
- Use `PageHeader` for a content-led introduction, not as mandatory CRUD
  ceremony under an existing toolbar.
- Prefer whitespace and dividers. Use Card only for a bounded object that
  benefits from its own surface. Never default to Card inside Card.

An index begins with a short introduction only if it adds useful context, then
renders its table and pagination directly. Use `DataSection` when a page has
multiple independently named datasets. At zero records, replace the data region
with one intentional `EmptyState`; keep the primary New action in the toolbar.

A new or edit page begins with `FormSection`. Use one form component for new,
edit, and invalid renders. Put the primary submit in the toolbar by setting the
button's `form:` to the form's stable DOM ID. Invalid submissions render the
same model and form with `422 Unprocessable Entity`. The toolbar owns that
action: do not render a second Save or Create submit inside the form body.

A detail page begins with status or stable metadata, then the resource itself.
Keep status inside that normal details flow instead of detaching it into a
second side panel.
Use the authenticated `show` route as the operational detail or draft preview.
Put lifecycle forms in the page and associate their toolbar buttons with
`form:`. Put destructive confirmation in one separate `DangerZone` on edit,
with a safe escape back to the record. Do not make every show page end in a
large deletion surface.

## Model and route the lifecycle

Scope every lookup through `Current.team` or `Current.account`. Record
`Current.user` as author, creator, or publisher. If a state has provenance,
timing, or behavior, model it as a record and expose it as a noun resource:

```ruby
namespace :admin do
  resources :posts do
    resource :publication,
      only: %i[create destroy],
      module: :posts
  end
end
```

The main controller keeps the seven REST actions. Successful mutations redirect
with `303 See Other`. Publication create and destroy invoke domain methods and
redirect. Public controllers query published records only. Ordinary Rails forms
and Turbo Drive are the default; do not add fetch code for CRUD submissions.

## Ship the acceptance path

Request tests cover tenant isolation, public visibility, successful `303`
redirects, invalid `422` renders, pagination, and lifecycle resources. Rendering
assertions should also protect the high-level composition: hybrid AppShell,
one `h1`, navigation, toolbar action, actual form association, table or empty
state, and destructive confirmation. Add one browser test for the meaningful
end-to-end path, using Capybara waiting assertions instead of sleeps.

Assert that each primary action has one visible control. A toolbar-associated
form submit plus an identical body submit is duplication, even when both invoke
the same valid form.

Before finishing, inspect a populated index, empty index, invalid form, narrow
form, draft detail, published detail, and edit-owned destructive dialog. Remove any extra
heading, surface, wrapper, or page gutter that does not communicate information.
