module Gallery
  module Compositions
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
              actions.button(status.secondary_action, href: status.secondary_href)
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
          description: "Keep this reference when contacting support or checking incident updates.",
          id: "gallery-system-status-context"
        ) do |section|
          section.table NitroKit::DetailsTable.new(
            status,
            caption: "System response details",
            id: "gallery-system-status-table"
          ) do |details|
            details.field(:code, label: "Status")
            details.field(:reference)
            details.field(:recorded, value: "July 13, 2026 at 11:08 UTC")
            details.field(:retry, value: status.retry_after) if status.retry_after
          end
        end
      end

      def status
        @status ||= Gallery::PublicData.system_status(state)
      end

      def section_title = "Errors, availability, and recovery"
      def section_description = "HTTP failures, maintenance, connectivity, rate limits, degradation, and pressure states."

      def state_description
        {
          "403" => "Your account is signed in, but it does not have permission to open this page.",
          "404" => "The address may be outdated, or the page may have moved.",
          "422" => "The requested change conflicts with the workspace’s current state.",
          "500" => "The failure was recorded and no submitted data was intentionally changed.",
          "maintenance" => "Workspace writes are paused during a scheduled database upgrade.",
          "offline" => "Reconnect to the internet, then retry without losing the values on this page.",
          "rate-limited" => "This client has reached its temporary request limit. Try again in 42 seconds.",
          "degraded" => "Core workspace access is available while webhook delivery and exports recover.",
          "long" => "The complete organization workspace could not be loaded, but the request was preserved.",
          "mobile" => "The page could not be found. Check the address or return home."
        }.fetch(state)
      end
    end
  end
end
