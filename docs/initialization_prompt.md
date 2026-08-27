# Verify Nitro Kit 2 setup in this Rails application

**Audience:** Coding agent running immediately after Nitro Kit installation.

1. Run `bundle show nitro_kit` and confirm the resolved version starts with
   `2.`.
2. Choose the project-local Nitro Kit skill matching the task. It will resolve
   and read the installed, version-matched `docs/agent_guide.md`.
3. For greenfield planning or broad product work, check whether Nitro Kit
   catalog or MCP tools are available. When available, inventory and search by
   product workflow, retrieve relevant patterns, and state what will be used,
   adapted, or deferred. When unavailable, continue with the bundled guidance;
   catalog access is optional and must never block the work.
4. Inspect the application before editing. Preserve established view, asset,
   authentication, and testing conventions unless the task changes them.
5. For a greenfield application, run `bin/rails generate phlex:install` and use
   Phlex for the application layout, route views, and reusable UI. In an
   established application, introduce Phlex only at the requested boundary.
   Do not perform an application-wide migration unless it is explicitly
   authorized.
6. Verify that the application loads Nitro Kit CSS, the appearance bootstrap,
   Turbo, Stimulus, and the normal Stimulus controller loader. Never copy Nitro
   components or `nk--*` controllers into the application.
7. Verify one application base component includes `NitroKit`, and model-backed
   forms select `NitroKit::FormBuilder` explicitly.
8. Run `bin/rails nitro_kit:doctor`, fix actionable failures, and run the
   application's relevant tests. Doctor verifies Nitro Kit integration, not
   whether the product implements every relevant workflow.

If this is a Nitro Kit 1.x migration, stop and follow
`docs/migration_1_to_2.md` from the installed gem. Replace a control only when
2.x provides a genuine semantic and behavioral equivalent. Otherwise preserve
it as application-owned Rails and semantic HTML. Never retain copied Nitro Kit
1.x source as the fallback.

Report changes, preserved conventions, unsupported controls, and unresolved
decisions.
