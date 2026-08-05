---
name: nitro-kit-hotwire
description: Implement or refactor Nitro Kit 2 Hotwire interactions using conventional Turbo Drive, Frame, Stream, morph, form, dialog, flash, and toast patterns. Use for CRUD forms, validation, filtering, sorting, pagination, destructive confirmations, inline editing, self-submitting controls, server-rendered notifications, or any Nitro Kit interaction that should work progressively without copied controllers or custom request JavaScript.
---

# Nitro Kit Hotwire

Make the server response and stable DOM boundary the interaction API. Add Stimulus only for behavior the browser, Rails, and Turbo cannot express.

## Load the matching recipes

1. Work from the Rails application root.
2. Confirm `nitro_kit` appears in `Gemfile.lock`.
3. Run `bundle show nitro_kit` and treat its output as `NITRO_KIT_ROOT`.
4. Read `NITRO_KIT_ROOT/docs/agent_guide.md` completely.
5. Read `NITRO_KIT_ROOT/docs/hotwire.md`, then only the matching files under `NITRO_KIT_ROOT/docs/patterns/`:
   - query/filter/sort/paginate: `queryable_collection.md`
   - create/update/validation: `resource_form.md`
   - delete/revoke/archive confirmation: `destructive_action.md`
   - notices/errors after responses: `flash_and_toast.md`
   - row or panel edit/cancel: `inline_edit.md`
   - application-wide confirmation and settings forms:
     `application_foundation.md`
6. Inspect the installed Nitro component contract used by the recipe. Never assume a recipe from another version still matches.
7. Read `NITRO_KIT_ROOT/docs/browser_support.md` for the canonical
   full/reduced/unavailable no-JavaScript classification.

Do not proceed with a remembered Nitro Kit 1.x API. Do not copy or recreate
the installed gem's `nk--*` controllers under `app/javascript/controllers/nk`.

## Choose the smallest Hotwire primitive

1. Start with ordinary Rails navigation and forms under Turbo Drive.
2. Add a Turbo Frame when one stable region has an independent navigation or form lifecycle.
3. Return Turbo Streams over the request when one action must update multiple existing regions.
4. Broadcast only when other sessions need the update.
5. Add an application Stimulus controller only for client-only state or browser behavior not covered above.

Keep frames around complete resource or collection regions, not individual buttons. Derive IDs with Rails `dom_id` or a named constant and use the same identifier in links, forms, responses, and tests.

## Keep response semantics conventional

- Redirect successful non-GET form submissions with `303 See Other`.
- Render invalid HTML and Turbo submissions with `422 Unprocessable Entity` and the same invalid model instance.
- Preserve an HTML response branch as the progressive fallback.
- Do not describe that HTML branch as a JavaScript-free interaction when its
  control still depends on Turbo or a closed overlay.
- Let GET query parameters be the source of truth for filtering, sorting, and pagination.
- Use native Nitro Dialog behavior for reviewed destructive actions. Use `data: { turbo_confirm: ... }` for compact confirmations that do not need a dialog.
- Render flash through `NitroKit::Toast::FlashMessages`; the application owns setting the flash.

## Preserve ownership

- Nitro owns component markup, CSS, and its focused progressive controllers.
- Rails owns routes, records, authorization, query policy, validation, DOM identity, and responses.
- Hotwire owns transport and replacement.
- Application Stimulus owns only application-specific browser behavior.

Do not create a universal interaction controller, hide server behavior inside a UI component, or use Turbo Streams for a single replacement that a frame already handles.

## Verify end to end

Cover the HTML fallback and Turbo response in request tests. Add a system test when focus, dialog behavior, frame navigation, or multiple DOM updates are central to the interaction. Assert response status and stable frame or target IDs, not Turbo internals.

Some headless browser sessions throttle `requestAnimationFrame`, which Turbo
uses before rendering a completed visit. If a request succeeds but the page or
frame never renders only in automation, reproduce it in a Rails system test
before changing application code. Disable Chrome's background throttling or
use a test-only `requestAnimationFrame` shim when necessary. Never ship that
workaround in the application or replace a conventional Turbo flow to satisfy
one browser driver.
