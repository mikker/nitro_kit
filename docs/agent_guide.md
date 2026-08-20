# Nitro Kit application guide for coding agents

**Audience:** Coding agents changing a Rails application that uses Nitro Kit.
Humans should start with the [README](../README.md) and
[Rails integration guide](rails_integration.md).

## Resolve the installed version

From the application root, run:

```sh
bundle show nitro_kit
```

Read this guide from that directory. The installed
[component contracts](component_contracts.md) define the public API.

| Task                                               | Read                                                         |
| -------------------------------------------------- | ------------------------------------------------------------ |
| Rails models, routes, CRUD, and tests              | [Rails conventions](rails_conventions.md)                    |
| Authentication, teams, shell, and settings         | [Application foundation](patterns/application_foundation.md) |
| Complete product CRUD                              | [CRUD resource](patterns/crud_resource.md)                   |
| Components and composition                         | [Component contracts](component_contracts.md)                |
| Installation, assets, forms, and Rails integration | [Rails integration](rails_integration.md)                    |
| Turbo, Frames, Streams, morphs, or Stimulus        | [Hotwire](hotwire.md)                                        |
| Browser compatibility or fallback behavior         | [Browser support](browser_support.md)                        |
| Theme tokens and application CSS                   | [Customization](customization.md)                            |
| Nitro Kit 1.x upgrade                              | [Migration guide](migration_1_to_2.md)                       |
| Query, sort, filter, or paginate                   | [Queryable collection](patterns/queryable_collection.md)     |
| Create, update, and validation                     | [Resource form](patterns/resource_form.md)                   |
| Delete, revoke, archive, or confirm                | [Destructive action](patterns/destructive_action.md)         |
| Flash messages and notifications                   | [Flash and toast](patterns/flash_and_toast.md)               |
| Edit and cancel inside a page                      | [Inline edit](patterns/inline_edit.md)                       |

Before changing a Nitro Kit 1.x application, read the migration guide. Do not
infer 2.x APIs from memory or old application code.

## Preserve the application's architecture

For a greenfield application, run:

```sh
bin/rails generate phlex:install
```

Use Phlex for the application layout, route views, and reusable UI. In an established
application, preserve its view architecture and introduce Phlex only at the
requested boundary. Do not perform an application-wide migration unless it is
explicitly authorized.

## Stay within the public API

- Include `NitroKit` once in the application's base Phlex component and use
  Kit methods such as `Button(...)` and `Card(...)`.
- Use `NitroKit::Button(...)` when inclusion is inappropriate and `.new` only
  when another API requires a component object.
- Select `NitroKit::FormBuilder` explicitly with Rails `form_with`.
- Put stacked fields and actions in `form.group` or `FieldGroup`.
- Use documented component options, compound methods, native attributes, and
  public `--nk-*` tokens.
- Keep product policy, records, routes, authorization, queries, DOM IDs, and
  server responses in application code.
- Do not copy Nitro source, add `nk_*` helpers, mutate Nitro controllers, or
  pass `class:` or `style:`. Use `desperately_need_a_class:` only for a named
  external integration that requires a class hook.

Follow the canonical [browser support policy](browser_support.md) for
JavaScript and fallback guarantees.

## Install project-local guidance

From the consuming application, run:

```sh
bin/rails generate nitro_kit:install
```

The installer updates its managed `AGENTS.md` block and local Nitro Kit skills
without copying component source. Re-run it after upgrading the gem.
