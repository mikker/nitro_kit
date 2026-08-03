# New application strategy

Recommend a Rails application template for new applications, not a return to Nitro Kit's old component-copying generator.

Rails application templates are designed to configure a new app during `rails new`, can add gems, and can run generators after Bundler finishes. Nitro Kit's starter therefore remains a thin one-command entry point:

```sh
rails new my_app -m https://nitrokit.dev/template.rb
```

The template adds Nitro Kit and invokes `nitro_kit:install`. The generator owns
the project-local skills and `AGENTS.md`. The template does not copy Nitro
components, controllers, authentication, teams, billing, or product models.

Existing applications install the gem directly and run the setup generator.
Agent discovery, version-matched skill routing, diagnostics, and initialization
handoff are meaningful application-owned setup; component source remains
gem-owned.

An optional `nitro_kit:application` generator can later create an application-owned base: layout, `UI` namespace, shell choice, root screen, and authentication hooks. Keep that separate from installing the UI gem so teams can adopt Nitro Kit without adopting an application architecture.

Promote the template into a versioned starter application only when Nitro Kit deliberately owns opinions beyond UI and interaction conventions, such as authentication, accounts, teams, billing, jobs, mail, and deployment. Until then, the application template is easier to inspect, test, and evolve and does not impose the maintenance cost of a forked starter repository.
