module Gallery
  module Compositions
    class ApiWebhooksPage < ScenarioPage
      include Phlex::Rails::Helpers::FormWith

      private

      def render_scenario
        workspace_surface do
          render_header

          case state
          when "list" then render_list(webhook_rows.first(3))
          when "empty" then render_empty
          when "detail" then render_detail
          when "create", "validation", "loading" then render_form
          when "delivery-succeeded" then render_delivery(:success)
          when "delivery-failed" then render_delivery(:failed)
          when "retrying" then render_delivery(:retrying)
          when "disabled" then render_disabled
          when "signing-secret" then render_signing_secret
          when "dense" then render_list(webhook_rows)
          when "long" then render_long
          when "mobile" then render_mobile
          end
        end
      end

      def render_header
        render NitroKit::PageHeader.new(
          title: webhook_title,
          description: webhook_description,
          id: "gallery-api-webhooks-header"
        ) do |header|
          header.actions NitroKit::ButtonGroup.new(label: "Webhook actions", id: "gallery-api-webhooks-actions") do |actions|
            actions.button("API docs", href: "#webhook-docs")
            actions.button("Create endpoint", href: entry_path(entry, state: "create"), variant: :primary, disabled: state == "loading")
          end
        end
      end

      def render_list(rows)
        render NitroKit::DataSection.new(
          title: "Configured endpoints",
          description: "Applications own endpoint authorization, event policy, secret storage, retry queues, and delivery persistence.",
          id: "gallery-api-webhooks-list-section"
        ) do |section|
          section.actions NitroKit::ButtonGroup.new(label: "Endpoint list actions") do |actions|
            actions.button("Export endpoints", href: "#export")
          end
          section.table NitroKit::Table.new(id: "gallery-api-webhooks-table", table_aria: { label: "Webhook endpoints" }) do |table|
            table.caption("#{rows.length} configured webhook endpoints")
            table.thead do
              table.tr do
                table.th("Endpoint")
                table.th("Events")
                table.th("Last delivery")
                table.th("Status")
                table.th("Actions", align: :right)
              end
            end
            table.tbody do
              rows.each do |row|
                table.tr do
                  table.th(scope: :row) do
                    render NitroKit::Flex.new(dir: :col, gap: 1, align: :start) do
                      strong { row.fetch(:name) }
                      small { row.fetch(:url) }
                    end
                  end
                  table.td(row.fetch(:events))
                  table.td(row.fetch(:last_delivery))
                  table.td do
                    render NitroKit::Badge.new(
                      row.fetch(:status).to_s.humanize,
                      color: webhook_status_color(row.fetch(:status)),
                      size: :sm,
                      id: "gallery-api-webhook-#{row.fetch(:key)}-status"
                    )
                  end
                  table.td(align: :right) do
                    render NitroKit::ButtonGroup.new(label: "Actions for #{row.fetch(:name)}") do |actions|
                      actions.button("View", href: entry_path(entry, state: "detail"), size: :sm)
                      actions.button("Deliveries", href: entry_path(entry, state: row.fetch(:status) == :failing ? "delivery-failed" : "delivery-succeeded"), size: :sm)
                    end
                  end
                end
              end
            end
          end
        end
      end

      def render_empty
        render NitroKit::DataSection.new(
          title: "Webhook endpoints",
          description: "No application has configured an outbound delivery destination.",
          id: "gallery-api-webhooks-empty-section"
        ) do |section|
          section.empty_state NitroKit::EmptyState.new(
            title: "No webhook endpoints",
            description: "Create an endpoint when an application is ready to verify signatures and process deliveries.",
            level: 3,
            id: "gallery-api-webhooks-empty"
          ) do |empty|
            empty.icon NitroKit::Icon.new(:webhook)
            empty.action NitroKit::Button.new("Create first endpoint", href: entry_path(entry, state: "create"), variant: :primary, id: "gallery-api-webhooks-empty-action")
            empty.action NitroKit::Button.new("Read delivery guide", href: "#webhook-guide")
          end
        end
      end

      def render_detail
        render NitroKit::StatGrid.new(id: "gallery-api-webhooks-detail-grid") do |stats|
          stats.stat(key: :endpoint, label: "Endpoint", value: "Production events", detail: "https://api.example.test/hooks/nitro")
          stats.stat(key: :events, label: "Subscribed events", value: "4 events", detail: "deployment.created · incident.updated · member.invited · invoice.paid")
          stats.stat(key: :policy, label: "Delivery policy", value: "Enabled", detail: "10 second timeout · exponential retry managed by the application")
        end
        render_delivery_history(:success)
      end

      def render_form
        invalid = state == "validation"
        disabled = state == "loading"

        render NitroKit::SettingsSection.new(
          title: "Endpoint configuration",
          description: "URL validation, allowed event policy, ownership, signing secrets, and persistence remain application code.",
          id: "gallery-api-webhooks-settings-section"
        ) do |section|
          if invalid
            section.status NitroKit::Alert.new(variant: :error, id: "gallery-api-webhooks-form-error") do |alert|
              alert.title("Endpoint was not created")
              alert.description("Use an HTTPS URL, choose at least one allowed event, and provide a recognizable endpoint name.")
            end
          elsif disabled
            section.status NitroKit::Alert.new(id: "gallery-api-webhooks-form-loading") do |alert|
              alert.title("Creating endpoint")
              alert.description("The URL is being verified and the signing secret is being generated.")
            end
          end
          section.form do
            form_with(url: "#webhook", scope: :webhook, builder: NitroKit::FormBuilder, id: "gallery-api-webhooks-form") do |form|
              form.group do
                form.field(
                  :name,
                  label: "Endpoint name",
                  value: invalid ? "" : "Production events",
                  errors: invalid ? [ "cannot be blank" ] : nil,
                  required: true,
                  disabled:
                )
                form.field(
                  :url,
                  as: :url,
                  label: "HTTPS endpoint URL",
                  value: invalid ? "http://localhost" : "https://api.example.test/hooks/nitro",
                  errors: invalid ? [ "must use HTTPS" ] : nil,
                  autocomplete: "url",
                  required: true,
                  disabled:
                )
                render NitroKit::CheckboxGroup.new(
                  legend: "Delivered events",
                  name: "webhook[events]",
                  id: "gallery-api-webhooks-events",
                  options: [ [ "Deployment created", "deployment.created" ], [ "Incident updated", "incident.updated" ], [ "Member invited", "member.invited" ], [ "Invoice paid", "invoice.paid" ] ],
                  value: invalid ? [] : [ "deployment.created", "incident.updated" ],
                  description: invalid ? "Choose at least one delivered event." : "Choose only events this endpoint is prepared to process.",
                  disabled:,
                  aria: { invalid: invalid ? "true" : nil }
                )
                form.submit(
                  disabled ? "Creating endpoint…" : "Create endpoint",
                  id: "gallery-api-webhooks-submit",
                  disabled:,
                  data: { turbo_submits_with: "Creating endpoint…" }
                )
              end
            end
          end
        end
      end

      def render_delivery(kind)
        variant = { success: :success, failed: :error, retrying: :warning }.fetch(kind)
        title = { success: "Delivery accepted", failed: "Delivery failed", retrying: "Delivery retry scheduled" }.fetch(kind)
        description = {
          success: "The endpoint returned HTTP 202 in 184 ms.",
          failed: "The endpoint returned HTTP 500. No application event was changed.",
          retrying: "Attempt 3 of 8 will run July 13, 2026 at 10:52 UTC."
        }.fetch(kind)

        render NitroKit::Alert.new(variant:, id: "gallery-api-webhooks-delivery-alert") do |alert|
          alert.icon NitroKit::Icon.new(kind == :success ? :circle_check : :triangle_alert)
          alert.title(title)
          alert.description(description)
        end
        render_delivery_history(kind)
      end

      def render_delivery_history(kind)
        render NitroKit::DataSection.new(
          title: "Delivery attempts",
          description: "Payload storage, redaction, response bodies, timeout policy, and retries remain application-owned.",
          id: "gallery-api-webhooks-deliveries-section"
        ) do |section|
          section.actions NitroKit::ButtonGroup.new(label: "Delivery actions") do |actions|
            actions.button("Inspect payload", href: "#payload")
            actions.button("Retry now", href: entry_path(entry, state: "retrying"), variant: :primary, disabled: kind == :success)
          end
          section.table NitroKit::Table.new(id: "gallery-api-webhooks-deliveries-table") do |table|
            table.caption("Attempts for delivery del_84K2")
            table.thead do
              table.tr do
                table.th("Attempt")
                table.th("Time")
                table.th("Response")
                table.th("Duration", align: :right)
              end
            end
            table.tbody do
              delivery_attempts(kind).each do |attempt|
                table.tr do
                  table.th(attempt.fetch(:number), scope: :row)
                  table.td(attempt.fetch(:time))
                  table.td(attempt.fetch(:response))
                  table.td(attempt.fetch(:duration), align: :right)
                end
              end
            end
          end
        end
      end

      def delivery_attempts(kind)
        return [ { number: "1", time: "10:41:22 UTC", response: "HTTP 202 Accepted", duration: "184 ms" } ] if kind == :success

        [
          { number: "1", time: "10:41:22 UTC", response: "HTTP 500 Internal Server Error", duration: "10.0 s" },
          { number: "2", time: "10:43:22 UTC", response: "Connection timed out", duration: "10.0 s" },
          { number: "3", time: kind == :retrying ? "Scheduled 10:52 UTC" : "10:47:22 UTC", response: kind == :retrying ? "Pending" : "HTTP 503 Service Unavailable", duration: "—" }
        ]
      end

      def render_disabled
        render NitroKit::Alert.new(variant: :warning, id: "gallery-api-webhooks-disabled-alert") do |alert|
          alert.icon NitroKit::Icon.new(:webhook)
          alert.title("Production events is disabled")
          alert.description("No new deliveries will be queued. Existing delivery records and signing-secret rotation history remain available.")
        end
        render NitroKit::ButtonGroup.new(label: "Endpoint availability") do |actions|
          actions.button("Review delivery history", href: entry_path(entry, state: "detail"))
          actions.button("Enable endpoint", href: "#enable", variant: :primary, id: "gallery-api-webhooks-enable")
        end
      end

      def render_signing_secret
        render NitroKit::Alert.new(variant: :warning, id: "gallery-api-webhooks-secret-warning") do |alert|
          alert.icon NitroKit::Icon.new(:key_round)
          alert.title("Copy this secret now")
          alert.description("The application displays the full value once and owns encrypted storage and rotation overlap.")
        end
        render NitroKit::Flex.new(dir: :col, gap: 2, align: :stretch, id: "gallery-api-webhooks-secret-card") do
          render NitroKit::Label.new("New signing secret", for: "gallery-api-webhooks-secret")
          render NitroKit::ControlGroup.new(label: "New signing secret") do
            render NitroKit::Input.new(
              id: "gallery-api-webhooks-secret",
              name: "webhook[secret]",
              value: "whsec_7P3F9J2M4Q8R",
              readonly: true,
              autocomplete: "off",
              aria: { label: "New signing secret" }
            )
            render NitroKit::Button.new(
              "Copy",
              id: "gallery-api-webhooks-copy-secret",
              icon: :copy,
              data: { secret: "whsec_7P3F9J2M4Q8R" }
            )
          end
        end
      end

      def render_long
        row = webhook_rows.last
        render NitroKit::Card.new(id: "gallery-api-webhooks-long-card") do |card|
          card.title(row.fetch(:name))
          card.body do
            render NitroKit::Flex.new(dir: :col, gap: 4, align: :stretch) do
              p { row.fetch(:url) }
              p { "Subscribed to customer-visible incident coordination, international invoice settlement, production deployment approval, and regulatory audit export completion events." }
            end
          end
          card.footer do
            render NitroKit::Button.new("View endpoint history", href: entry_path(entry, state: "detail"), variant: :primary)
          end
        end
      end

      def render_mobile
        render NitroKit::Card.new(id: "gallery-api-webhooks-mobile-card") do |card|
          card.title("Production events")
          card.body do
            render NitroKit::Flex.new(dir: :col, gap: 4, align: :stretch) do
              render NitroKit::Flex.new(dir: :row, gap: 2, align: :center) do
                render NitroKit::Badge.new("Failing", color: :danger)
              end
              p { "https://api.example.test/hooks/nitro" }
              p { "Last response: HTTP 500 · attempt 3 scheduled" }
            end
          end
          card.footer do
            render NitroKit::Button.new("Review failed delivery", href: entry_path(entry, state: "delivery-failed"), variant: :primary, id: "gallery-api-webhooks-mobile-action")
          end
        end
      end

      def webhook_rows
        @webhook_rows ||= [
          { key: "production", name: "Production events", url: "https://api.example.test/hooks/nitro", events: "4 events", last_delivery: "2 minutes ago", status: :failing },
          { key: "billing", name: "Billing ledger", url: "https://ledger.example.test/webhooks/billing", events: "2 events", last_delivery: "18 minutes ago", status: :healthy },
          { key: "audit", name: "Audit archive", url: "https://archive.example.test/events", events: "6 events", last_delivery: "1 hour ago", status: :disabled },
          { key: "deployments", name: "Deployment coordination", url: "https://deploy.example.test/nitro/events", events: "3 events", last_delivery: "2 hours ago", status: :healthy },
          { key: "incidents", name: "Incident escalation", url: "https://incidents.example.test/hooks", events: "5 events", last_delivery: "3 hours ago", status: :healthy },
          { key: "members", name: "Identity synchronization", url: "https://identity.example.test/workspace/events", events: "4 events", last_delivery: "5 hours ago", status: :failing },
          { key: "invoices", name: "International invoice settlement", url: "https://finance.example.test/international-reconciliation/webhook-delivery", events: "7 events", last_delivery: "Yesterday", status: :healthy },
          { key: "research", name: "Research environment lifecycle", url: "https://research.example.test/environment-lifecycle", events: "8 events", last_delivery: "Yesterday", status: :disabled },
          { key: "compliance", name: "Regulatory archive completion", url: "https://compliance.example.test/regulated-audit-events", events: "9 events", last_delivery: "2 days ago", status: :healthy },
          { key: "reliability", name: "Reliability engineering incident coordination", url: "https://reliability.example.test/customer-visible-incident-coordination/production", events: "12 events", last_delivery: "3 days ago", status: :failing }
        ]
      end

      def webhook_status_color(status)
        { healthy: :success, failing: :danger, disabled: :neutral }.fetch(status)
      end

      def webhook_title
        {
          "list" => "Webhook endpoints",
          "empty" => "Create a webhook endpoint",
          "detail" => "Production events",
          "create" => "Create endpoint",
          "validation" => "Correct endpoint configuration",
          "loading" => "Creating endpoint",
          "delivery-succeeded" => "Successful delivery",
          "delivery-failed" => "Failed delivery",
          "retrying" => "Retry scheduled",
          "disabled" => "Endpoint disabled",
          "signing-secret" => "Signing secret",
          "dense" => "Webhook inventory",
          "long" => "Long endpoint detail",
          "mobile" => "Webhook operations"
        }.fetch(state)
      end

      def webhook_description
        {
          "list" => "Inventory endpoints, subscriptions, health, recency, and labelled operations.",
          "empty" => "Explain signing and delivery prerequisites before endpoint creation.",
          "detail" => "Separate endpoint configuration from application-owned delivery history.",
          "create" => "Collect endpoint name, HTTPS URL, and allowed events.",
          "validation" => "Connect invalid URL and event policy to their native controls.",
          "loading" => "Keep configuration visible while verification and secret generation run.",
          "delivery-succeeded" => "Expose response code, timing, payload inspection, and immutable attempt history.",
          "delivery-failed" => "Failure preserves the source event and offers an explicit retry.",
          "retrying" => "Retry number and schedule remain visible without client-owned queue policy.",
          "disabled" => "Disabled delivery and retained records are distinct.",
          "signing-secret" => "One-time secret display remains an application security boundary.",
          "dense" => "Ten deterministic endpoints pressure row operations and long URLs.",
          "long" => "Long names, URLs, subscriptions, and operational copy remain readable.",
          "mobile" => "Status, URL, latest response, and recovery action survive narrow width."
        }.fetch(state)
      end

      def section_title = "Webhook endpoints and delivery lifecycle"
      def section_description = "Endpoint inventory, creation, details, signing secrets, successful and failed attempts, retries, disabled state, and pressure cases."
    end
  end
end
