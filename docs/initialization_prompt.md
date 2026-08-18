# Initialize Nitro Kit 2 in this Rails application

Finish the application-specific Nitro Kit 2 setup. Do not use Nitro Kit 1.x
APIs or examples.

1. Run `bundle show nitro_kit` and confirm the resolved version begins with
   `2.`.
2. Read `docs/agent_guide.md` from that installed gem, then read the locally
   installed `nitro-kit-rails`, `nitro-kit-hotwire`, and `nitro-kit-ui` skills.
3. Inspect the application before editing. Inventory user flows, every rendered
   button treatment (including application-owned `.btn` classes and native Rails
   helpers), joined controls, and the existing semantic color, focus, radius,
   density, and typography tokens. Capture representative wide and narrow
   screenshots before changing markup. Preserve established application
   conventions unless they conflict with the requested Nitro Kit 2 setup.
4. If this is a greenfield application, run `bin/rails generate phlex:install`
   and use Phlex for the application layout, route-level views, and reusable
   UI. If the application already has meaningful ERB or other view conventions,
   preserve them and introduce Phlex only at the requested boundary unless an
   application-wide migration is explicitly authorized. Do not infer this from
   the Rails version or apparent age.
5. Ensure an application base Phlex component includes `NitroKit` once. Prefer
   capitalized Kit methods such as `Button(...)` and `Card(...)`; use `.new`
   only when another API requires a component object.
6. Re-run `bin/rails generate nitro_kit:install`. Ensure its application layout
   setup has one appearance bootstrap before every stylesheet, then optional
   third-party base styles, the optional Tailwind adapter, `nitro_kit`, compiled
   Tailwind, and application token overrides in that order. Add flash toast
   rendering when the application uses it.
7. Ensure Turbo and Stimulus are wired and the normal Stimulus loader can
   discover the gem-owned `nk--*` controllers. Never copy Nitro components,
   helpers, or controllers into the application.
8. Remove confirmed Nitro Kit 1.x shadows such as application-owned
   `NitroKit` components, `nk_*` helpers, or `controllers/nk` only when this
   task is authorized to migrate the application.
9. Use ordinary Rails routes, models, forms, and server-rendered HTML. Follow
   the installed Rails and Hotwire guidance for new work. During a migration,
   replace an existing control only when Nitro Kit 2 has a genuine semantic
   and behavioral equivalent. Preserve compound ownership: use `ButtonGroup`
   for joined actions and `ControlGroup` for joined inputs, addons, and buttons
   instead of rebuilding their geometry with a raw flex wrapper. Otherwise
   preserve the control as application-owned Rails and semantic HTML; never
   downgrade specialized behavior or retain copied Nitro Kit 1.x source as the
   fallback. Preserve strict component boundaries: route native attributes
   through `html:`, `aria:`, or `data:`, explicitly name icon-only Buttons and
   triggers, and give custom `form.field` blocks explicit labels.
10. Translate the application's existing semantic theme into documented public
    `--nk-*` tokens. Preserve primary, focus, destructive, neutral, font, density, and
    radius decisions rather than selecting visually similar raw palette values.
    Use `--nk-button-radius` when buttons intentionally have a different shape
    from inputs and surfaces.
11. Run `bin/rails nitro_kit:doctor`, fix actionable failures, and run the
    application's relevant tests plus the generated upgrade smoke tests. When
    the application uses strict i18n, render representative forms with
    `ActiveModel::Translation.raise_on_missing_translations` enabled. Doctor
    inventories migration work; a clean result is not runtime or visual
    verification.
12. Compare the same representative flows across the dated matrix in
    `docs/browser_support.md`, including Mobile Safari where available, at wide
    and narrow widths. Exercise keyboard focus and inspect computed styles for missing
    application classes, stacked Button content, broken compound corners,
    double focus rings, clipping, and theme drift. Re-audit rendered native
    buttons, `button_tag`, `submit_tag`, and application-owned button classes
    before declaring the migration complete.

Report what you changed, any existing convention you deliberately preserved,
any unsupported control recorded as a Nitro Kit coverage gap, and any warning
that still needs a product decision.
