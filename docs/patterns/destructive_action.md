# Destructive action

**Audience:** Coding agents and developers implementing delete, revoke,
archive, or similarly destructive Rails actions.

## Summary

- Use `NitroKit::Dialog` when the user must review impact or type confirmation;
  use Turbo's native browser confirmation for a one-sentence consequence.
- A real Rails form owns the request, and the server owns authorization.
- Put permanent deletion on the edit route, not the operational show route.
- Use a server-rendered review route when confirmation must work without
  JavaScript or Invoker Commands.

## Choose one confirmation path

| Need                                            | Pattern                                                         |
| ----------------------------------------------- | --------------------------------------------------------------- |
| One-sentence confirmation                       | Real form with `data: { turbo_confirm: "Delete permanently?" }` |
| Reviewed impact or typed confirmation           | `DangerZone` containing a Dialog and real form                  |
| Confirmation required without client JavaScript | Ordinary link to a server-rendered review page                  |

Never stack `turbo_confirm` inside a Dialog.

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
        dialog.close_button(label: "Cancel deletion")
      end
    end
  end
  zone.escape NitroKit::Button.new("Keep project", href: project_path(project))
end
```

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
