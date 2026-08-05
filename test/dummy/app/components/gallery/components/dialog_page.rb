module Gallery
  module Components
    class DialogPage < ComponentPage
      private

      def source_note
        "app/components/nitro_kit/dialog.rb"
      end

      def api_note
        "NitroKit::Dialog.new(id:) { |dialog| dialog.trigger; dialog.panel }"
      end

      def component_template
        example_section(
          "Action cluster",
          slug: "dialog-action-cluster",
          description: "The Dialog root belongs inside the action layout that places its trigger."
        ) do
          example(
            "Narrow transcript actions",
            slug: "dialog-narrow-action-cluster",
            mode: :full_width,
            description: "A converted Redact and Permalink Flex once ended before the Dialog sibling, wrapping its trigger. One no-wrap cluster now owns all three actions, including the Dialog root."
          ) do
            render NitroKit::Flex.new(
              dir: :row,
              gap: 1,
              align: :center,
              wrap: :nowrap,
              id: "gallery-dialog-transcript-actions"
            ) do
              render NitroKit::Button.new("Redact", size: :sm, variant: :destructive)
              render NitroKit::Button.new("Permalink", href: "#transcript-permalink", size: :sm)
              render NitroKit::Dialog.new(id: "gallery-dialog-transcript-details") do |dialog|
                dialog.trigger("Details", size: :sm)
                dialog.panel(title: "Transcript details") do
                  p { "The panel block is the yielded application-content slot." }
                end
              end
            end
          end
        end

        example_section(
          "Confirmation sequence",
          slug: "dialog-confirmation",
          description: "The trigger opens a native dialog whose title and description are connected by ID."
        ) do
          example("Remove team member", slug: "dialog-remove-member") do
            render NitroKit::Dialog.new(id: "gallery-dialog-remove-member") do |dialog|
              dialog.trigger("Remove member", variant: :destructive)
              dialog.panel(
                title: "Remove Katherine Johnson?",
                description: "Katherine will immediately lose access to this workspace."
              ) do
                dialog.close_button(label: "Keep team member")
                form(
                  action: "/gallery/destructive_action",
                  method: "post",
                  id: "gallery-dialog-delete-form"
                ) do
                  input(type: "hidden", name: "_method", value: "delete")
                  render NitroKit::Button.new(
                    "Remove team member",
                    type: :submit,
                    variant: :destructive
                  )
                end
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
                dialog.panel(
                  title: "Release notes",
                  description: "This server-rendered panel is deliberately nonmodal.",
                  nonmodal: true
                ) do
                  dialog.close_button
                end
              end
            end
            sample("Required decision", slug: "required-decision") do
              render NitroKit::Dialog.new(
                id: "gallery-dialog-required",
                dismissible: false
              ) do |dialog|
                dialog.trigger("Accept updated terms")
                dialog.panel(
                  title: "Accept the updated terms",
                  description: "This workspace cannot be used until an owner accepts the new processing terms."
                ) do
                  render NitroKit::Button.new(
                    "Accept terms",
                    id: "gallery-dialog-required-accept",
                    variant: :primary,
                    html: { command: "close", commandfor: "gallery-dialog-required-panel" }
                  )
                end
              end
            end
            sample("Disabled trigger", slug: "disabled-trigger") do
              render NitroKit::Dialog.new(id: "gallery-dialog-disabled") do |dialog|
                dialog.trigger("Unavailable action", disabled: true)
                dialog.panel(title: "Unavailable action") do
                  dialog.close_button
                end
              end
            end
          end
        end

        example_section(
          "Long content",
          slug: "dialog-long-content",
          description: "The panel scrolls while the close control stays pinned to the top of the panel."
        ) do
          example("Processing terms", slug: "dialog-long-terms") do
            render NitroKit::Dialog.new(id: "gallery-dialog-long") do |dialog|
              dialog.trigger("Read processing terms")
              dialog.panel(
                title: "Data processing terms",
                description: "Review the complete terms before accepting them for this workspace."
              ) do
                12.times do |index|
                  p do
                    "Section #{index + 1}. The processor handles workspace content only on documented " \
                      "instructions from the controller, keeps every sub-processor under equivalent " \
                      "obligations, and reports a personal-data breach without undue delay."
                  end
                end
                dialog.close_button(label: "Close terms")
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
              dialog.panel(
                title: "Invite a teammate",
                description: "Choose an address and the role this person should receive."
              ) do
                form(id: "gallery-dialog-invite-form", action: "#invite", method: "post") do
                  render NitroKit::FieldGroup.new do
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
                  end
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
