# Rails integration

**Audience:** Application developers and coding agents installing Nitro Kit or
connecting it to Rails forms, assets, Stimulus, and Hotwire.

Rails owns records, routes, DOM IDs, forms, authorization, and responses.
Nitro Kit owns Phlex components, presentation, and focused browser behavior.
There are no `nk_form_with` helpers or general ERB component bridge.

## Install

Pin the current prerelease:

```ruby
gem "nitro_kit", "2.0.0.alpha.3"
```

Use the released gem and commit `Gemfile` with `Gemfile.lock`. Before upgrading,
review the changelog, run `bundle update nitro_kit`, rerun the installer, and
test the application before committing the lockfile.

```sh
bundle install
bin/rails generate nitro_kit:install
bin/rails nitro_kit:doctor
```

The installer adds project-local agent guidance and completes conventional
layouts when the insertion points are unambiguous. It leaves dynamic or custom
layouts unchanged and reports manual work. It never copies component source.

Load Nitro Kit before application styles:

```erb
<%= stylesheet_link_tag "nitro_kit", "application", "data-turbo-track": "reload" %>
```

For third-party base CSS, Tailwind, appearance setup, and token overrides, use
the canonical [stylesheet order](customization.md#stylesheet-order).

## Stimulus

Importmap applications receive Nitro Kit's pins from the engine. The host still
owns Stimulus and its normal loader:

```js
import { application } from "controllers/application";
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading";

eagerLoadControllersFrom("controllers", application);
```

Do not copy `nk--*` controllers into the application. Nitro Kit currently has
no JavaScript-package entrypoint for automatic bundler registration. Without
the packaged controllers, Ruby and CSS remain available with the reduced
baselines in [Browser support](browser_support.md).

## Appearance and CSP

Render `AppearanceBootstrap` before stylesheets. Render zero or more pickers in
the body:

```ruby
head do
  render NitroKit::AppearanceBootstrap.new(
    default: :system,
    nonce: content_security_policy_nonce
  )
  stylesheet_link_tag("nitro_kit", data: { turbo_track: "reload" })
  stylesheet_link_tag("application", data: { turbo_track: "reload" })
end

body do
  render NitroKit::AppearancePicker.new(
    id: "application-appearance",
    label: "Appearance"
  )
  yield
end
```

For a nonce policy, pass Rails' `content_security_policy_nonce`. For a hash
policy, allow the current fixed body:

```text
script-src 'self' 'sha256-Vcime4euWSeYtHSfjYjqz/XhRyzMcLpn6Ip2LlaHleY='
```

The value is also `NitroKit::AppearanceBootstrap::CSP_HASH`; recheck it after
upgrades. The runtime stores the preference under `nitro-kit-appearance`, sets
resolved `data-theme="light|dark"`, and keeps the selected preference in
`data-theme-preference`. Nitro does not synchronize it to a user record.

## Model-backed forms

Select the builder explicitly and group visible fields and actions:

```ruby
class RegistrationForm < Phlex::HTML
  include Phlex::Rails::Helpers::FormWith

  def initialize(registration)
    @registration = registration
  end

  def view_template
    form_with(model: @registration, builder: NitroKit::FormBuilder) do |form|
      form.hidden_field(:source)
      form.group do
        form.field(:email, as: :email, required: true)
        form.field(
          :role,
          as: :select,
          options: [["Developer", "developer"], ["Designer", "designer"]]
        )
        form.field(:attachment, as: :file, accept: "text/plain")
        form.submit("Register")
      end
    end
  end
end
```

`form.field` preserves Rails-generated names, IDs, model values, errors, file
multipart behavior, and checkbox hidden values. `form.group` owns vertical
rhythm. Hidden fields may remain outside it.

Use `html:`, `aria:`, and `data:` for control attributes. Use
`wrapper_html:`, `wrapper_aria:`, and `wrapper_data:` for the Field wrapper.
The [component contracts](component_contracts.md) list supported field types
and exact option boundaries.

### Optional integrations

- **Rich text:** after installing Action Text and Lexxy, use
  `form.field(:body, as: :rich_text)`. Lexxy owns editor behavior and uploads.
- **Direct upload:** `form.dropzone` requires configured Active Storage and its
  direct-upload route. The native file input remains the submission source.
- **Pagy:** pass a Pagy object to `Pagination(pagy: @pagy)`, or use the manual
  declaration API. Pagy is optional.
- **Remote command palette:** pass `search_url:` and return
  `CommandPalette::Results` HTML with the same stable ID. Scope every query on
  the server.

## Turbo responses

| Outcome                        | Response                                                       |
| ------------------------------ | -------------------------------------------------------------- |
| Successful HTML mutation       | Redirect with `303 See Other`                                  |
| Invalid mutation               | Render the same model and form with `422 Unprocessable Entity` |
| Frame response                 | Return the same stable frame ID                                |
| Multiple changed regions       | Return a request-scoped Turbo Stream and keep an HTML branch   |
| Other sessions need the update | Broadcast                                                      |

Use Rails DOM helpers for frame IDs. A matching frame ID is part of the
response contract; a page-level text assertion cannot prove Turbo can apply the
response. See [Hotwire](hotwire.md) and the focused
[interaction patterns](patterns/).

## Upgrade verification

For a Nitro Kit 1.x application, follow the dedicated
[migration guide](migration_1_to_2.md). It owns the upgrade smoke-test setup,
legacy inventory, Doctor review, and browser acceptance checklist.
