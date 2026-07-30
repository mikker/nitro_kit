# Migrating a Nitro Kit 1.x application

Treat a 1.x migration as a product-flow review, not a helper rename. Nitro Kit
2 deliberately removed copied components, `nk_*` helpers, application-owned
`controllers/nk`, and unrestricted utility-class customization.

## Pin the prerelease before migrating

During the Nitro Kit 2 prerelease, use a reviewed full Git commit rather than a
moving branch or a loose prerelease dependency:

```ruby
NITRO_KIT_REVIEWED_COMMIT = "REPLACE_WITH_FULL_REVIEWED_COMMIT_SHA"

gem "nitro_kit",
  git: "https://github.com/mikker/nitro_kit.git",
  ref: NITRO_KIT_REVIEWED_COMMIT
```

Replace the placeholder with the complete 40-character SHA you reviewed; do
not run Bundler with the placeholder. Verify that revision contains every
component, migration rule, and installer behavior the migration will rely on.
Advance only after reviewing a newer revision: replace the SHA, run
`bundle update nitro_kit`, rerun the installer and doctor, exercise the
converted flows, and commit `Gemfile` with `Gemfile.lock`. Never use a moving
branch for production. This guidance applies only to prereleases; switch to a
normal released-version constraint once Nitro Kit 2 is stable.

## Inventory behavior before editing

1. List every `nk_*` helper, `NitroKit::*` component, copied Nitro source file,
   and `controllers/nk` controller.
2. Group usage by user flow: authentication, settings, collection browsing,
   mobile navigation, editing, destructive actions, notifications, and
   copy/share controls.
3. Record behavior that must survive: native element, submitted method and
   parameters, Turbo target, accessible name and description, focus behavior,
   narrow-screen presentation, empty/error state, and visual density.
4. Capture representative wide and narrow screenshots before conversion.

If the Nitro Kit MCP catalog is connected, search it by workflow after this
inventory — for example `mobile transcript navigation`, `settings form`, or
`empty query results`. Do not search only for an old component name. MCP can
deliver complete compositions; the installed gem remains the authority for
the free component contract.

## Select semantics before atoms

Map each flow to the highest-level matching 2.x component first:

| Existing need                           | Begin with                              |
| --------------------------------------- | --------------------------------------- |
| Sign-in or recovery card                | `AuthShell`                             |
| Application navigation                  | `AppShell`, `AppNavigation`             |
| Mobile contextual navigation or details | `Sheet`                                 |
| Settings screen                         | `SettingsLayout`, `FormSection`         |
| Empty collection card                   | `EmptyState`                            |
| Data collection                         | `DataSection`, `Table`, `PaginationBar` |
| Destructive settings                    | `DangerZone`, `Dialog`, `ButtonTo`      |
| Joined copy or filter controls          | `ControlGroup`                          |

Only then replace remaining atoms. Common direct mappings include:

- `nk_button_link_to` → `NitroKit::Button.new(..., href:)`
- `nk_button_to` → `NitroKit::ButtonTo.new(..., href:, method:)`
- `nk_form_with` → Rails `form_with(..., builder: NitroKit::FormBuilder)`
- block-wrapped tooltips → a linked Button trigger or Tooltip `as: :custom`
- copied mobile Sidebar → `Sheet`, not a plain disclosure

Do not preserve a Card merely because 1.x used one. Empty states,
authentication shells, settings regions, and data sections have stronger
semantics and more useful responsive behavior.

## Preserve unsupported behavior honestly

When no equivalent exists, keep semantic Rails or HTML under the application
namespace and report the missing capability. Do not retain copied 1.x source,
downgrade a specialized control, or hide the gap behind a generic component.

Tooltip custom triggers are the explicit composition path for an existing
focusable control. Forward every yielded boundary to that actual control:

```ruby
render NitroKit::Tooltip.new(id: "revoke-help", content: "Revokes access immediately") do |tooltip|
  tooltip.trigger(as: :custom) do |attributes|
    render NitroKit::ButtonTo.new(
      "Revoke",
      href: token_path(token),
      method: :delete,
      variant: :destructive,
      button_html: attributes.html,
      button_aria: attributes.aria,
      button_data: attributes.data
    )
  end
end
```

## Verify fidelity

Run focused request and component tests, then compare the converted flows in a
browser at wide and narrow widths. Exercise keyboard focus, dialogs and sheets,
Turbo submissions, errors, empty states, light/dark appearance, and dense
metadata. A green request suite does not prove that a tooltip, off-canvas
panel, interactive Card treatment, or responsive composition survived.

Finish by deleting copied components, helpers, and controllers; run
`bin/rails nitro_kit:doctor`; and record every remaining application-owned
fallback as either intentional product UI or a Nitro Kit coverage gap.

Doctor inventories only concrete Nitro Kit 1.x conventions: `nk_*` helpers,
generated files under `app/components/nitro_kit`, controllers under
`app/javascript/controllers/nk`, the old Floating UI and combobox packages,
and `tailwind_merge`. Every finding includes a file and replacement. Its
disposition is:

- `migrated` — no remaining occurrence in that category.
- `unresolved` — a known 1.x integration still needs its documented 2.x
  replacement or removal.
- `application-owned` — custom or unsupported behavior must be preserved under
  an application namespace, not as a Nitro shadow.

The inventory deliberately does not guess from generic component, JavaScript,
or dependency names. Review application-owned product behavior separately and
keep its migration record with the application.
