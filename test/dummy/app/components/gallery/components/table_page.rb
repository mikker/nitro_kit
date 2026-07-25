module Gallery
  module Components
    class TablePage < ComponentPage
      private

      def source_note
        "app/components/nitro_kit/table.rb"
      end

      def api_note
        "NitroKit::Table.new { |table| table.thead; table.tbody }"
      end

      def component_template
        example_section(
          "Semantic structure",
          slug: "table-structure",
          description: "Captions, column headers, row headers, and alignment remain explicit in Ruby and HTML."
        ) do
          example("Workspace members", slug: "table-workspace-members", mode: :full_width) do
            render NitroKit::Table.new(
              id: "gallery-table-members",
              table_html: { id: "gallery-table-members-element" }
            ) do |table|
              table.caption("Workspace members")
              table.thead do
                table.tr do
                  table.th("Name")
                  table.th("Role")
                  table.th("Status", align: :right)
                end
              end
              table.tbody do
                Gallery::Data.members.each do |member|
                  table.tr do
                    table.th(member.name, scope: :row)
                    table.td(member.role.to_s.humanize)
                    table.td(member.status.to_s.humanize, align: :right)
                  end
                end
              end
            end
          end
        end

        example_section(
          "Data and actions",
          slug: "table-actions",
          description: "Badges and compact actions compose inside cells without weakening table semantics."
        ) do
          example("Invoice history", slug: "table-invoice-history", mode: :full_width) do
            render NitroKit::Table.new(
              id: "gallery-table-invoices",
              table_html: { id: "gallery-table-invoices-element" }
            ) do |table|
              table.caption("Invoice history")
              table.thead do
                table.tr do
                  table.th("Invoice")
                  table.th("Issued")
                  table.th("Status")
                  table.th("Amount", align: :right)
                  table.th("Action", align: :right)
                end
              end
              table.tbody do
                Gallery::Data.invoices.each do |invoice|
                  table.tr do
                    table.th(invoice.number, scope: :row)
                    table.td(invoice.issued_on.iso8601)
                    table.td do
                      render NitroKit::Badge.new(
                        invoice.status.to_s.humanize,
                        id: "gallery-table-invoice-#{invoice.id}-status",
                        color: invoice_status_color(invoice.status),
                        size: :sm
                      )
                    end
                    table.td(format_amount(invoice), align: :right)
                    table.td(align: :right) do
                      render NitroKit::Button.new(
                        "View",
                        id: "gallery-table-invoice-#{invoice.id}-view",
                        href: "#invoice-#{invoice.id}",
                        size: :sm
                      )
                    end
                  end
                end
              end
            end
          end
        end

        example_section(
          "Alignment",
          slug: "table-alignment",
          description: "Headers and cells declare left, center, and right alignment independently."
        ) do
          example("All alignments", slug: "table-all-alignments", mode: :full_width) do
            render NitroKit::Table.new(
              id: "gallery-table-alignment",
              table_html: { id: "gallery-table-alignment-element" }
            ) do |table|
              table.caption("Deployment timing")
              table.thead do
                table.tr do
                  table.th("Environment", align: :left)
                  table.th("State", align: :center)
                  table.th("Duration", align: :right)
                end
              end
              table.tbody do
                table.tr do
                  table.th("Production", scope: :row, align: :left)
                  table.td("Operational", align: :center)
                  table.td("2m 14s", align: :right)
                end
                table.tr do
                  table.th("Staging", scope: :row, align: :left)
                  table.td("Queued", align: :center)
                  table.td("—", align: :right)
                end
              end
            end
          end
        end

        example_section(
          "Content pressure",
          slug: "table-pressure",
          description: "Long identifiers, multiline descriptions, dense records, status, and grouped actions stay semantic."
        ) do
          example("API credential inventory", slug: "table-api-credentials", mode: :full_width) do
            render NitroKit::Table.new(
              id: "gallery-table-credentials",
              table_html: { id: "gallery-table-credentials-element" }
            ) do |table|
              table.caption("API credential inventory")
              table.thead do
                table.tr do
                  table.th("Credential and identifier")
                  table.th("Access", align: :center)
                  table.th("Last used")
                  table.th("Actions", align: :right)
                end
              end
              table.tbody do
                Gallery::Data.api_keys.each do |api_key|
                  table.tr do
                    table.th(scope: :row) do
                      strong { api_key.name }
                      div { "#{api_key.prefix}••••••••••••••••" }
                    end
                    table.td(align: :center) do
                      render NitroKit::Badge.new(
                        api_key.access.to_s.humanize,
                        id: "gallery-table-credential-#{api_key.id}-access",
                        variant: :outline,
                        color: :info,
                        size: :sm
                      )
                    end
                    table.td(api_key.last_used_at&.iso8601 || "Never used")
                    table.td(align: :right) do
                      render NitroKit::ButtonGroup.new(
                        id: "gallery-table-credential-#{api_key.id}-actions",
                        label: "Actions for #{api_key.name} credential"
                      ) do |group|
                        group.button(
                          "Rotate",
                          id: "gallery-table-credential-#{api_key.id}-rotate",
                          size: :sm,
                        )
                        group.button(
                          "Revoke",
                          id: "gallery-table-credential-#{api_key.id}-revoke",
                          size: :sm,
                          variant: :destructive
                        )
                      end
                    end
                  end
                end
              end
            end
          end

          example("Integration descriptions", slug: "table-integration-descriptions", mode: :full_width) do
            render NitroKit::Table.new(
              id: "gallery-table-integrations",
              table_html: { id: "gallery-table-integrations-element" }
            ) do |table|
              table.caption("Integration delivery and connection status")
              table.thead do
                table.tr do
                  table.th("Integration")
                  table.th("Purpose and delivery behavior")
                  table.th("Status", align: :right)
                end
              end
              table.tbody do
                Gallery::Data.integrations.each do |integration|
                  table.tr do
                    table.th(integration.name, scope: :row)
                    table.td(integration.description)
                    table.td(align: :right) do
                      render NitroKit::Badge.new(
                        integration.status.to_s.humanize,
                        id: "gallery-table-integration-#{integration.id}-status",
                        color: integration_status_color(integration.status),
                        size: :sm
                      )
                    end
                  end
                end
              end
            end
          end
        end

        example_section(
          "Empty state",
          slug: "table-empty",
          description: "An empty collection remains a valid table with a caption, headers, and one spanning message."
        ) do
          example("No API keys", slug: "table-no-api-keys", mode: :full_width) do
            render NitroKit::Table.new(
              id: "gallery-table-empty",
              table_html: { id: "gallery-table-empty-element" }
            ) do |table|
              table.caption("API credentials")
              table.thead do
                table.tr do
                  table.th("Name")
                  table.th("Access")
                  table.th("Last used", align: :right)
                end
              end
              table.tbody do
                table.tr do
                  table.td(
                    "No API credentials have been created.",
                    html: { colspan: 3 }
                  )
                end
              end
            end
          end
        end
      end

      def invoice_status_color(status)
        { paid: :success, refunded: :warning }.fetch(status)
      end

      def integration_status_color(status)
        { connected: :success, action_required: :warning, available: :neutral }.fetch(status)
      end

      def format_amount(invoice)
        amount = invoice.amount_cents.fdiv(100)
        "#{invoice.currency} #{Kernel.format("%.2f", amount)}"
      end
    end
  end
end
