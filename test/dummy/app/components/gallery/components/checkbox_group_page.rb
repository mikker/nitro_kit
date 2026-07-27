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
          "Presentation and orientation",
          slug: "checkbox-group-presentation",
          description: "`presentation:` and `orientation:` change how the same fieldset lays its choices out; " \
            "the markup, names, and hidden sentinel stay identical."
        ) do
          example(
            "Card presentation",
            slug: "checkbox-group-cards",
            description: "Cards suit choices that carry their own explanation, and the selected card is outlined."
          ) do
            render NitroKit::CheckboxGroup.new(
              legend: "Deployment protections",
              description: "Protections apply to every production deploy in this workspace.",
              id: "gallery-checkbox-group-cards",
              name: "workspace[protections]",
              value: %w[review status_checks],
              presentation: :cards,
              options: [
                {
                  label: "Require a reviewer",
                  value: "review",
                  description: "One approving review from outside the authoring team."
                },
                {
                  label: "Require passing status checks",
                  value: "status_checks",
                  description: "The deploy waits for the full test suite and the security scan."
                },
                {
                  label: "Require a deploy window",
                  value: "window",
                  description: "Production deploys are refused outside 08:00–18:00 UTC on weekdays."
                }
              ]
            )
          end

          example(
            "Horizontal orientation",
            slug: "checkbox-group-horizontal",
            description: "Short, self-evident choices read well on one line and wrap when the parent narrows."
          ) do
            render NitroKit::CheckboxGroup.new(
              legend: "Include in the export",
              id: "gallery-checkbox-group-horizontal",
              name: "export[sections]",
              value: %w[members deployments],
              orientation: :horizontal,
              options: [
                [ "Members", "members" ],
                [ "Deployments", "deployments" ],
                [ "Invoices", "invoices" ],
                [ "Audit log", "audit_log" ]
              ]
            )
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
                { label: "Change billing details", value: "billing", disabled: true },
                [ "Export the complete workspace audit log", "export_audit" ]
              ]
            )
          end

          example("Required large group", slug: "checkbox-group-required") do
            render NitroKit::CheckboxGroup.new(
              legend: "Compliance acknowledgements",
              description: "Every reviewer must record at least one acknowledgement.",
              id: "gallery-checkbox-group-required",
              name: "review[acknowledgements]",
              value: %w[retention],
              required: true,
              size: :lg,
              options: [
                [ "Retention policy reviewed", "retention" ],
                [ "Access log reviewed", "access_log" ]
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
              render NitroKit::FieldGroup.new(html: { id: "gallery-checkbox-group-report-fields" }) do
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

          example(
            "Two groups in one fieldset",
            slug: "checkbox-group-fieldset",
            description: "A Fieldset owns the heading and the rhythm between related groups; " \
              "each group keeps its own legend and its own Rails array name."
          ) do
            form(id: "gallery-checkbox-group-alerts-form", action: "#alert-routing", method: "post") do
              render NitroKit::Fieldset.new(
                legend: "Alert routing",
                description: "Choose where each class of alert is delivered.",
                html: { id: "gallery-checkbox-group-alerts-fieldset" }
              ) do
                render NitroKit::CheckboxGroup.new(
                  legend: "Incident alerts",
                  id: "gallery-checkbox-group-incident-alerts",
                  name: "routing[incident]",
                  value: %w[pagerduty email],
                  orientation: :horizontal,
                  options: [ [ "PagerDuty", "pagerduty" ], [ "Email", "email" ], [ "Chat", "chat" ] ]
                )
                render NitroKit::CheckboxGroup.new(
                  legend: "Billing alerts",
                  id: "gallery-checkbox-group-billing-alerts",
                  name: "routing[billing]",
                  value: %w[email],
                  orientation: :horizontal,
                  options: [ [ "Email", "email" ], [ "Chat", "chat" ] ]
                )
              end
            end
          end
        end
      end
    end
  end
end
