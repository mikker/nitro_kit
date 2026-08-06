# A durable application foundation

Start a small authenticated application with the same records and page grammar
it will need after the second person joins. The first-user case should be the
smallest instance of the team model, not a separate personal mode that must be
replaced later.

## Summary

- Model `User`, `Team`, and `Membership` from the first signup; role belongs to
  `Membership`, and every team-owned record loads through `Current.team`.
- One hybrid `AppShell` frames the authenticated product: `AppNavigation` owns
  brand and destinations, the shell `Toolbar` owns route titles and persistent
  basic actions.
- One wrapper immediately inside `shell.main` owns responsive page padding for
  every route; the shell owns viewport height and scrolling.
- Infrequent account destinations go after `navigation.spacer`; settings
  compose with `SettingsLayout` and plain `FormSection` regions.
- When destination count warrants search, compose one `CommandPalette` in the
  shell and render only routes the current membership may visit.
- Centralize cross-cutting feedback in one flash-driven toast region rendered
  by the layout, and set the document language on the root `html` element.

## Use memberships from the first user

Use `User`, `Team`, and `Membership` even when signup creates exactly one of
each. Put the role on `Membership`, not `User`, because authority belongs to a
person's relationship with a team. Create the first team and owner membership
in the same transaction as signup.

Set `Current.user`, `Current.membership`, and `Current.team` from the session.
Load every team-owned record through `Current.team`; use `Current.user` for
authorship and audit fields. Start with the smallest role vocabulary the
product needs, usually owner, administrator, and member. Protect the last owner
in the domain model rather than only hiding a button.

Invitations should belong to a team, record the inviter and intended role,
expire, match the invited email, and be consumed when accepted. An existing
user accepts into a new membership; a new user completes signup and then uses
the same acceptance path.

## Compose one authenticated frame

Use one hybrid `AppShell` for the authenticated product. Keep the brand and
primary destinations in `AppNavigation`; place route titles and persistent
basic actions in the shell `Toolbar`. One wrapper immediately inside
`shell.main` owns responsive page padding for every route. The topbar and
sidebar header should use the shell's shared height and border tokens rather
than independent padding guesses. At narrow widths, allow trailing actions to
stack below the Back affordance and title so neither the title nor persistent
actions are clipped.

Put infrequent account navigation after `navigation.spacer`, near the account
controls at the bottom of the sidebar:

```ruby
shell.navigation do
  AppNavigation(label: "Workspace navigation") do |navigation|
    navigation.body do
      navigation.item("Inventory", href: assets_path, icon: :archive)
      navigation.item("Team", href: team_path, icon: :users)
      navigation.spacer
      navigation.item("Settings", href: settings_profile_path, icon: :settings)
    end
  end
end
```

Application code owns destinations and current-route policy. Nitro owns shell
layout, mobile disclosure, focus management, and navigation semantics.
For larger products, place one `CommandPalette` in the shell. Its native links
remain the navigation authority while Command-K or Control-K adds fast
filtering. Render the same authorized destination set the user can reach in
ordinary navigation; do not use the palette to bypass route policy.
When the destination set is too large or dynamic to render eagerly, pass
`search_url:` and return `CommandPalette::Results` from that endpoint. Keep the
same authorization scope on the initial links and every remote query.
Let the shell own viewport height and scrolling; do not add `min-height: 100vh`
to its main region or page wrapper. Put brand and destination icons through the
navigation slots so they share the same left alignment.

Team is an administration surface, not merely a roster. Include pending
invitations and the complete invite, role-change, removal, and revoke paths,
with last-owner protection in the model and authorization on every mutation.

Authentication is a standalone form surface. Inside `AuthShell`, use Rails
`form_with` with `NitroKit::FormBuilder` and put the visible fields, submit
control, and related recovery link in one `form.group`. The group owns their
vertical rhythm; `AuthShell` owns only the page container and spacing between
its major regions.

## Keep settings plain

Use `SettingsLayout` inside the normal shell main region. Its navigation lists
stable subsections such as Profile, Notifications, Appearance, and Password;
its content renders the selected form. Use `FormSection` for genuinely distinct
form regions and ordinary whitespace or dividers between them.

Render subsection destinations as links and mark the active link with
`aria-current="page"`. They navigate between routes; Buttons and ButtonGroup
would incorrectly present them as in-page actions. Small preferences may
submit on change through a tiny application Stimulus controller that calls the
form's native `requestSubmit`. Keep a submit control in `noscript` so the form
still works without JavaScript.

The route still has one `h1` in the shell toolbar. Do not repeat “Settings” in
the page body, wrap each subsection in a Card, or give every form its own outer
padding. A toolbar Save button can submit the selected form with the native
`form:` attribute, so the action stays in the same place at narrow and wide
widths without JavaScript.

## Centralize cross-cutting feedback

Render `Toast::FlashMessages` once in the application layout. Keep using
ordinary Rails flash and `303 See Other` redirects from controllers.

Compact destructive actions should continue to declare
`data: { turbo_confirm: "…" }` and use Turbo's native browser confirmation.
When the user needs branded review UI or more context than one sentence,
compose a dedicated native Nitro `Dialog` at the action's call site. The
browser's top layer keeps that inline dialog clear of ancestor clipping and
stacking contexts. Put record deletion on the edit route rather than adding a
danger surface to every operational show page.

## Baseline acceptance path

Before polishing empty-state illustration or dashboard summaries, verify:

- signup or sign-in selects the current membership and team;
- another team cannot load the current team's records;
- owner, administrator, and member policy differs where intended;
- populated, empty, invalid, narrow, and destructive states work;
- settings forms preserve validation and use one content gutter;
- successful mutations redirect with `303` and invalid forms render with
  `422`;
- confirmation has both cancel and confirm coverage;
- the shell, headings, tables, and forms remain usable without custom request
  JavaScript.
