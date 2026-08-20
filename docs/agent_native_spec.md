# Nitro Kit architecture

**Audience:** Nitro Kit core maintainers and coding agents changing the gem.
This is not an application integration guide. Consumers should start with the
[agent guide](agent_guide.md) or [Rails integration](rails_integration.md).

Nitro Kit is a gem-owned, versioned Phlex UI system for Rails. The
[component contracts](component_contracts.md) define the current public Ruby
and markup API. The [browser support policy](browser_support.md) defines the
compatibility contract. Do not duplicate those inventories here.

## Ownership

Nitro Kit owns:

- component Ruby and public component APIs;
- rendered structure, accessibility semantics, CSS, and `--nk-*` tokens;
- focused Stimulus behavior and compatibility fallbacks;
- Rails engine integration, examples, and component tests.

Applications own:

- records, policy, routes, authorization, queries, DOM IDs, and responses;
- product-specific composition and copy;
- application CSS and documented token overrides.

Components load from the gem. Generators may install application guidance and
integration files, but never copies of component source.

## Public API principles

Direct Phlex construction is canonical:

```ruby
render NitroKit::Button.new("Save", variant: :primary)
```

Compound components expose explicit Ruby methods:

```ruby
render NitroKit::Card.new do |card|
  card.title("Workspace")
  card.body { render WorkspaceSummary.new }
end
```

- Public options are explicit keywords with validated closed vocabularies.
- Required content and compound cardinality fail early.
- Common native semantics may be first-class keywords. Other native
  attributes use `html:`, `aria:`, and `data:`.
- Nitro identity and state attributes are reserved. Source constants and the
  component contracts define the current set.
- Components reject `class:` and `style:`. The audited
  `desperately_need_a_class:` escape exists only for external integrations.
- There are no `nk_*` helpers, generated variant helpers, copied components,
  or general ERB bridge.

Rails helpers remain first-class for forms, routes, DOM IDs, translations,
assets, Active Storage, Turbo Frames, and Turbo Streams.

## Structure, behavior, and styling

Every visual root emits `data-nk`. Owned parts use component-qualified
`data-slot` values. Native elements remain native, and state stays with the
native element when the platform already owns it.

Nitro uses native HTML as the preferred interaction path. A feature outside
the browser-support window receives the smallest capability-detected fallback
needed to preserve essential behavior. Stimulus augments native semantics; it
does not replace Rails requests or application policy.

Nitro ships classless, layered CSS. Selectors use `:where()` and public
`--nk-*` tokens; private `--_nk-*` variables are implementation details.
Applications load unlayered overrides after Nitro Kit. The complete contract
is in [Customization](customization.md).

Parents own external placement and available width. Components own intrinsic
geometry. Use the typed `Flex`, `Grid`, and `Container` APIs instead of a
general utility language.

## Rails and Hotwire

`NitroKit::FormBuilder` preserves Rails names, IDs, values, errors, multipart
forms, and checkbox semantics. Invalid mutations render with `422`; successful
HTML mutations redirect with `303`. Turbo transports server-rendered HTML.
Broadcast only for updates needed by other sessions.

The host application owns Stimulus and its loader. Nitro owns `nk--*`
controllers and releases listeners, observers, timers, and other resources on
disconnect. The supported setup is documented in
[Rails integration](rails_integration.md).

## Verification

Every public component requires:

- render, invalid-option, reserved-attribute, and accessibility tests;
- deterministic CSS coverage;
- gallery examples covering meaningful states and narrow layouts;
- browser tests for interaction and Turbo lifecycle where applicable.

The gallery consumes the component contract tables and each pattern's leading
`## Summary`. Keep those formats valid and test their parsers. Git and `tk`
hold delivery history; this document records only durable architecture.

## Outside the current architecture

Nitro Kit does not provide generated component copies, a generic utility DSL,
arbitrary breakpoints, a public component registry, an MCP server, or a
JavaScript custom-element runtime. New abstractions require demonstrated reuse
and an explicit public contract.
