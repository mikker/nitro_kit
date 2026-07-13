module Gallery
  module Components
    class AccordionPage < ComponentPage
      private

      def source_note
        "app/components/nitro_kit/accordion.rb"
      end

      def api_note
        "NitroKit::Accordion.new(id:, mode:) { |accordion| accordion.item }"
      end

      def component_template
        example_section(
          "Account questions",
          slug: "accordion-account",
          description: "Stable keys produce deterministic trigger and region relationships."
        ) do
          example("Billing questions", slug: "accordion-billing-questions") do
            render NitroKit::Accordion.new(id: "gallery-accordion-billing", mode: :single) do |accordion|
              accordion.item(:invoices, title: "Where can I find invoices?", expanded: true) do
                "Invoices are available from Billing settings."
              end
              accordion.item(:currency, title: "Can I change billing currency?") do
                "Contact support before the next renewal date."
              end
              accordion.item(:legacy, title: "Legacy plan details", disabled: true) do
                "Legacy plan changes are currently unavailable."
              end
            end
          end
        end

        example_section(
          "Modes and item counts",
          slug: "accordion-modes",
          description: "Single and multiple expansion modes remain useful from one disclosure through a dense set."
        ) do
          example("Boundary counts", slug: "accordion-boundary-counts", layout: :matrix) do
            sample("One closed item", slug: "one-closed") do
              render NitroKit::Accordion.new(id: "gallery-accordion-one", mode: :multiple) do |accordion|
                accordion.item(:summary, title: "Workspace summary") do
                  "Mothership is on the Team plan with twelve active members."
                end
              end
            end

            sample("One open item", slug: "one-open") do
              render NitroKit::Accordion.new(id: "gallery-accordion-one-open", mode: :single) do |accordion|
                accordion.item(:summary, title: "Workspace summary", expanded: true) do
                  "Mothership is on the Team plan with twelve active members."
                end
              end
            end
          end

          example("Multiple open items", slug: "accordion-multiple-open") do
            render NitroKit::Accordion.new(id: "gallery-accordion-multiple", mode: :multiple) do |accordion|
              accordion.item(:general, title: "General", expanded: true) do
                "Workspace name, locale, and time zone."
              end
              accordion.item(:members, title: "Members and access", expanded: true) do
                "Roles, pending invitations, and session policies."
              end
              accordion.item(:billing, title: "Billing") do
                "Plan, payment method, and invoice history."
              end
              accordion.item(:advanced, title: "Advanced controls", disabled: true) do
                "Advanced controls are managed by the organization owner."
              end
            end
          end
        end

        example_section(
          "Content pressure",
          slug: "accordion-pressure",
          description: "Long labels, long copy, nested markup, and many items use the same keyed declaration API."
        ) do
          example("Long and nested content", slug: "accordion-long-nested") do
            render NitroKit::Accordion.new(id: "gallery-accordion-pressure", mode: :multiple) do |accordion|
              accordion.item(
                :retention,
                title: "How does workspace data retention change when a long-running organization changes plans?",
                expanded: true
              ) do
                p do
                  "Workspace records remain available throughout the current billing period. Exported audit events " \
                    "continue to use their original timestamps and actor identifiers."
                end
                ul do
                  li { "Active members keep their existing access until the renewal date." }
                  li { "Pending invitations can be revoked before the plan changes." }
                  li { "Invoice and audit exports remain available to workspace owners." }
                end
              end
              accordion.item(:exports, title: "Exports") { "Exports are prepared as UTF-8 CSV files." }
              accordion.item(:regions, title: "Data regions") { "The workspace currently uses the EU region." }
              accordion.item(:sessions, title: "Active sessions") { "Owners can revoke individual sessions." }
              accordion.item(:webhooks, title: "Webhook delivery") { "Failed deliveries retry with backoff." }
              accordion.item(:legacy, title: "Legacy retention controls", disabled: true) do
                "Legacy controls cannot be changed for this workspace."
              end
            end
          end
        end

        example_section(
          "Detail composition",
          slug: "accordion-detail",
          description: "An operational detail view composes cards, status, tables, and grouped actions inside panels."
        ) do
          example("Deployment detail", slug: "accordion-deployment-detail") do
            render NitroKit::Accordion.new(id: "gallery-accordion-deployment", mode: :single) do |accordion|
              accordion.item(:overview, title: "Deployment overview", expanded: true) do
                render NitroKit::Card.new(id: "gallery-accordion-deployment-card") do |card|
                  card.title("Billing portal · release 1842", level: 3)
                  card.body do
                    render NitroKit::Badge.new(
                      "Operational",
                      id: "gallery-accordion-deployment-status",
                      color: :success,
                      size: :sm
                    )
                    p { "Deployed by Grace Hopper on July 13, 2026 at 08:42 UTC." }
                  end
                  card.footer do
                    render NitroKit::ButtonGroup.new(
                      id: "gallery-accordion-deployment-actions",
                      label: "Deployment actions"
                    ) do |group|
                      group.button(
                        "View logs",
                        id: "gallery-accordion-deployment-logs",
                        href: "#deployment-logs",
                        variant: :ghost,
                        size: :sm
                      )
                      group.button(
                        "Roll back",
                        id: "gallery-accordion-deployment-rollback",
                        variant: :destructive,
                        size: :sm
                      )
                    end
                  end
                end
              end

              accordion.item(:checks, title: "Health checks") do
                render_health_checks
              end

              accordion.item(:environment, title: "Environment and access") do
                render NitroKit::Card.new(id: "gallery-accordion-environment-card") do |card|
                  card.title("Production environment", level: 3)
                  card.body do
                    p { "EU region · protected branch · owner approval required" }
                  end
                  card.footer do
                    render NitroKit::Badge.new(
                      "Protected",
                      id: "gallery-accordion-environment-status",
                      variant: :outline,
                      color: :info
                    )
                  end
                end
              end
            end
          end
        end
      end

      def render_health_checks
        render NitroKit::Table.new(
          id: "gallery-accordion-checks-table",
          table_html: { id: "gallery-accordion-checks-table-element" }
        ) do |table|
          table.caption("Deployment health checks")
          table.thead do
            table.tr do
              table.th("Check")
              table.th("Result", align: :right)
            end
          end
          table.tbody do
            [ [ "Application boot", "Passed" ], [ "Database connection", "Passed" ], [ "Queue latency", "42 ms" ] ].each do |name, result|
              table.tr do
                table.th(name, scope: :row)
                table.td(result, align: :right)
              end
            end
          end
        end
      end
    end
  end
end
