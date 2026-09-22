# Destructive action

**Audience:** Coding agents and developers implementing delete, revoke,
archive, or similarly destructive Rails actions.

## Summary

- Use `NitroKit::Dialog` for destructive confirmations, including simple
  deletion, member removal, and invitation revocation. A short consequence
  still belongs in the application dialog, not a native browser confirm.
- A real Rails form owns the request, and the server owns authorization.
- Put permanent deletion on the edit route, not the operational show route.
- Use a server-rendered review route when confirmation must work without
  JavaScript or Invoker Commands.

## Choose one confirmation path

Use a Dialog with a clear title, a short consequence, a Cancel control, and a
real Rails form with a specifically named destructive submit. Use stable,
record-specific dialog IDs when rendering repeated actions in a table.
Put permanent deletion in an edit-page `DangerZone`; invitation revocation
may open a compact Dialog from its table row without adding a DangerZone.

Use an ordinary link to a server-rendered review page when confirmation must
work without client JavaScript. Do not add `turbo_confirm` to a Dialog form:
it would ask twice. Native browser confirmations are not the default Nitro Kit
experience; keep them only when the host application explicitly requires them.

```ruby
render NitroKit::DangerZone.new(
  title: "Delete project",
  description: "This permanently removes the project.",
  id: dom_id(project, :danger_zone)
) do |zone|
  zone.confirmation do
    render NitroKit::Dialog.new(id: dom_id(project, :delete_dialog)) do |dialog|
      dialog.trigger("Review deletion", variant: :destructive)
      dialog.panel(title: "Delete #{project.name}?") do
        render NitroKit::Flex.new(dir: :row, gap: 2, justify: :end, wrap: :wrap) do
          render NitroKit::Button.new(
            "Cancel",
            html: { command: "close", commandfor: "#{dialog.id}-panel" }
          )
          form_with(
            model: project,
            method: :delete,
            data: { turbo_frame: "_top" }
          ) do
            render NitroKit::Button.new(
              "Delete project",
              type: :submit,
              variant: :destructive
            )
          end
        end
      end
    end
  end
  zone.escape NitroKit::Button.new("Keep project", href: project_path(project))
end
```

Keep Cancel and the destructive action together in this right-aligned row.
`dialog.close_button` configures the corner X and its accessible label; it does
not render a visible footer Cancel button. The ordinary Cancel Button uses
native commands with Nitro's existing browser fallback.

The `_top` target keeps the redirect out of a surrounding frame. The dialog is
not a security boundary; load and authorize the record on the server.

```ruby
def destroy
  project = Current.account.projects.find(params[:id])
  project.destroy!
  redirect_to projects_path, status: :see_other, notice: "Project deleted"
end
```

Without JavaScript, a form inside a closed Dialog is reachable only where
Invoker Commands are supported. `data-turbo-confirm` also requires Turbo. Use
the server-owned review route when confirmation must be unavoidable. See
[Browser support](../browser_support.md).

## Tests

Request-test authorization, mutation, flash, and the `303` redirect. For a
reviewed flow, system-test open, cancel with focus restoration, and confirm.
