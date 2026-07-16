# Rails and Hotwire integration

Nitro Kit 2.0 uses Rails where Rails owns important application semantics: model-backed forms, routes, DOM IDs, and Hotwire. The supported view layer remains direct Phlex. There is no `nk_form_with`, `nk_form_for`, or general ERB component bridge.

## Installation and assets

Add Nitro Kit to the application's Gemfile and install it:

```ruby
gem "nitro_kit", "2.0.0.pre.1"
```

```sh
bundle install
```

Load the static stylesheet before application styles through the Rails asset pipeline:

```erb
<%= stylesheet_link_tag "nitro_kit", "application", "data-turbo-track": "reload" %>
```

Nitro Kit does not require Tailwind. A Tailwind CSS v4 application loads `nitro_kit-tailwind-v4`, Nitro Kit, compiled Tailwind, and application styles in that order. The adapter establishes cascade order and maps Nitro theme tokens to common Tailwind theme variables.

Keep application token overrides after Nitro Kit. The [customization guide](customization.md) documents the exact load order, every supported token, scoped and appearance-specific overrides, the gallery wizard, and the optional Tailwind adapter.

Raised default Buttons have their own public background, hover, foreground, and border tokens. Override `--nk-button-default-*` rather than changing `--nk-color-surface` when form controls, cards, dialogs, and menus should retain their existing surfaces.

There is no install generator and no source-copy step.

## Stimulus and importmap

Enhanced components use gem-owned Stimulus controllers, including `nk--app-shell`, `nk--appearance`, `nk--checkable`, `nk--combobox`, `nk--dropdown`, `nk--dropzone`, `nk--progressive-image`, `nk--tabs`, `nk--toast`, and `nk--tooltip`.

Accordion and Dialog are controller-free: native `details` grouping and declarative `command`/`commandfor` own their complete interaction. Dropdown uses native Popover as its source of truth and adds only menu keyboard focus; Tooltip uses CSS for hover/focus and JavaScript only for Escape dismissal. Nitro does not promise dialog light dismiss.

When `importmap-rails` is present, the engine adds its importmap and asset paths automatically. The application must still install Stimulus and provide the normal controller loader:

```js
import { application } from "controllers/application";
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading";

eagerLoadControllersFrom("controllers", application);
```

Nitro Kit packages no third-party JavaScript. Accordion, Datepicker, Dialog, and Switch use native browser behavior and need no controllers.

The engine deliberately boots when importmap is absent. In that configuration, Ruby and CSS remain available, but automatic JavaScript registration does not: a bundler-based application must expose and register the controller modules itself. This prerelease does not ship a JavaScript-package entrypoint.

## Appearance and content security policy

Render the non-visual bootstrap in the document `head` before every stylesheet link. Its fixed script body restores the validated `light`, `dark`, or `system` preference before CSS-visible paint. The optional picker can appear zero, one, or many times; every picker reflects the same document preference.

```ruby
class ApplicationLayout < Phlex::HTML
  include Phlex::Rails::Layout
  include Phlex::Rails::Helpers::ContentSecurityPolicyNonce

  def view_template
    doctype
    html(lang: "en") do
      head do
        render NitroKit::AppearanceBootstrap.new(
          default: :system,
          nonce: content_security_policy_nonce
        )
        stylesheet_link_tag("nitro_kit", data: { turbo_track: "reload" })
      end

      body do
        render NitroKit::AppearancePicker.new(
          id: "application-appearance",
          label: "Appearance"
        )
        yield
      end
    end
  end
end
```

The runtime stores the preference under `nitro-kit-appearance`. It writes `data-theme-preference="light|dark|system"` and the resolved `data-theme="light|dark"` on the document root. System mode follows live operating-system changes; explicit choices do not. Storage denial falls back to `default:` and does not prevent in-document changes. Nitro does not synchronize this browser preference to an application user record.

For nonce-based policies, pass Rails' `content_security_policy_nonce` as above and include the generated nonce in the application's `script-src` policy. For hash-based policies, allow Nitro's exact fixed script body with:

```text
script-src 'self' 'sha256-Vcime4euWSeYtHSfjYjqz/XhRyzMcLpn6Ip2LlaHleY='
```

The same value is available as `NitroKit::AppearanceBootstrap::CSP_HASH`. The hash covers only the fixed inline body; `default:` lives in a data attribute and a nonce lives on the script element, so neither changes it. Recheck the constant when upgrading Nitro Kit because an intentional runtime change produces a new hash.

If the bootstrap is blocked or omitted, Nitro's token CSS follows `prefers-color-scheme`. An explicit `[data-theme="light"]` or `[data-theme="dark"]` on a document or containing theme root overrides that fallback. `data-theme` always names the resolved appearance; system preference is recorded separately in `data-theme-preference`. See [Customizing Nitro Kit](customization.md#global-overrides) for matching light, dark, system-fallback, and scoped CSS recipes.

## Application shells

`AppShell` composes directly in Phlex and keeps Rails route policy in the application. It requires one navigation and one main region; brand and topbar regions are optional:

```ruby
render NitroKit::AppShell.new(id: "workspace", layout: :sidebar) do |shell|
  shell.brand { strong { "Northstar" } }

  shell.navigation do
    render NitroKit::AppNavigation.new(label: "Primary navigation") do |navigation|
      navigation.body do
        navigation.item("Overview", href: root_path, icon: :house, current: true)
        navigation.item("Projects", href: projects_path, icon: :folder)
        navigation.spacer
        navigation.item("Settings", href: settings_path, icon: :settings)
      end
    end
  end

  shell.topbar do
    render NitroKit::Button.new("New project", href: new_project_path, variant: :primary)
  end

  shell.main { render Workspace::Dashboard.new }
end
```

The same declarations work with `layout: :topbar` and `layout: :hybrid`. Nitro owns responsive disclosure and focus behavior; the application owns destinations, authorization, current-route selection, and page content. The [customization guide](customization.md#application-shells) covers shell tokens, composition boundaries, and the three complete gallery applications.

## Model-backed forms

Include the Rails helpers a Phlex component actually uses, then select `NitroKit::FormBuilder` explicitly:

```ruby
class RegistrationForm < Phlex::HTML
  include Phlex::Rails::Helpers::DOMID
  include Phlex::Rails::Helpers::FormWith
  include Phlex::Rails::Helpers::Routes
  include Phlex::Rails::Helpers::TurboFrameTag

  def initialize(registration)
    @registration = registration
  end

  def view_template
    turbo_frame_tag(dom_id(@registration, :form)) do
      form_with(
        model: @registration,
        url: registration_path,
        builder: NitroKit::FormBuilder,
        id: dom_id(@registration, :details)
      ) do |form|
        form.hidden_field(:source)
        form.field(:email, as: :email, required: true)
        form.field(
          :role,
          as: :select,
          options: [["Developer", "developer"], ["Designer", "designer"]],
          prompt: "Choose a role",
          required: true
        )
        form.field(:terms, as: :checkbox, label: "I accept the terms")
        form.field(:attachment, as: :file, accept: "text/plain")
        form.submit("Register", data: { turbo_submits_with: "Registering…" })
      end
    end
  end
end
```

`form.field` is the canonical Nitro API. It preserves Rails-generated names, IDs, model values, values-before-type-cast, and errors while rendering the Nitro `Field` and control contracts. A file field marks the enclosing form as `multipart/form-data`. Checkbox fields emit the unchecked hidden value before the checkbox.

The builder also supports Rails-shaped control methods such as `text_field`, `email_field`, `file_field`, `check_box`, `hidden_field`, and `select`. Their ordinary native options belong to the control:

```ruby
form.email_field(
  :email,
  maxlength: 120,
  data: { action: "input->signup#validate" },
  aria: { describedby: "email-help" }
)

form.select(:role, nil) do
  option(value: "developer") { "Developer" }
  option(value: "designer") { "Designer" }
end
```

Captured select blocks stay inside the native `<select>`. Explicit `selected:` values, including arrays for multiple selects, override the model value. `prompt: true` uses Rails' translated “Please select” prompt.

`hidden_field` intentionally renders a standalone hidden Nitro input rather than a visible Field wrapper. `class` and `style` remain rejected. When calling `form.field` directly, use its `control_html:`, `control_aria:`, and `control_data:` boundaries for uncommon control attributes; `html:`, `aria:`, and `data:` describe the Field root.

The complete builder surface includes:

- `field`, `fieldset`, and `group`.
- `dropzone` for native file selection with optional Active Storage direct uploads.
- `select`, `radio_button`, `check_box`/`checkbox`, and `hidden_field`.
- `submit` and `button`.
- Rails-shaped color, date, datetime, email, file, month, number, password, phone/telephone, range, search, text, textarea, time, URL, and week fields.

### File drops and direct uploads

`form.dropzone` derives the native input ID and Rails parameter name, marks the form as multipart, and accepts the same explicit upload contract as `NitroKit::Dropzone`:

```ruby
form.dropzone(
  :attachments,
  title: "Upload evidence",
  description: "Up to three PDF files, each no larger than 5 MB.",
  multiple: true,
  accept: "application/pdf",
  max_files: 3,
  max_bytes: 5 * 1024 * 1024,
  required: true
)
```

The labelled `<input type="file">` remains the source of truth. Without JavaScript it submits ordinary uploaded files. With the controller connected, selection and dropping add removable previews, enforce the declared count, byte, and type constraints, and announce upload and error state. Set `direct_upload: false` to keep the selected `File` objects on that input for the normal multipart request.

The default `direct_upload: true` uses Rails' public `DirectUpload` client. Nitro Kit pins `@rails/activestorage` for importmap applications; bundler-based applications must make that module available alongside the Nitro controller. The host application must install Active Storage's tables, configure a service, and expose the standard `rails_direct_uploads_path` route. Successful uploads submit signed blob IDs under the same Rails parameter name. Removing or replacing a file removes its signed ID, and the form's submit controls remain unavailable while uploads are active.

## Validation responses

Build the model from submitted parameters and render the same Phlex form with status 422 when it is invalid. `NitroKit::FormBuilder` reads the model's real `ActiveModel::Errors`; Field connects help and error IDs through `aria-describedby` and sets `aria-invalid`.

```ruby
def create
  @registration = Registration.new(registration_params)
  @registration.valid? ? render_success : render_errors
end

private
  def render_errors
    respond_to do |format|
      format.turbo_stream do
        render RegistrationStream.new(@registration), status: :unprocessable_entity
      end
      format.html do
        render RegistrationForm.new(@registration), status: :unprocessable_entity
      end
    end
  end
```

Keep the HTML branch. It is the progressive fallback when Turbo is unavailable.

## Turbo Frames and Streams

Use Rails' DOM helper for stable frame targets. A form inside a frame submits to that frame by default; use `data: { turbo_frame: "_top" }` only for navigation that should leave it.

Turbo Stream responses can also be Phlex components:

```ruby
class RegistrationStream < Phlex::HTML
  include Phlex::Rails::Helpers::DOMID
  include Phlex::Rails::Helpers::TurboStream

  def initialize(registration)
    @registration = registration
  end

  def view_template
    turbo_stream.replace(dom_id(@registration, :form)) do
      render RegistrationForm.new(@registration)
    end
  end
end
```

Deliver the submitting user's stream over the HTTP response. A successful non-Turbo POST should redirect with `303 See Other`; an invalid HTML or Turbo submission should return 422. Reserve Action Cable broadcasts for updates that must reach other sessions.

The dummy application's `RailsIntegration::RegistrationForm`, `RegistrationStream`, and request tests are executable reference implementations of this contract.

## Conventional interaction recipes

Use the packaged recipes for complete application flows:

- [Queryable collections](patterns/queryable_collection.md) for GET filters, sorting, pagination, and one results frame.
- [Resource forms](patterns/resource_form.md) for model-backed create/update flows and 422 validation responses.
- [Destructive actions](patterns/destructive_action.md) for reviewed dialogs, compact confirmation, and 303 redirects.
- [Flash and toast](patterns/flash_and_toast.md) for one server-feedback path across Turbo and HTML.
- [Inline edit](patterns/inline_edit.md) for stable resource frames and Cancel behavior.

These recipes are conventions rather than new client-side abstractions. Rails owns the request and policy, Hotwire owns transport and replacement, and Nitro owns the rendered UI contract.
