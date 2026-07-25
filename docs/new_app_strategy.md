# New application strategy

Recommend a Rails application template for new applications, not a return to Nitro Kit's old component-copying generator.

Rails application templates are designed to configure a new app during `rails new`, can add gems, and can run generators after Bundler finishes. That gives Nitro Kit an eventual one-command entry point:

```sh
rails new my_app -m https://nitrokit.dev/template.rb
```

The template should remain thin while the conventions settle. Its first
version should add Nitro Kit and invoke `nitro_kit:install`. The generator owns
the project-local skills and `AGENTS.md`; the template may call
`NitroKit.start()` and add an application layout that renders the stylesheet,
appearance bootstrap, confirm dialog, and flash toasts. It must not copy Nitro
components or their controllers.

Existing applications install the gem directly and run the setup generator.
Agent discovery, version-matched skill routing, diagnostics, and initialization
handoff are meaningful application-owned setup; component source remains
gem-owned.

An optional `nitro_kit:application` generator can later create an application-owned base: layout, `UI` namespace, shell choice, root screen, and authentication hooks. Keep that separate from installing the UI gem so teams can adopt Nitro Kit without adopting an application architecture.

Promote the template into a versioned starter application only when Nitro Kit deliberately owns opinions beyond UI and interaction conventions, such as authentication, accounts, teams, billing, jobs, mail, and deployment. Until then, the application template is easier to inspect, test, and evolve and does not impose the maintenance cost of a forked starter repository.
