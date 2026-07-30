# Initialize Nitro Kit 2 in this Rails application

Finish the application-specific Nitro Kit 2 setup. Do not use Nitro Kit 1.x
APIs or examples.

1. Run `bundle show nitro_kit` and confirm the resolved version begins with
   `2.`.
2. Read `docs/agent_guide.md` from that installed gem, then read the locally
   installed `nitro-kit-rails`, `nitro-kit-hotwire`, and `nitro-kit-ui` skills.
3. Inspect the application before editing. Preserve established application
   conventions unless they conflict with the requested Nitro Kit 2 setup.
4. Ensure an application base Phlex component includes `NitroKit` once and
   product components inherit from it.
5. Re-run `bin/rails generate nitro_kit:install`. Ensure its application layout
   setup has one appearance bootstrap before every stylesheet, then optional
   third-party base styles, the optional Tailwind adapter, `nitro_kit`, compiled
   Tailwind, and application token overrides in that order. Add flash toast
   rendering when the application uses it.
6. Ensure Turbo and Stimulus are wired and the normal Stimulus loader can
   discover the gem-owned `nk--*` controllers. Never copy Nitro components,
   helpers, or controllers into the application.
7. Remove confirmed Nitro Kit 1.x shadows such as application-owned
   `NitroKit` components, `nk_*` helpers, or `controllers/nk` only when this
   task is authorized to migrate the application.
8. Use ordinary Rails routes, models, forms, and server-rendered HTML. Follow
   the installed Rails and Hotwire guidance for new work. During a migration,
   replace an existing control only when Nitro Kit 2 has a genuine semantic
   and behavioral equivalent. Otherwise preserve it as application-owned
   Rails and semantic HTML; never downgrade specialized behavior or retain
   copied Nitro Kit 1.x source as the fallback.
9. Run `bin/rails nitro_kit:doctor`, fix actionable failures, and run the
   application's relevant tests.

Report what you changed, any existing convention you deliberately preserved,
any unsupported control recorded as a Nitro Kit coverage gap, and any warning
that still needs a product decision.
