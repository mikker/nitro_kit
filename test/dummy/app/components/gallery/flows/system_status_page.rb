module Gallery
  module Flows
    class SystemStatusPage < ScenarioPage
      private

      def render_scenario
        workspace_surface(size: :lg) do
          render_header
          render_status
          render_service_metrics if state == "degraded"
          render_context
        end
      end

      def render_header
        render NitroKit::PageHeader.new(
          title: status.title,
          description: state_description,
          id: "gallery-system-status-header"
        ) do |header|
          header.actions(
            NitroKit::ButtonGroup.new(id: "gallery-system-status-actions", label: "System recovery actions")
          ) do |actions|
            actions.button(status.primary_action, href: status.primary_href, variant: :primary)
            if status.secondary_action
              actions.button(status.secondary_action, href: status.secondary_href, variant: :ghost)
            end
          end
        end
      end

      def render_status
        render NitroKit::Alert.new(
          variant: status.variant,
          id: "gallery-system-status-alert",
          data: { gallery_status_code: status.code }
        ) do |alert|
          alert.icon(NitroKit::Icon.new(status.icon, id: "gallery-system-status-icon"))
          alert.title(status.code)
          alert.description(status.description)
        end
      end

      def render_service_metrics
        render NitroKit::StatGrid.new(id: "gallery-system-status-metrics") do |stats|
          stats.stat(key: :workspace, label: "Workspace API", value: "99.98%", detail: "Operational")
          stats.stat(key: :webhooks, label: "Webhook delivery", value: "92.14%", detail: "Recovering")
          stats.stat(key: :exports, label: "Data exports", value: "4m 18s", detail: "Delayed")
        end
      end

      def render_context
        render NitroKit::DataSection.new(
          title: "Request context",
          description: "HTTP responses, incident references, retry policy, and support routes remain application-owned.",
          id: "gallery-system-status-context"
        ) do |section|
          section.actions(NitroKit::ButtonGroup.new(label: "Request context actions")) do |actions|
            actions.button("Copy reference", type: :button, data: { reference: status.reference })
          end
          section.table(NitroKit::Table.new(id: "gallery-system-status-table")) do |table|
            table.caption("Caller-owned system response context")
            table.thead do
              table.tr do
                table.th("Detail")
                table.th("Value")
              end
            end
            table.tbody do
              context_rows.each do |label, value|
                table.tr do
                  table.th(label, scope: :row)
                  table.td(value)
                end
              end
            end
          end
        end
      end

      def context_rows
        rows = [
          [ "Status", status.code ],
          [ "Reference", status.reference ],
          [ "Recorded", "July 13, 2026 at 11:08 UTC" ]
        ]
        rows << [ "Retry", status.retry_after ] if status.retry_after
        rows
      end

      def status
        @status ||= Gallery::PublicData.system_status(state)
      end

      def flow_label = "System response flow"
      def section_title = "Errors, availability, and recovery"
      def section_description = "HTTP failures, maintenance, connectivity, rate limits, degradation, and pressure states."

      def state_description
        {
          "403" => "An authenticated user sees the policy decision and a safe route away from forbidden content.",
          "404" => "A missing route explains uncertainty without claiming the underlying resource was deleted.",
          "422" => "A conflicting application state remains distinct from field-level validation or a server failure.",
          "500" => "An unexpected failure exposes a support reference and explicitly avoids claiming a successful mutation.",
          "maintenance" => "Scheduled downtime identifies protected data, expected recovery, and an update route.",
          "offline" => "Browser connectivity failure preserves local values and offers an explicit retry.",
          "rate-limited" => "Caller-owned retry timing and API documentation accompany a 429 response.",
          "degraded" => "Partial service availability keeps healthy operations distinct from recovering dependencies.",
          "long" => "Long organization, action, and reference copy wraps without custom styling or truncation.",
          "mobile" => "The same recovery anatomy remains concise on the narrow flow surface."
        }.fetch(state)
      end
    end
  end
end
