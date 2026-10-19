# Rails integration

**Audience:** Application developers and coding agents installing Nitro Kit or
connecting it to Rails forms, assets, Stimulus, and Hotwire.

Rails owns records, routes, DOM IDs, forms, authorization, and responses.
Nitro Kit owns Phlex components, presentation, and focused browser behavior.
There are no `nk_form_with` helpers or general ERB component bridge.

## Install

Nitro Kit 2.0.0.beta.3 requires Ruby 4.0.6 or newer. Check the application's
Ruby version first; Bundler refuses to install the gem on an older Ruby.

Pin the current prerelease:

```ruby
gem "nitro_kit", "2.0.0.beta.3"
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
the canonical [stylesheet order](customization.md#stylesheet-order). A
`tailwindcss-rails` application can bundle Nitro Kit into its compiled Tailwind
stylesheet through the engine entry described there.

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

## Bundlers

Nitro Kit ships its controllers as plain ES modules in the gem's
`app/javascript` directory, not as an npm package. A jsbundling-rails
application bundles them straight from the installed gem. This esbuild setup is
verified against an application generated with `rails new --javascript=esbuild`.

Two resolution rules matter:

- Nitro controllers import their helpers by importmap-style bare paths such as
  `controllers/nk/overlay_position`. An alias for the gem root alone does not
  resolve these, so the gem's `app/javascript` directory must be a module search
  path.
- The controllers import `@hotwired/stimulus`, and Dropzone imports
  `@rails/activestorage`. The gem lives outside the application, so esbuild
  cannot find the application's `node_modules` by walking up from those files.
  Add `node_modules` to the same search path so the bundle contains one copy of
  Stimulus.

Put both directories on `NODE_PATH` in the `build` script in `package.json`:

```json
{
  "scripts": {
    "build": "NODE_PATH=\"$(bundle info --path nitro_kit)/app/javascript:node_modules\" esbuild app/javascript/*.* --bundle --sourcemap --format=esm --outdir=app/assets/builds --public-path=/assets"
  }
}
```

`bundle info --path` resolves the installed gem, including `path:` and `git:`
sources, so nothing is hard-coded. `bin/dev` (`yarn build --watch`) and
`bin/rails assets:precompile` run the same script, so Bundler must be available
wherever assets are built. The inline variable needs a POSIX shell. With
esbuild's JavaScript API, pass the same two directories as `nodePaths`.

Register the controllers in an application-owned file. Each identifier must
match the `data-controller` value Nitro renders:

```js
// app/javascript/controllers/nitro_kit.js
import { application } from "./application";

import AppShellController from "controllers/nk/app_shell_controller";
import AppearanceController from "controllers/nk/appearance_controller";
import AvatarController from "controllers/nk/avatar_controller";
import ButtonController from "controllers/nk/button_controller";
import CheckableController from "controllers/nk/checkable_controller";
import ComboboxController from "controllers/nk/combobox_controller";
import CommandPaletteController from "controllers/nk/command_palette_controller";
import DialogController from "controllers/nk/dialog_controller";
import DropdownController from "controllers/nk/dropdown_controller";
import DropzoneController from "controllers/nk/dropzone_controller";
import ProgressiveImageController from "controllers/nk/progressive_image_controller";
import TabsController from "controllers/nk/tabs_controller";
import ToastController from "controllers/nk/toast_controller";
import TooltipController from "controllers/nk/tooltip_controller";

application.register("nk--app-shell", AppShellController);
application.register("nk--appearance", AppearanceController);
application.register("nk--avatar", AvatarController);
application.register("nk--button", ButtonController);
application.register("nk--checkable", CheckableController);
application.register("nk--combobox", ComboboxController);
application.register("nk--command-palette", CommandPaletteController);
application.register("nk--dialog", DialogController);
application.register("nk--dropdown", DropdownController);
application.register("nk--dropzone", DropzoneController);
application.register("nk--progressive-image", ProgressiveImageController);
application.register("nk--tabs", TabsController);
application.register("nk--toast", ToastController);
application.register("nk--tooltip", TooltipController);
```

Import it from the entry point, not from `controllers/index.js`, because
`bin/rails stimulus:manifest:update` regenerates that file and drops the import:

```js
// app/javascript/application.js
import "@hotwired/turbo-rails";
import "./controllers";
import "./controllers/nitro_kit";
```

Dropzone needs `yarn add @rails/activestorage`. If the application does not use
direct uploads, remove the Dropzone import and registration instead; the
remaining controllers have no other package dependencies. Bundled registration
is explicit, so after each upgrade compare this file with
`ls "$(bundle info --path nitro_kit)/app/javascript/controllers/nk"`.

Other bundlers need the same two resolution rules. Only esbuild is verified.

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

## Fragment caching

Rails `cache` blocks in ERB key each fragment on a template digest. The digest
covers the template's source and the partials Rails finds by scanning it for
`render` calls. Ruby classes are not templates, so the source of a Phlex
component, Nitro's or the application's, never enters the digest. This is a gap
between Rails template digests and Phlex, not something Nitro Kit can close on
its own. The upstream proposals, rails/rails#42850 and phlex-rails#106, were
closed without a fix.

In practice:

- Changing a component without changing the fragment's cache key serves the
  old HTML until the entry expires. A `path:` or `git:` gem source keeps the
  same `NitroKit::VERSION` across edits, so no version-based key notices.
- Partials rendered inside a component's ERB block are still tracked.
- Phlex's own `cache` method, used inside Phlex views, includes a
  process-boot timestamp in its key, so those fragments reset when the
  application restarts. The gap applies to ERB `cache` blocks.

### Avoid false partial dependencies

Both Rails dependency trackers read `render NitroKit::Button.new(...)` as a
partial render. On Rails 8.1.4, the default ERB tracker records
`NitroKits/NitroKit`, and the Ruby tracker
(`config.action_view.render_tracker = :ruby`) records `news/new`. Each digest
then logs `Couldn't find template for digesting`. Rendered HTML is unaffected,
but the log noise hides real missing partials. Inside cached templates, call
`render_in` instead. It renders the same HTML, block content included, and adds
no dependency:

```erb
<% cache @video do %>
  <%= NitroKit::Button.new("Save", variant: :primary).render_in(self) %>

  <%= NitroKit::Card.new.render_in(self) do |card| %>
    <% card.title "Details" %>
    <% card.body do %>
      <%= render "videos/details", video: @video %>
    <% end %>
  <% end %>
<% end %>
```

Outside cached templates, `render` stays the normal form. Rails 8.1.4 also
fixes `render_tracker` registration (rails/rails#57265), so on Rails 8.1.3.x
the Ruby tracker setting may not take effect.

### Invalidate on gem upgrades

Add the installed Nitro Kit version to every fragment digest:

```ruby
class ApplicationController < ActionController::Base
  view_cache_dependency { "nitro-kit:#{NitroKit::VERSION}" }
end
```

This is the supported approach for Nitro Kit upgrades. It does not cover edits
to application-owned components, or Nitro Kit changes that keep the same
version. For those, add a dependency that changes with each deploy, such as
the release's Git revision, and accept that every deploy then starts with a
cold fragment cache.

### Turn fragment caching off

When cached fragments mostly wrap components and render quickly, staleness
costs more than rendering. Turn HTML fragment caching off with
`config.action_controller.perform_caching = false` in that environment. ERB
`cache` blocks then render on every request, and `Rails.cache` remains
available for expensive queries and computed data. One production adopter
measured under 20 ms per page after doing this. Measure the affected pages
before and after.

## Upgrade verification

For a Nitro Kit 1.x application, follow the dedicated
[migration guide](migration_1_to_2.md). It owns the upgrade smoke-test setup,
legacy inventory, Doctor review, and browser acceptance checklist.

### Doctor outcomes

`bin/rails nitro_kit:doctor` reports one outcome per check. Only `FAIL` makes
Doctor exit non-zero:

- `PASS`: verified.
- `FAIL`: a real defect, such as a missing stylesheet, the wrong stylesheet
  order, a stylesheet outside the head, or a stale skill copy.
- `UNVERIFIED`: Doctor could not inspect a custom or dynamic layout, so the
  detail says what to check by hand. Stylesheet calls it can still read must
  be in the right order, or the check fails instead.
- `OPTIONAL`: a convention the application has chosen not to adopt in
  `config/nitro_kit/doctor.yml`.
- `WARN`: a migration or application next step.

`--format=json` reports the same statuses as lowercase strings.

### Doctor configuration

A manual integration can tell the installer and Doctor what it owns. The file
is optional, and every key is optional:

```yaml
# config/nitro_kit/doctor.yml
theme_owner: application # default: nitro_kit
skill_roots: # default: both .agents/skills and .claude/skills
  - .agents/skills
retained_dependencies:
  "@github/combobox-nav": Used by the application-owned search combobox
```

- `theme_owner: application` means the application sets `data-theme` itself.
  The installer stops adding `AppearanceBootstrap`, and Doctor reports it as
  optional. Leave `data-theme` unset to follow `prefers-color-scheme`.
  `AppearancePicker` still needs `AppearanceBootstrap`.
- `skill_roots` lists the skill directories the installer writes and Doctor
  requires. Doctor still fails a stale copy left in a root that isn't listed.
- `retained_dependencies` maps a dependency the migration inventory would flag
  to the reason it is kept. Doctor reports those findings as `retained`
  instead of unresolved.

If a key or value is unknown, the `Doctor configuration` check fails and the
default is used for that setting.
