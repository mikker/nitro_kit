---
name: nitro-kit-rails
description: "Build or refactor Nitro Kit 2 Rails application features on one conventional path: REST noun resources, tenant-scoped records, rich domain models, state records, standard forms and responses, Minitest fixtures, and server-rendered HTML. Use for CRUD, authentication-adjacent application structure, teams or accounts, publication and other lifecycle state, controllers, models, routes, authorization boundaries, and tests in an application that uses Nitro Kit."
---

# Nitro Kit Rails

Use the Rails conventions shipped with the application's installed Nitro Kit
version. Treat them as the greenfield default, not a reason to rewrite an
established application outside the requested scope.

## Load the installed path

1. Work from the Rails application root.
2. Confirm `nitro_kit` appears in `Gemfile.lock` at version 2.x.
3. Run `bundle show nitro_kit` and treat its output as `NITRO_KIT_ROOT`.
4. Read `NITRO_KIT_ROOT/docs/agent_guide.md` completely.
5. Read `NITRO_KIT_ROOT/docs/rails_conventions.md` completely.
6. For a complete product resource, read
   `NITRO_KIT_ROOT/docs/patterns/crud_resource.md` completely.
7. For authentication, teams, application navigation, or settings, read
   `NITRO_KIT_ROOT/docs/patterns/application_foundation.md` completely.
8. Read the matching Hotwire recipe before implementing an interaction.
9. Read `NITRO_KIT_ROOT/docs/browser_support.md` before claiming an
   interaction works without JavaScript.

Never use a Nitro Kit 1.x helper, copied component, controller, or Tailwind
contract as a substitute for the installed API.

## Follow the application grammar

- Scope tenant data through `Current.team` or `Current.account`; record
  `Current.user` as the actor.
- Put domain behavior on the model before introducing another abstraction.
- Model meaningful lifecycle state as a record and expose it through a noun
  resource instead of a custom controller verb.
- Keep controllers focused on scoped loading, one domain operation, and one
  conventional response.
- Use Rails `form_with` with `NitroKit::FormBuilder`.
- In an existing application, replace a form control only when Nitro Kit has a
  genuine semantic and behavioral equivalent. Otherwise preserve it as
  application-owned Rails and semantic HTML, including its names, values,
  errors, accessibility, uploads, and browser behavior. Do not retain copied
  Nitro Kit 1.x source as the fallback.
- Redirect successful mutations with `303`; render invalid models with `422`.
- Render HTML on the server and add Hotwire progressively.
- Set the document language on the root `html` element.
- Test with Minitest and fixtures, including tenancy and unhappy paths.
- In authenticated admin areas, default to a hybrid `AppShell` with the route's
  one `h1` and basic actions in its `Toolbar`. Keep one page gutter and avoid
  repeated headings or automatic Card wrappers. At narrow widths, let trailing
  actions stack below a Back affordance and title instead of clipping the title
  or hiding persistent actions.
- In a new team-aware application, create the first user's `Team` and owner
  `Membership` together. Put roles on memberships and scope product records
  through `Current.team`.

Preserve a clear ownership boundary: Rails owns product policy and records;
Nitro Kit owns component contracts and focused progressive behavior.

## Verify

Run focused model and request tests first. Add a system test only where browser
behavior is part of the contract. Assert status, visibility, authorization,
and stable DOM boundaries rather than implementation trivia.
