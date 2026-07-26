module Gallery
  module Components
    class RadioButtonPage < ComponentPage
      private

      def source_note
        "app/components/nitro_kit/radio_button.rb"
      end

      def api_note
        "NitroKit::RadioButton.new(label:, id:, name:, value:, checked:, size:)"
      end

      def component_template
        example_section(
          "Native selection",
          slug: "radio-button-selection",
          description: "Radio buttons share a native name and the browser owns selection; nothing mirrors checked state into markup."
        ) do
          example("Workspace visibility", slug: "radio-button-visibility") do
            render NitroKit::RadioButton.new(
              label: "Private to invited members",
              id: "gallery-radio-button-private-control",
              name: "workspace[visibility]",
              value: "private",
              checked: true,
              required: true,
              html: { id: "gallery-radio-button-private" }
            )
            render NitroKit::RadioButton.new(
              label: "Visible to the organization",
              id: "gallery-radio-button-organization-control",
              name: "workspace[visibility]",
              value: "organization",
              required: true,
              html: { id: "gallery-radio-button-organization" }
            )
            render NitroKit::RadioButton.new(
              label: "Public on the web",
              id: "gallery-radio-button-public-control",
              name: "workspace[visibility]",
              value: "public",
              disabled: true,
              required: true,
              html: { id: "gallery-radio-button-public" }
            )
          end
        end

        example_section(
          "Size and label pressure",
          slug: "radio-button-states",
          description: "Both sizes, explicitly named standalone controls, disabled state, and long labels preserve native radio semantics."
        ) do
          example("State matrix", slug: "radio-button-state-matrix", layout: :matrix) do
            sample("Medium", slug: "medium") do
              render NitroKit::RadioButton.new(
                label: "Member",
                id: "gallery-radio-button-medium-control",
                name: "member[role]",
                value: "member",
                checked: true,
                size: :md,
                html: { id: "gallery-radio-button-medium" }
              )
            end
            sample("Large", slug: "large") do
              render NitroKit::RadioButton.new(
                label: "Administrator",
                id: "gallery-radio-button-large-control",
                name: "member[role]",
                value: "admin",
                size: :lg,
                html: { id: "gallery-radio-button-large" }
              )
            end
            sample("Standalone", slug: "standalone") do
              render NitroKit::RadioButton.new(
                id: "gallery-radio-button-standalone-control",
                name: "table[selection]",
                value: "deployment-1842",
                control_aria: { label: "Select deployment 1842" },
                html: { id: "gallery-radio-button-standalone" }
              )
            end
            sample("Invalid", slug: "invalid") do
              render NitroKit::RadioButton.new(
                label: "Unsupported region",
                id: "gallery-radio-button-invalid-control",
                name: "deployment[region]",
                value: "unsupported",
                checked: true,
                invalid: true,
                html: { id: "gallery-radio-button-invalid" }
              )
            end
            sample("Long label", slug: "long") do
              render NitroKit::RadioButton.new(
                label: "Retain audit events and credential activity for the extended regulated compliance period",
                id: "gallery-radio-button-long-control",
                name: "retention[policy]",
                value: "regulated",
                html: { id: "gallery-radio-button-long" }
              )
            end
          end
        end

        example_section(
          "Rails form builder",
          slug: "radio-button-builder",
          description: "Individual builder radio helpers preserve Rails naming and explicit accessible names."
        ) do
          example("Invitation role", slug: "radio-button-invitation-role") do
            invitation = Gallery::FormExamples.team_invitation

            form_with(
              model: invitation,
              scope: :invitation,
              url: "#invitation-role",
              builder: NitroKit::FormBuilder,
              id: "gallery-radio-button-invitation-form"
            ) do |form|
              form.radio_button(
                :role,
                "admin",
                id: "gallery-radio-button-builder-admin",
                aria: { label: "Administrator" }
              )
              form.radio_button(
                :role,
                "member",
                id: "gallery-radio-button-builder-member",
                aria: { label: "Member" }
              )
              form.radio_button(
                :role,
                "viewer",
                id: "gallery-radio-button-builder-viewer",
                aria: { label: "Viewer" },
                disabled: true
              )
            end
          end
        end
      end
    end
  end
end
