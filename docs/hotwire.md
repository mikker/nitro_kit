# Hotwire with Nitro Kit

**Audience:** Application developers and coding agents implementing Hotwire
interactions with Nitro Kit.

Rails owns records, routes, authorization, DOM identity, and responses. Nitro
Kit owns component markup, CSS, and its focused controllers. Hotwire transports
server-rendered HTML between them.

## Choose the smallest interaction

1. Ordinary links and forms under Turbo Drive.
2. One Turbo Frame for one independently navigable region.
3. A request-scoped Turbo Stream when one action changes multiple regions.
4. A broadcast only when another session needs the update.
5. Application Stimulus only for browser-owned behavior the previous layers
   cannot express.

Do not copy Nitro controllers or add files under
`app/javascript/controllers/nk`. Follow the canonical
[browser support policy](browser_support.md) for fallback behavior.

## Response contract

| Request         | Success                                   | Validation failure                                              |
| --------------- | ----------------------------------------- | --------------------------------------------------------------- |
| HTML mutation   | Redirect with `303 See Other`             | Render the invalid form with `422`                              |
| Frame mutation  | Redirect to, or render, the same frame ID | Render the same frame ID with `422`                             |
| Stream mutation | Return a stream only for multiple targets | Replace the invalid form target with `422`; keep an HTML branch |
| GET query       | Render from URL parameters                | Render a useful empty or error state                            |

Authentication and authorization failures are separate policy decisions; do
not return `422` for them.

Use `dom_id` or one named constant for each frame. Show, edit, invalid, success,
and cancel responses must preserve that identifier. An HTML branch preserves
the request path without Turbo; it does not make a closed or JavaScript-owned
interaction available.

## Stimulus and lifecycle

Let Turbo submit real Rails forms. Use `data-turbo-submits-with` for submission
feedback and `data-turbo-confirm` only for compact confirmation. A reviewed
destructive flow still submits a real Rails form; use the
[destructive action pattern](patterns/destructive_action.md).

Keep application controllers declarative. Prefer `data-action` over manually
registered listeners. Release listeners, observers, timers, object URLs, and
third-party instances in `disconnect`.

Keep server-rendered markup morph-safe. Enable refresh morphing deliberately,
and use `data-turbo-permanent` only for a stateful island with a stable unique
ID. Clean ephemeral UI before Turbo caches a page.

Use `_top` when navigation must leave a frame. Authentication redirects and
errors must not strand the user behind a missing-frame response. Give lazy and
failed frames useful content and a route to continue.

## Verify

- Request-test `303`, `422`, HTML fallback, and stable frame IDs.
- Scope mutation assertions to the matching frame.
- System-test focus, navigation, dialogs, and multi-target changes.
- Use Capybara waiting assertions; never use `sleep`.
- Test navigation, caching, morphing, and reconnection for duplicate state or
  listeners.

Use the matching [interaction pattern](patterns/) for complete compositions.
