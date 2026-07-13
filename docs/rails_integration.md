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

Load the static stylesheet through the Rails asset pipeline:

```erb
<%= stylesheet_link_tag "nitro_kit", "data-turbo-track": "reload" %>
```

Nitro Kit does not require Tailwind. A Tailwind CSS v4 application may load `nitro_kit-tailwind-v4` before Nitro Kit and its compiled Tailwind stylesheet; the adapter establishes cascade order and maps Nitro theme tokens to common Tailwind theme variables.

There is no install generator and no source-copy step.

## Stimulus and importmap

Interactive components use seven gem-owned Stimulus controllers:

- `nk--accordion`
- `nk--combobox`
- `nk--dialog`
- `nk--dropdown`
- `nk--tabs`
- `nk--toast`
- `nk--tooltip`

When `importmap-rails` is present, the engine adds its importmap and asset paths automatically. The application must still install Stimulus and provide the normal controller loader:

```js
import { application } from "controllers/application";
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading";

eagerLoadControllersFrom("controllers", application);
```

Nitro Kit packages no third-party JavaScript. Datepicker and Switch use native inputs and need no controllers.

The engine deliberately boots when importmap is absent. In that configuration, Ruby and CSS remain available, but automatic JavaScript registration does not: a bundler-based application must expose and register the controller modules itself. This prerelease does not ship a JavaScript-package entrypoint.

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
- `select`, `radio_button`, `check_box`/`checkbox`, and `hidden_field`.
- `submit` and `button`.
- Rails-shaped color, date, datetime, email, file, month, number, password, phone/telephone, range, search, text, textarea, time, URL, and week fields.

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
