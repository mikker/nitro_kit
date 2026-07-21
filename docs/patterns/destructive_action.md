# Destructive action

Use a native Nitro Dialog when the user needs to review impact or type confirmation. The dialog only owns accessible disclosure and focus behavior; a real Rails form owns the destructive request.

## Reviewed deletion

Place this composition on the resource's edit page. A show page is the
operational home; it should not advertise permanent deletion on every visit.

```ruby
module UI
  class DeleteProject < Phlex::HTML
    include Phlex::Rails::Helpers::DOMID
    include Phlex::Rails::Helpers::FormWith
    include Phlex::Rails::Helpers::Routes

    def initialize(project)
      @project = project
    end

    def view_template
      render NitroKit::DangerZone.new(
        title: "Delete project",
        description: "This permanently removes the project and its activity.",
        id: dom_id(project, :danger_zone)
      ) do |zone|
        zone.confirmation do
          render NitroKit::Dialog.new(id: dom_id(project, :delete_dialog)) do |dialog|
            dialog.trigger("Review deletion", variant: :destructive)
            dialog.dialog(
              title: "Delete #{project.name}?",
              description: "This action cannot be undone."
            ) do
              form_with(
                model: project,
                url: project_path(project),
                method: :delete,
                data: { turbo_frame: "_top" }
              ) do
                render NitroKit::Button.new(
                  "Delete project",
                  type: :submit,
                  variant: :destructive,
                  data: { turbo_submits_with: "Deleting…" }
                )
              end
              dialog.close_button(label: "Cancel deletion")
            end
          end
        end
        zone.escape NitroKit::Button.new("Keep project", href: project_path(project))
      end
    end

    private
      attr_reader :project
  end
end
```

The top-level target makes a successful redirect navigate the page rather than trying to render the destination inside the surrounding settings frame.

```ruby
def destroy
  project = Current.account.projects.find(params[:id])
  project.destroy!
  redirect_to projects_path, status: :see_other, notice: "Project deleted"
end
```

Authorize and load the record on the server even when the dialog is open. The confirmation UI is not a security boundary.

## Compact confirmation

When the consequence fits in one sentence and needs no review UI, keep the ordinary request and use Turbo's confirm hook:

```ruby
form_with(model: project, url: project_path(project), method: :delete) do
  render NitroKit::Button.new(
    "Delete",
    type: :submit,
    variant: :destructive,
    data: { turbo_confirm: "Delete this project permanently?" }
  )
end
```

Do not stack `turbo_confirm` inside a Dialog. Choose one confirmation surface.

## Tests

Request-test authorization, deletion, 303 redirect, and flash. System-test the dialog only when the reviewed flow matters: trigger opens it, Cancel closes and restores focus, and the destructive submit removes the record.
