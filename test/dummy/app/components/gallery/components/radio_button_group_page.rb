module Gallery
  module Components
    class RadioButtonGroupPage < ComponentPage
      private

      def source_note
        "app/components/nitro_kit/radio_button_group.rb"
      end

      def api_note
        "NitroKit::RadioButtonGroup.new(legend:, options:, name:, value:, required:)"
      end

      def component_template
        example_section(
          "Selection groups",
          slug: "radio-button-group-selection",
          description: "One fieldset owns the legend, description, same-name controls, and selected value."
        ) do
          example("Default member role", slug: "radio-button-group-role") do
            render NitroKit::RadioButtonGroup.new(
              legend: "Default member role",
              description: "New invitations use this role unless an administrator chooses another.",
              id: "gallery-radio-button-group-role",
              name: "workspace[default_role]",
              value: "member",
              required: true,
              options: [
                [ "Administrator", "admin" ],
                { label: "Member", value: "member", id: "gallery-role-member" },
                NitroKit::Choice.new(
                  label: "Viewer",
                  value: "viewer",
                  disabled: true,
                  id: "gallery-role-viewer"
                )
              ]
            )
          end

          example("Boundary counts", slug: "radio-button-group-boundaries", layout: :matrix) do
            sample("One choice", slug: "one") do
              render NitroKit::RadioButtonGroup.new(
                legend: "Deployment target",
                id: "gallery-radio-button-group-one",
                name: "deployment[target]",
                value: "production",
                options: [ [ "Production", "production" ] ]
              )
            end
            sample("No selection", slug: "none") do
              render NitroKit::RadioButtonGroup.new(
                legend: "Export format",
                id: "gallery-radio-button-group-none",
                name: "export[format]",
                value: nil,
                options: [ [ "CSV", "csv" ], [ "JSON", "json" ], [ "PDF", "pdf" ] ]
              )
            end
          end
        end

        example_section(
          "Availability and pressure",
          slug: "radio-button-group-states",
          description: "Sizes, disabled groups, many options, and long labels retain the same deterministic structure."
        ) do
          example("Large retention policies", slug: "radio-button-group-many") do
            render NitroKit::RadioButtonGroup.new(
              legend: "Workspace retention policy for audit events, credential activity, and deployment metadata",
              description: "Changing the policy affects future retention and never shortens an active legal hold.",
              id: "gallery-radio-button-group-many",
              name: "workspace[retention_policy]",
              value: "regulated",
              size: :lg,
              options: [
                [ "Standard ninety-day retention", "standard" ],
                [ "Extended one-year retention", "extended" ],
                [ "Regulated seven-year retention with immutable audit exports", "regulated" ],
                { label: "Legacy indefinite retention", value: "legacy", disabled: true }
              ]
            )
          end

          example("Segmented presentation", slug: "radio-button-group-segmented") do
            render NitroKit::RadioButtonGroup.new(
              legend: "Table density",
              description: "Segmented groups stay native radios and drop the indicator.",
              id: "gallery-radio-button-group-segmented",
              name: "table[density]",
              value: "comfortable",
              presentation: :segmented,
              orientation: :horizontal,
              options: [
                [ "Compact", "compact" ],
                [ "Comfortable", "comfortable" ],
                [ "Spacious", "spacious" ]
              ]
            )
          end

          example("Disabled group", slug: "radio-button-group-disabled") do
            render NitroKit::RadioButtonGroup.new(
              legend: "Billing currency",
              description: "Contact support before the next renewal date to change currency.",
              id: "gallery-radio-button-group-disabled",
              name: "billing[currency]",
              value: "USD",
              disabled: true,
              options: [ [ "United States dollar", "USD" ], [ "Euro", "EUR" ] ]
            )
          end
        end

        example_section(
          "Rails form builder",
          slug: "radio-button-group-builder",
          description: "A builder field derives the selected model value, names, IDs, descriptions, and errors."
        ) do
          example("Invalid invitation role", slug: "radio-button-group-invitation-role") do
            invitation = Gallery::FormExamples.team_invitation(:invalid)

            form_with(
              model: invitation,
              scope: :invitation,
              url: "#invitation-role-group",
              builder: NitroKit::FormBuilder,
              id: "gallery-radio-button-group-invitation-form"
            ) do |form|
              form.field(
                :role,
                as: :radio_group,
                id: "gallery-radio-button-group-invitation-role",
                label: "Invitation role",
                description: "Choose the least privileged role that supports the member's work.",
                options: [ [ "Administrator", "admin" ], [ "Member", "member" ], [ "Viewer", "viewer" ] ],
                required: true
              )
              form.submit("Send invitation", id: "gallery-radio-button-group-invitation-save")
            end
          end
        end
      end
    end
  end
end
