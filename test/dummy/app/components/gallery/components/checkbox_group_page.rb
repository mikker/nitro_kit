module Gallery
  module Components
    class CheckboxGroupPage < ComponentPage
      private

      def source_note
        "app/components/nitro_kit/checkbox_group.rb"
      end

      def api_note
        "NitroKit::CheckboxGroup.new(legend:, options:, name:, value:)"
      end

      def component_template
        example_section(
          "Choice normalization",
          slug: "checkbox-group-choices",
          description: "Typed choices normalize into one fieldset, one unchecked sentinel, and deterministic checkbox IDs."
        ) do
          example("Notification channels", slug: "checkbox-group-notifications") do
            render NitroKit::CheckboxGroup.new(
              legend: "Notification channels",
              description: "Choose every channel that should receive production alerts.",
              id: "gallery-checkbox-group-notifications",
              name: "preferences[channels]",
              value: [ "Email", "security" ],
              options: [
                "Email",
                [ "Security dashboard", "security" ],
                { label: "Team operations channel", value: "operations", id: "gallery-channel-operations" },
                NitroKit::Choice.new(
                  label: "Legacy pager",
                  value: "pager",
                  disabled: true,
                  id: "gallery-channel-pager"
                )
              ]
            )
          end

          example("Boundary counts", slug: "checkbox-group-boundaries", layout: :matrix) do
            sample("One choice", slug: "one") do
              render NitroKit::CheckboxGroup.new(
                legend: "Workspace digest",
                id: "gallery-checkbox-group-one",
                name: "preferences[digest]",
                value: [],
                options: [ [ "Weekly summary", "weekly" ] ]
              )
            end
            sample("No selection", slug: "none-selected") do
              render NitroKit::CheckboxGroup.new(
                legend: "Export formats",
                id: "gallery-checkbox-group-none",
                name: "export[formats]",
                value: [],
                options: [ [ "CSV", "csv" ], [ "JSON", "json" ], [ "PDF", "pdf" ] ]
              )
            end
          end
        end

        example_section(
          "Availability and pressure",
          slug: "checkbox-group-states",
          description: "Disabled groups, disabled individual choices, many choices, and long copy retain fieldset semantics."
        ) do
          example("Many permissions", slug: "checkbox-group-many") do
            render NitroKit::CheckboxGroup.new(
              legend: "Workspace permissions inherited by members of the release engineering team",
              description: "Selected permissions apply to new team members and do not replace individual owner grants.",
              id: "gallery-checkbox-group-many",
              name: "team[permissions]",
              value: %w[deploy read_logs manage_incidents],
              options: [
                [ "Deploy to production", "deploy" ],
                [ "Read deployment logs", "read_logs" ],
                [ "Manage incidents and customer-visible status updates", "manage_incidents" ],
                [ "Rotate production credentials", "rotate_credentials" ],
                [ "Change billing details", "billing", true ],
                [ "Export the complete workspace audit log", "export_audit" ]
              ]
            )
          end

          example("Disabled group", slug: "checkbox-group-disabled") do
            render NitroKit::CheckboxGroup.new(
              legend: "Legacy synchronization targets",
              description: "This configuration is locked while migration is in progress.",
              id: "gallery-checkbox-group-disabled",
              name: "legacy[targets]",
              value: %w[warehouse archive],
              disabled: true,
              options: [ [ "Reporting warehouse", "warehouse" ], [ "Compliance archive", "archive" ] ]
            )
          end
        end

        example_section(
          "Form composition",
          slug: "checkbox-group-form",
          description: "The direct group submits conventional Rails array names inside an ordinary Phlex form."
        ) do
          example("Report subscription", slug: "checkbox-group-report-form") do
            form(id: "gallery-checkbox-group-report-form", action: "#report-subscription", method: "post") do
              render NitroKit::CheckboxGroup.new(
                legend: "Reports to receive",
                description: "Select any number of recurring workspace reports.",
                id: "gallery-checkbox-group-reports",
                name: "subscription[reports]",
                value: %w[deployments billing],
                options: [
                  [ "Deployment activity", "deployments" ],
                  [ "Member access changes", "access" ],
                  [ "Billing summary", "billing" ]
                ]
              )
              render NitroKit::Button.new(
                "Save subscriptions",
                id: "gallery-checkbox-group-report-save",
                type: :submit,
                variant: :primary
              )
            end
          end
        end
      end
    end
  end
end
