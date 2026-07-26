module Gallery
  module Components
    class DangerZonePage < ComponentPage
      private

      def component_template
        example_section(
          "Impact, confirmation, and escape",
          slug: "danger-zone-pressure",
          description: "Nitro owns warning anatomy while applications own confirmation mechanics and destructive policy."
        ) do
          example("Direct confirmation form", slug: "danger-zone-form", mode: :full_width) do
            render NitroKit::DangerZone.new(
              title: "Revoke all sessions",
              description: "Every browser and device will need to authenticate again.",
              id: "gallery-danger-zone-form"
            ) do |zone|
              zone.confirmation do
                form(action: "#revoke", method: :post, id: "gallery-danger-zone-revoke-form") do
                  render NitroKit::Button.new("Revoke sessions", type: :submit, variant: :destructive)
                end
              end
              zone.escape NitroKit::Button.new("Keep sessions", href: "#security")
            end
          end

          example("Disabled by caller policy", slug: "danger-zone-disabled", mode: :full_width) do
            render NitroKit::DangerZone.new(
              title: "Delete workspace",
              description: "Transfer workspace ownership before deletion becomes available.",
              id: "gallery-danger-zone-disabled"
            ) do |zone|
              zone.confirmation do
                form(action: "#delete-disabled", method: :post, id: "gallery-danger-zone-disabled-form") do
                  render NitroKit::Button.new("Delete workspace", type: :submit, variant: :destructive, disabled: true)
                end
              end
              zone.escape NitroKit::Button.new("Review ownership", href: "#ownership")
            end
          end

          example("Dialog confirmation", slug: "danger-zone-dialog", mode: :full_width) do
            render NitroKit::DangerZone.new(
              title: "Delete production credential",
              description: "Requests using this secret will fail immediately and the secret cannot be recovered.",
              id: "gallery-danger-zone-dialog"
            ) do |zone|
              zone.confirmation do
                render NitroKit::Dialog.new(id: "gallery-danger-zone-confirm-dialog") do |dialog|
                  dialog.trigger("Review deletion", variant: :destructive)
                  dialog.panel(
                    title: "Delete Production Deploy credential?",
                    description: "Confirm only after every production client has rotated to another credential."
                  ) do
                    form(action: "#delete-credential", method: :post, id: "gallery-danger-zone-dialog-form") do
                      render NitroKit::FieldGroup.new do
                        render NitroKit::Field.new(nil, :confirmation, label: "Type Production Deploy", required: true)
                        render NitroKit::Button.new("Delete credential", type: :submit, variant: :destructive)
                      end
                    end
                    dialog.close_button(label: "Cancel deletion")
                  end
                end
              end
              zone.escape NitroKit::Button.new("Return to credentials", href: "#credentials")
            end
          end

          example(
            "Settings footer without an escape",
            slug: "danger-zone-no-escape",
            mode: :full_width,
            description: "At the bottom of a settings page there is nothing to escape to, so the escape action is omitted."
          ) do
            render NitroKit::DangerZone.new(
              title: "Delete this project",
              description: "Deleting removes every task, comment, and attachment in this project.",
              id: "gallery-danger-zone-no-escape"
            ) do |zone|
              zone.confirmation do
                form(action: "#delete-project", method: :post, id: "gallery-danger-zone-no-escape-form") do
                  render NitroKit::Button.new("Delete project", type: :submit, variant: :destructive)
                end
              end
            end
          end

          example("Long nested impact", slug: "danger-zone-long", mode: :full_width) do
            render NitroKit::Container.new(size: :lg, id: "gallery-danger-zone-long-container") do
              render NitroKit::DangerZone.new(
                title: "Permanently delete International Research, Production, and Reliability Engineering",
                description: "This removes every project, service credential, invoice attachment, audit event, pending invitation, and retained operational export for all regions. Regulatory archives outside this workspace are unaffected and must be managed separately.",
                id: "gallery-danger-zone-long"
              ) do |zone|
                zone.confirmation do
                  form(action: "#delete-long", method: :post, id: "gallery-danger-zone-long-form") do
                    render NitroKit::Button.new("Permanently delete workspace", type: :submit, variant: :destructive)
                  end
                end
                zone.escape NitroKit::Button.new("Keep workspace and return to settings", href: "#settings")
              end
            end
          end
        end
      end

      def source_note
        "The confirmation leaf can be a Rails form or Dialog composition. Hidden IDs, authorization, consent, routes, and method semantics remain application code."
      end

      def api_note
        "Supply the required title and description through constructor text or matching compound methods. confirmation requires exactly one caller block. escape is optional and accepts at most one non-destructive NitroKit::Button."
      end
    end
  end
end
