# Nitro Kit 2.0 implementation record

This document records the staged delivery program used for the agent-native pivot. `tk` is the source of truth for live status and dependency order; ticket IDs below connect durable design intent to executable work. Candidate lists in early stages are historical investigation prompts, not current public API. The settled contract lives in [`agent_native_spec.md`](agent_native_spec.md) and [`component_contracts.md`](component_contracts.md).

Nitro Kit 2.0 is allowed to break 1.x completely. Each stage should leave one simpler system behind rather than maintaining parallel APIs.

The original implementation program reached release-quality consolidation. Component migration, evidence-gathering flows, accepted layout/block extraction, the expanded gallery, 1.x removal, documentation, packaging, and browser verification are retained here as history; later contract revisions such as responsive Flex/Grid remain tracked in `tk` and the canonical contract documents.

## Definition of done

The 2.0 pivot is complete when:

- Every component is constructed directly from Phlex with explicit Ruby options.
- Nitro Kit owns the Ruby, markup contract, behavior, CSS, examples, and documentation.
- No Nitro-authored component, layout, block, flow, or gallery subject emits `class`, `style`, or an escape marker.
- Applications can theme the system through documented `--nk-*` variables and compose or subclass components.
- Rails forms, routes, assets, Turbo Frames, and Turbo Streams remain first-class.
- The gem does not expose `nk_*` view helpers, copied-component generators, a Tailwind runtime, or a template-buffer bridge.
- The complete catalog renders through explicit Rails routes in light/dark and narrow/wide states.
- Keyboard behavior and Turbo lifecycle behavior pass browser tests.
- The full Ruby, CSS, JavaScript formatting, package, and browser checks pass from a clean checkout.

## Delivery rules

Every migration ticket follows the same sequence:

1. Define the smallest explicit Ruby API and closed vocabularies.
2. Render native, self-describing HTML with `data-nk` and qualified `data-slot` identities.
3. Preserve Rails and accessibility semantics before visual styling.
4. Add static zero-specificity CSS driven by public theme tokens and private mechanics variables.
5. Add focused render, invalid-option, reserved-attribute, and integration tests.
6. Add representative and exhaustive gallery examples without classes or escape hatches.
7. Verify the family independently before allowing dependent flows to use it.

No compatibility layer should survive merely to keep a legacy example green. Replace the example and delete the obsolete API.

## Stage 0 — ownership and execution scaffold

Tickets: `nk-rzxf`, `nk-g3qu`

- Work on the dedicated `2.0-agent-native` branch.
- Keep the agent-native specification, component contracts, repository guidance, and this plan tracked with the gem.
- Track the entire program in the workspace-level `.tickets` database.
- Record implementation decisions and verification counts on each ticket before closing it.

Gate: an agent can explain who owns Ruby, markup, CSS, behavior, theming, composition, and the class escape hatch by reading the tracked docs.

## Stage 1 — kernel and distribution foundation

Tickets: `nk-6q5i`, `nk-fooc`, `nk-rx0j`

- Replace permissive attributes with explicit component options plus `html:`, `aria:`, and `data:` boundaries.
- Centralize identity, slot attachment, reserved attributes, validation, additive Stimulus data, and `desperately_need_a_class:`.
- Build deterministic layered CSS from split plain-CSS sources.
- Ship the built stylesheet, optional Tailwind adapter, importmap pins, and controllers from the gem without vendored third-party JavaScript.
- Prove the engine still boots when importmap-rails is absent.

Gate: a minimal Rails app can render and style a Nitro component without copying sources or configuring Tailwind or JavaScript pins.

## Stage 2 — representative vertical slice

Ticket: `nk-g3x1`

Migrate Button/Icon, Card, Input/Field/FormBuilder, Table, and Dialog all the way through Ruby, HTML, CSS, behavior, Rails integration, tests, and gallery routes.

Use this slice to settle:

- Direct compound-component methods and nested slot ownership.
- Native attribute boundaries and error messages.
- Intrinsic versus stretch sizing.
- Rails form names, IDs, values, errors, multipart behavior, and checkbox semantics.
- Native dialog behavior, stable ARIA relationships, and Stimulus cleanup.
- The explicit gallery catalog and route contract.

Gate: the slice is classless, invalid options fail immediately, focused tests pass, and its examples render through real Rails routes with Nitro CSS alone.

## Stage 3 — complete atom migration

Tickets: `nk-t17c`, `nk-b18t`, `nk-7lkw`, `nk-4r36`, `nk-i4xu`, `nk-19gd`

### Display

Migrate Alert, Avatar, AvatarStack, Badge, and Icon. Cover semantic intents, long content, image/fallback behavior, overflow, sizes, labeled/decorative icons, and nested combinations.

### Actions and navigation

Migrate ButtonGroup and Pagination. Preserve native links/buttons, current-page semantics, disabled previous/next controls, ellipses, compact ranges, and stable labels.

### Forms

Migrate Label, Textarea, Select, Checkbox, CheckboxGroup, RadioButton, RadioButtonGroup, Switch, FieldGroup, Fieldset, and all FormBuilder methods. Cover:

- Bound and unbound forms.
- Required, disabled, readonly, checked, indeterminate, invalid, prompt, and empty states.
- Array and nested parameter names.
- Active Model values and errors.
- Multipart uploads and native file-input constraints.
- Accessible descriptions, legends, labels, and error relationships.

### Structured content

Migrate Accordion and Tabs alongside the Card and Table slice. Require deterministic IDs and keys, direct compound APIs, semantic table structure, and keyboard-visible state.

### Interaction

Migrate Dropdown, Tooltip, Combobox, Datepicker, and Toast alongside Dialog. Require closed placement/state APIs, visible ARIA/data state, keyboard behavior, native controls where possible, and complete disconnect cleanup.

Gate: every shipped atom has a classless direct-Phlex API, static CSS, focused tests, exhaustive examples, and no dependency on a legacy helper.

## Stage 4 — Rails and Hotwire proof

Ticket: `nk-19gd`

- Exercise `form_with` directly from Phlex using `NitroKit::FormBuilder`.
- Prove route helpers, DOM ID helpers, CSRF behavior, model errors, submit paths, and multipart forms.
- Render Turbo Frames and Turbo Streams from direct-Phlex pages.
- Add one small validation submit path that demonstrates the real request/response loop.
- Document the supported Rails boundary and show examples without introducing Nitro view helpers.

Gate: Rails supplies framework semantics while Phlex remains the only general UI composition language.

## Stage 5 — gallery infrastructure and exhaustive combinations

Tickets: `nk-q4mj`, `nk-put2`, `nk-jp63`, `nk-5028`, `nk-t23x`, `nk-rtwj`, `nk-8mh8`, `nk-t66i`, `nk-vnwu`

- Keep one explicit catalog of component, block, and flow entries.
- Render the shell, pages, sections, examples, samples, and notes in Phlex.
- Pair every preview with highlighted, copyable Ruby extracted from the exact rendering block or concrete flow method.
- Generate route contract tests from the catalog.
- Assert every subject has stable Nitro identities and no `class`, `style`, or escape markers.
- Add meaningful Cartesian coverage without mechanically showing nonsense combinations.

Required pressure cases:

- All closed variants and sizes.
- Default, hover/focus-capable, disabled, readonly, invalid, empty, loading-like, open, and selected states where meaningful.
- Short, long, wrapped, numeric, missing-image, and high-item-count content.
- Nested atoms and compound slots.
- Light and dark themes.
- Narrow and wide viewports.
- Forms, tables, overlays, and navigation used together rather than only in isolation.

Gate: every catalog entry succeeds through an explicit route and the gallery itself requires no Tailwind or ERB templates.

## Stage 6 — atom-only product flows

Tickets: `nk-31ne`, `nk-7d05`, `nk-q37g`, `nk-tcig`, `nk-32vc`

Build realistic screens before inventing layout abstractions:

- Authentication, registration, password reset, and verification.
- Onboarding progress, validation, resume, and completion.
- Dashboard overview, statistics, recent records, and activity.
- Profile, preferences, account, and destructive settings.
- Billing plans, payment methods, invoices, and upgrade states.
- Users search, filters, pagination, empty state, and detail.
- Team members, invitations, roles, and removal confirmation.
- API credential empty, create, reveal-once, list, and revoke states.

Use deterministic PORO data and explicit state slugs. Record repeated layout and responsibility friction in `notes/block_candidates.md`; do not abstract a one-off screen.

Gate: all required product states exist using atoms and plain Phlex composition, and repeated structures are backed by concrete evidence.

## Stage 7 — evidence-driven layouts and blocks

Tickets: `nk-okls`, `nk-bjv5`, `nk-b8eg`

Extract the smallest vocabulary that removes proven repetition. The evidence pass accepted:

- Layouts: VStack, HStack, the three-column Grid, and Container.
- Shell: AuthShell.
- Sections and blocks: SettingsLayout, Toolbar, PaginationBar, PageHeader, StatGrid, DataSection, FormSection, DangerZone, and EmptyState.

This list records the first extraction decision. It has since been superseded: `VStack` and `HStack` were removed in favor of unified responsive `Flex`, and the fixed three-column Grid became a responsive 1–12-column `Grid`. See the canonical specification and component contracts for the current API.

At that stage, the evidence pass deferred Spacer, Split, Frame, AppShell, MarketingShell, AuthenticationPanel, and ProgressSteps because their responsibilities were not stable across enough domains. A later application-layout mandate supplied enough evidence to accept AppShell; the other deferred candidates remain outside the prerelease. The settled contracts, rather than this historical stage record, live in [`agent_native_spec.md`](agent_native_spec.md) and [`component_contracts.md`](component_contracts.md).

Each abstraction must:

- Have one clear responsibility.
- Use closed layout options.
- Own only structure that actually repeats.
- Accept atoms/content through direct Ruby composition.
- Emit classless self-describing markup.
- Include examples showing reuse in at least two flows.

Then rewrite the atom-only flows with blocks and compare the result. Delete abstractions that do not make application code meaningfully clearer.

Gate: flow code describes product intent, while layouts and blocks remain a small coherent vocabulary rather than a second page framework.

## Stage 8 — expanded application gallery

Tickets: `nk-pmcn`, `nk-q1tc`, `nk-oi4y`, `nk-gn4s`, `nk-ky42`

Extend the block-based gallery across:

- Data detail, activity, audit, uploads, and integrations.
- Billing, authentication, onboarding, team, and API states.
- System error, permission, empty, loading-like, and marketing states.
- Changelog, support, and help experiences.

Prefer depth of state over disconnected decorative pages. Each flow should show success, empty/error, destructive/confirmation, and constrained-width behavior where applicable.

Gate: the gallery demonstrates that the vocabulary can build a credible Rails product, not only isolated controls.

## Stage 9 — remove the old system

Ticket: `nk-u534`

- Delete all `nk_*` view helpers and automatic variant aliases.
- Delete copied-component generators, schemas, manifests, and installation paths.
- Delete the Action View/template capture bridge and legacy builder path.
- Remove Tailwind Merge and consumer Tailwind dependencies.
- Remove legacy ERB test pages, Tailwind assets, and obsolete tests.
- Audit packaged gem files and runtime dependencies.

Gate: repository-wide searches find no public legacy invocation, copied-source promise, internal component class string, or required Tailwind runtime.

## Stage 10 — browser behavior and lifecycle verification

Tickets: `nk-352j`, `nk-6ivz`, `nk-gxwn`, `nk-lij5`, `nk-tkds`

- Enumerate every catalog URL and state in a real browser.
- Exercise keyboard order, arrows, Escape, Enter/Space, tab trapping/return, and focus visibility.
- Exercise open/close, select, filter, validation, submit, and destructive confirmation paths.
- Navigate through Turbo Drive, Frames, Streams, and morph refreshes; look for duplicate controllers and leaked listeners/positioners/timers.
- Review representative pages at narrow/wide sizes and light/dark themes.
- Check for horizontal overflow, clipped overlays, unstable layout, unreadable content, and broken focus state.

Gate: browser coverage proves both route completeness and interaction lifecycle behavior.

## Stage 11 — release-quality consolidation

Tickets: `nk-g3qu`, `nk-obb7`

- Reconcile actual component APIs with `docs/component_contracts.md` and `STYLE_GUIDE.md`.
- Document Rails integration, theming tokens, composition, subclass caveats, and the escape hatch.
- Run a data-structure review for duplicated collections, scattered state, and invalid intermediate states.
- Run a simplification pass and remove compatibility branches, duplicate validation, dead CSS, dead JavaScript, and unused dependencies.
- Audit all CSS selectors for zero specificity and owner scoping.
- Audit all controllers for disconnect cleanup and Turbo safety.
- Run the complete test, lint, format, CSS build/check, package, route, and browser suites.

Gate: every child of `nk-rzxf` is closed with evidence and the repository contains one coherent 2.0 architecture.

## Verification matrix

| Surface       | Required verification                                                                             |
| ------------- | ------------------------------------------------------------------------------------------------- |
| Ruby API      | Focused construction/render tests; invalid vocabulary; missing content; reserved attributes       |
| Markup        | Native semantics; stable IDs; ARIA relationships; `data-nk`; qualified `data-slot`; visible state |
| CSS           | Deterministic build/check; zero-specificity owner-scoped selectors; token audit; light/dark       |
| Rails         | Real `form_with`; Active Model; routes/DOM IDs; multipart; validation submit; Frame/Stream        |
| JavaScript    | Keyboard behavior; open/close/select; disconnect cleanup; Turbo navigation and morph              |
| Gallery       | Catalog routes; exact escaped source; copy behavior; no class/style/escape; narrow/wide           |
| Packaging     | Engine boot with optional integrations absent; gem contents and dependencies audited              |
| Documentation | Specification, contracts, style guide, Rails boundary, theming, examples, repository commands     |

## Execution and handoff

Use `tk ready` to select dependency-safe work. Preparatory parallel work is permitted only when the orchestrator explicitly assigns non-overlapping ownership. Every handoff names changed files, behavior decisions, focused test counts, and known failures. The orchestrator independently reviews and reproduces meaningful checks before closing a feature ticket.
