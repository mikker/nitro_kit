# Flash and toast

Rails flash is the server-side feedback contract. Render it once in the application layout with Nitro's toast adapter so redirects, Turbo visits, and full-page fallbacks all use the same path.

```ruby
class UI::ApplicationLayout < Phlex::HTML
  include Phlex::Rails::Layout
  include Phlex::Rails::Helpers::Flash

  def view_template
    doctype
    html do
      head do
        stylesheet_link_tag("nitro_kit", data: { turbo_track: "reload" })
      end
      body do
        render NitroKit::Toast::FlashMessages.new(flash: flash)
        yield
      end
    end
  end
end
```

Controllers set ordinary flash while redirecting:

```ruby
redirect_to projects_path, status: :see_other, notice: "Project created"
redirect_to billing_path, status: :see_other, alert: "Payment method was declined"
```

`notice` maps to the default presentation, `alert` and `error` to error, and `success`, `warning`, and `info` to their matching variants. Dismissible toast items are Turbo-temporary so a cached page does not replay old feedback.

Use `flash.now` only when rendering in the current request:

```ruby
flash.now[:alert] = "Import failed"
render UI::ImportForm.new(@import), status: :unprocessable_entity
```

For a request-scoped Turbo Stream that does not redirect, update a stable notification region in the same stream response. Keep the HTML branch and flash fallback. Do not introduce a client-side notification store for server outcomes.

## Tests

Controller tests assert the flash severity and message. One layout or integration test should prove the flash renders through `section[data-nk=toast]`. Nitro's own tests cover timers and dismissal behavior.
