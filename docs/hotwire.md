# Hotwire with Nitro Kit

Nitro Kit owns component markup, CSS, and its focused progressive controllers.
Rails owns records, routes, authorization, queries, DOM identity, and server
responses. Hotwire transports server-rendered HTML between those boundaries.

## Choose the smallest interaction

1. Use ordinary links and forms under Turbo Drive.
2. Use a Turbo Frame for one independently navigable or replaceable region.
3. Return request-scoped Turbo Streams when one action changes multiple
   regions.
4. Broadcast only when another session needs the update.
5. Add application Stimulus only for browser-owned behavior the preceding
   layers cannot express.

Do not copy Nitro Kit controllers into the application. Do not add files under
`app/javascript/controllers/nk`; consume the `nk--*` controllers packaged by
the installed gem.

## Response matrix

| Request              | Success                                       | Invalid or denied                                                   |
| -------------------- | --------------------------------------------- | ------------------------------------------------------------------- |
| HTML form mutation   | Redirect with `303 See Other`                 | Render HTML with `422`                                              |
| Frame form mutation  | Redirect or render the same frame ID          | Render the same frame ID with `422`                                 |
| Stream form mutation | Return only when multiple targets must change | Render the invalid form target with `422` and keep an HTML fallback |
| GET query            | Render from URL parameters                    | Render a useful empty or error state                                |

Use `dom_id` or one named constant for a frame. The show, edit, invalid,
success, and cancel responses must preserve that identifier.

## Forms and application Stimulus

Let Turbo submit real Rails forms. Use `data-turbo-submits-with` for submission
feedback and `data-turbo-confirm` for compact destructive confirmation.
Reviewed destructive flows may compose `DangerZone` and `Dialog`, but the
dialog must still submit a real Rails form.

Keep application controllers small, declarative, and disposable. For a
self-submitting control, the complete controller can be:

```js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  submit() {
    this.element.requestSubmit();
  }
}
```

Attach `data-action="change->auto-submit#submit"` to the form so change events
bubble to that one controller root. Keep a submit button inside `noscript` as
the HTML fallback. Use `data-action` instead of manually registering DOM listeners. If a
controller owns a listener, observer, timer, object URL, or third-party
instance, release it in `disconnect`.

## Morphing and cache lifecycle

Default to morphable server-rendered HTML. Use `data-turbo-permanent` only for
a genuinely stateful island, always with a stable unique `id`. Update content
inside a permanent element deliberately instead of making broad page regions
permanent.

Clean ephemeral UI before Turbo caches the page. Nitro Kit controllers own
their own cache and reconnect behavior; application controllers must do the
same for application-owned state.

## Frame escape and recovery

An authentication redirect or error response inside a frame must not strand
the user behind a missing-frame error. Use `_top` when navigation must leave
the frame. Keep authentication and authorization handling capable of returning
a full-page response, and handle `turbo:frame-missing` only when the
application has a deliberate recovery policy.

Give lazy frames meaningful loading content. A failed frame should leave an
understandable state and a path to retry or continue without JavaScript.

## Verify behavior

- Request-test `303`, `422`, HTML fallback, and stable frame IDs.
- System-test focus, dialogs, frame navigation, and multi-target changes.
- Use Capybara assertions that wait for the DOM; never use `sleep`.
- Test navigation, morphing, and reconnection without duplicating controller
  roots or listeners.

Read the matching recipe under `docs/patterns/` for complete compositions.
