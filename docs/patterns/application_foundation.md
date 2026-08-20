# Application foundation

**Audience:** Coding agents and developers starting an authenticated,
team-aware Nitro Kit application.

## Summary

- Model `User`, `Team`, and `Membership`; roles belong to memberships, and
  tenant-owned records load through `Current.team`.
- Use one `AppShell` for the authenticated product and one application-owned
  content gutter inside `shell.main`.
- Put route titles and persistent actions in the shell `Toolbar`; keep
  destinations in `AppNavigation`.
- Use links for settings destinations and one layout-level
  `Toast::FlashMessages` region for server feedback.

## Membership and current context

Create the first team and owner membership in the same transaction as signup.
Set `Current.user`, `Current.membership`, and `Current.team` from the session.
Use `Current.user` for authorship and audit fields; scope tenant data through
the team. Protect the last owner in the model.

Invitations belong to a team, record inviter and role, expire, and match the
invited email. Existing and new users should share one acceptance path.

## Authenticated shell

Use one `AppShell`, normally `layout: :hybrid`, for authenticated routes.
`AppNavigation` owns brand and destinations; a `Toolbar` in `shell.topbar`
owns the route's single `h1` and persistent actions. One wrapper inside
`shell.main` owns responsive page padding. Do not add another viewport-height
or outer-padding rule in child pages.

Application code owns destinations, authorization, and current-route policy.
Nitro owns responsive disclosure and focus behavior. Put infrequent account
destinations after `navigation.spacer`. Add one `CommandPalette` only when the
destination count warrants search, and render only authorized routes.

Use `AuthShell` with Rails `form_with` and `NitroKit::FormBuilder` for
authentication. Put visible fields, submit, and recovery link in one
`form.group`.

## Settings and feedback

Render `SettingsLayout` inside the normal shell. Settings destinations are
links with `aria-current="page"`, not Buttons. Use `SettingsSection` only for
distinct form regions; do not wrap every subsection in a Card or repeat the
route title.

Render `NitroKit::Toast::FlashMessages` once in the application layout. Keep
ordinary Rails flash and `303 See Other` redirects. Use the dedicated
[destructive action](destructive_action.md) and
[flash](flash_and_toast.md) patterns for those flows.

## Acceptance checklist

- Signup or sign-in selects a membership and team.
- Cross-team records cannot be loaded.
- Owner, administrator, and member policy differs where intended.
- Populated, empty, invalid, narrow, settings, and destructive states work.
- Successful mutations redirect with `303`; invalid forms render with `422`.
