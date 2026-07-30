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

## Move ERB collections and yielded content into compound declarations

The ERB below is representative application-owned migration input, not a
Nitro Kit 2 API. Nitro Kit 2 has no ERB component bridge. Move the collection
to the Phlex component, then declare entries only inside their owning compound
region. Content formerly yielded by a partial belongs directly inside the
matching `panel` or `content` block.

### AppNavigation

ERB source — the call site owns the destination collection and the partial
iterates it:

```erb
<% destinations = [["Home", root_path], ["Projects", projects_path]] %>
<%= render "app_navigation", label: "Primary", destinations: destinations %>

<%# _app_navigation.html.erb %>
<nav aria-label="<%= label %>">
  <ul>
    <% destinations.each do |text, href| %>
      <li><%= link_to text, href %></li>
    <% end %>
  </ul>
</nav>
```

Phlex destination — declare the collection before `AppNavigation`; consume it
inside the required `body` collection region:

```ruby
destinations = [["Home", root_path], ["Projects", projects_path]]

render NitroKit::AppNavigation.new(label: "Primary") do |navigation|
  navigation.body do
    destinations.each_with_index do |(text, href), index|
      navigation.item(text, href:, current: index.zero?)
    end
  end
end
```

The executable minimal version is on the
[`AppNavigation` gallery page](/gallery/components/app-navigation#example-app-navigation-minimal).

### Dialog

ERB source — the call-site block is yielded inside the partial's panel:

```erb
<%= render "dialog", id: "transcript-details", title: "Transcript details" do %>
  <p>The transcript was recorded at 09:42 UTC.</p>
<% end %>

<%# _dialog.html.erb %>
<button command="show-modal" commandfor="<%= id %>-panel">Details</button>
<dialog id="<%= id %>-panel">
  <h2><%= title %></h2>
  <%= yield %>
</dialog>
```

Phlex destination — trigger and panel declarations live inside `Dialog`; the
former yielded content lives inside `panel`:

```ruby
render NitroKit::Dialog.new(id: "transcript-details") do |dialog|
  dialog.trigger("Details")
  dialog.panel(title: "Transcript details") do
    p { "The transcript was recorded at 09:42 UTC." }
  end
end
```

Placement belongs to the parent. In the conversion that exposed this rule, a
`Flex` containing **Redact** and **Permalink** was followed by a `Dialog`
sibling, so the Dialog trigger started a second line. Put the Dialog root
inside the same no-wrap action cluster:

```ruby
Flex(dir: :row, gap: 1, align: :center, wrap: :nowrap) do
  Button("Redact", size: :sm, variant: :destructive)
  Button("Permalink", href: transcript_path(transcript), size: :sm)

  Dialog(id: dom_id(transcript, :details)) do |dialog|
    dialog.trigger("Details", size: :sm)
    dialog.panel(title: "Transcript details") do
      render UI::TranscriptDetails.new(transcript)
    end
  end
end
```

The gallery runs this structure at narrow widths in
[`Narrow transcript actions`](/gallery/components/dialog#example-dialog-narrow-action-cluster).

### Sheet

ERB source — the partial yields contextual content into its side panel:

```erb
<%= render "sheet", id: "transcript-prompts", title: "Prompts" do %>
  <%= render "prompts", prompts: @prompts %>
<% end %>

<%# _sheet.html.erb %>
<button command="show-modal" commandfor="<%= id %>-panel">Prompts</button>
<dialog id="<%= id %>-panel">
  <h2><%= title %></h2>
  <%= yield %>
</dialog>
```

Phlex destination — declare the collection before `Sheet`; render it only
inside the `panel` content slot:

```ruby
prompts = transcript.prompts.map { |prompt| [prompt.title, prompt_path(prompt)] }

render NitroKit::Sheet.new(id: "transcript-prompts", side: :left) do |sheet|
  sheet.trigger("Prompts", icon: :list)
  sheet.panel(title: "Transcript prompts") do
    render NitroKit::AppNavigation.new(label: "Transcript prompts") do |navigation|
      navigation.body do
        prompts.each do |text, href|
          navigation.item(text, href:)
        end
      end
    end
  end
end
```

See the executable
[`Sheet` collection example](/gallery/components/sheet#example-sheet-constructions).

### SettingsLayout

ERB source — the call site supplies both the navigation collection and yielded
settings content:

```erb
<% sections = [["Profile", profile_settings_path], ["Security", security_settings_path]] %>
<%= render "settings_layout", sections: sections do %>
  <%= render "profile_form" %>
<% end %>

<%# _settings_layout.html.erb %>
<nav aria-label="Settings">
  <% sections.each do |text, href| %>
    <%= link_to text, href %>
  <% end %>
</nav>
<main><%= yield %></main>
```

Phlex destination — navigation entries stay inside `navigation`; the former
yield lives inside the one `content` region:

```ruby
sections = [["Profile", profile_settings_path], ["Security", security_settings_path]]

render NitroKit::SettingsLayout.new do |layout|
  layout.navigation(label: "Settings") do
    sections.each_with_index do |(text, href), index|
      layout.item(text, href:, current: index.zero?)
    end
  end
  layout.content { render UI::ProfileForm.new(profile) }
end
```

See the executable
[`SettingsLayout` minimal example](/gallery/components/settings-layout#example-settings-layout-cardinality-states).

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
