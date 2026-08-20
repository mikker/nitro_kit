# Flash and toast

**Audience:** Coding agents and developers presenting Rails server feedback.

## Summary

- Rails flash is the server-side feedback contract; render
  `NitroKit::Toast::FlashMessages` once in the application layout.
- Use redirect flash for navigation and `flash.now` when rendering the current
  request.
- Toast items are Turbo-temporary so cached pages do not replay them; the
  region keeps a stable address for stream updates.
- Do not add a client-side notification store for server outcomes.

```ruby
body do
  render NitroKit::Toast::FlashMessages.new(flash: flash)
  yield
end
```

Controllers use ordinary Rails flash:

```ruby
redirect_to projects_path, status: :see_other, notice: "Project created"

flash.now[:alert] = "Import failed"
render UI::ImportForm.new(@import), status: :unprocessable_entity
```

`notice` uses the default presentation; `alert` and `error` map to error;
`success`, `warning`, and `info` map to matching variants. A request-scoped
Turbo Stream may update the same stable Toast list, but must keep an HTML
branch and flash fallback.

## Tests

Assert flash severity and message in request tests. One layout or integration
test should prove rendering through `section[data-nk=toast]`.
