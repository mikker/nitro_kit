# Verify Nitro Kit 2 setup in this Rails application

**Audience:** Coding agent running immediately after Nitro Kit installation.

1. Run `bundle show nitro_kit` and confirm the resolved version starts with
   `2.`.
2. Choose the project-local Nitro Kit skill matching the task. It will resolve
   and read the installed, version-matched `docs/agent_guide.md`.
3. Inspect the application before editing. Preserve established view, asset,
   authentication, and testing conventions unless the task changes them.
4. For a greenfield application, run `bin/rails generate phlex:install` and use
   Phlex for the application layout, route views, and reusable UI. In an
   established application, introduce Phlex only at the requested boundary.
   Do not perform an application-wide migration unless it is explicitly
   authorized.
5. Verify that the application loads Nitro Kit CSS, the appearance bootstrap,
   Turbo, Stimulus, and the normal Stimulus controller loader. Never copy Nitro
   components or `nk--*` controllers into the application.
6. Verify one application base component includes `NitroKit`, and model-backed
   forms select `NitroKit::FormBuilder` explicitly.
7. Run `bin/rails nitro_kit:doctor`, fix actionable failures, and run the
   application's relevant tests.

If this is a Nitro Kit 1.x migration, stop and follow
`docs/migration_1_to_2.md` from the installed gem. Replace a control only when
2.x provides a genuine semantic and behavioral equivalent. Otherwise preserve
it as application-owned Rails and semantic HTML. Never retain copied Nitro Kit
1.x source as the fallback.

Report changes, preserved conventions, unsupported controls, and unresolved
decisions.
