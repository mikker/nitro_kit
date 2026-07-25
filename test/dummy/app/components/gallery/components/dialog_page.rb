module Gallery
  module Components
    class DialogPage < ComponentPage
      private

      def source_note
        "app/components/nitro_kit/dialog.rb"
      end

      def api_note
        "NitroKit::Dialog.new(id:) { |dialog| dialog.trigger; dialog.dialog }"
      end

      def component_template
        example_section(
          "Confirmation flow",
          slug: "dialog-confirmation",
          description: "The trigger opens a native dialog whose title and description are connected by ID."
        ) do
          example("Remove team member", slug: "dialog-remove-member") do
            render NitroKit::Dialog.new(id: "gallery-dialog-remove-member") do |dialog|
              dialog.trigger("Remove member", variant: :destructive)
              dialog.dialog(
                title: "Remove Katherine Johnson?",
                description: "Katherine will immediately lose access to this workspace."
              ) do
                dialog.close_button(label: "Keep team member")
              end
            end
          end
        end

        example_section(
          "Panel states",
          slug: "dialog-states",
          description: "Declarative commands open modal dialogs; nonmodal is explicit for server-rendered open panels."
        ) do
          example("Nonmodal and unavailable", slug: "dialog-state-combinations", layout: :matrix) do
            sample("Open nonmodal panel", slug: "nonmodal") do
              render NitroKit::Dialog.new(id: "gallery-dialog-open") do |dialog|
                dialog.dialog(
                  title: "Release notes",
                  description: "This server-rendered panel is deliberately nonmodal.",
                  nonmodal: true
                ) do
                  dialog.close_button
                end
              end
            end
            sample("Disabled trigger", slug: "disabled-trigger") do
              render NitroKit::Dialog.new(id: "gallery-dialog-disabled") do |dialog|
                dialog.trigger("Unavailable action", disabled: true)
                dialog.dialog(title: "Unavailable action") do
                  dialog.close_button
                end
              end
            end
          end
        end

        example_section(
          "Form composition",
          slug: "dialog-form",
          description: "Field, Input, and Button compose directly inside a dialog without a second template API."
        ) do
          example("Invite a teammate", slug: "dialog-invite-form") do
            render NitroKit::Dialog.new(id: "gallery-dialog-invite") do |dialog|
              dialog.trigger("Invite teammate", variant: :primary)
              dialog.dialog(
                title: "Invite a teammate",
                description: "Choose an address and the role this person should receive."
              ) do
                form(id: "gallery-dialog-invite-form", action: "#invite", method: "post") do
                  render NitroKit::Field.new(
                    nil,
                    :email,
                    as: :email,
                    id: "gallery-dialog-invite-email",
                    name: "invitation[email]",
                    value: "katherine@example.test",
                    label: "Email",
                    autocomplete: "email",
                    required: true,
                    html: { id: "gallery-dialog-invite-email-field" }
                  )
                  render NitroKit::Field.new(
                    nil,
                    :role,
                    as: :select,
                    id: "gallery-dialog-invite-role",
                    name: "invitation[role]",
                    value: "member",
                    label: "Role",
                    options: Gallery::Forms::TeamInvitation::ROLES,
                    html: { id: "gallery-dialog-invite-role-field" }
                  )
                  render NitroKit::Button.new(
                    "Send invitation",
                    id: "gallery-dialog-invite-submit",
                    type: :submit,
                    variant: :primary
                  )
                  dialog.close_button(label: "Cancel invitation")
                end
              end
            end
          end
        end
      end
    end
  end
end
