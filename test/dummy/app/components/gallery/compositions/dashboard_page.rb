module Gallery
  module Compositions
    class DashboardPage < Page
      private

      def page_template
        header(data: { gallery: "composition-header" }) do
          p(data: { gallery: "eyebrow" }) { "Workspace" }
          h1 { entry.title }
          p { entry.description }
          state_navigation
        end

        render Section.new(
          slug: "dashboard-screen",
          title: "Workspace dashboard",
          description: "Component-composed workspace overview with chart pressure across empty, healthy, degraded, loading, dense, and mobile states."
        ) do
          render_example(
            slug: "dashboard-#{state}",
            title: state.to_s.humanize,
            description: state_description,
            mode: :full_width
          ) do
            main(
              id: "gallery-dashboard-surface",
              aria: { busy: state == "loading" ? "true" : nil },
              data: {
                gallery: "composition-surface",
                gallery_composition: "dashboard",
                gallery_composition_state: state,
                gallery_mobile: state == "mobile" ? "true" : nil
              }.compact
            ) do
              render NitroKit::Container.new(size: :xl, id: "gallery-dashboard-container") do
                render NitroKit::Flex.new(dir: :col, gap: 6, align: :stretch,
                id: "gallery-dashboard-stack") do
                  render_workspace_header(disabled: state == "loading")
                  render_state
                end
              end
            end
          end
        end
      end

      def render_state
        case state
        when "new" then render_new
        when "active" then render_active
        when "degraded" then render_degraded
        when "loading" then render_loading
        when "dense" then render_dense
        when "mobile" then render_mobile
        end
      end

      def render_workspace_header(disabled:)
        render NitroKit::PageHeader.new(
          title: Gallery::Data.auth_identity.workspace,
          eyebrow: "Team workspace",
          description: "Team plan · EU region · updated July 13, 2026 at 09:30 UTC",
          id: "gallery-dashboard-workspace-header"
        ) do |header|
          header.actions NitroKit::ButtonGroup.new(
            id: "gallery-dashboard-workspace-actions",
            label: "Workspace actions"
          ) do |group|
            group.button(
              "New project",
              id: "gallery-dashboard-new-project",
              href: disabled ? nil : "#new-project",
              variant: :primary,
              disabled:
            )
            group.button(
              "Invite members",
              id: "gallery-dashboard-invite-members",
              href: disabled ? nil : "#invite-members",
              disabled:
            )
          end
        end

        render NitroKit::Flex.new(dir: :row, align: :center, gap: 2, wrap: :wrap, id: "gallery-dashboard-workspace-context") do
          render NitroKit::Badge.new(
            workspace_status_label,
            id: "gallery-dashboard-workspace-status",
            color: workspace_status_color,
            size: :sm
          )
          render NitroKit::AvatarStack.new(
            id: "gallery-dashboard-members",
            label: "Active workspace members"
          ) do |stack|
            Gallery::Data.members.first(2).each do |member|
              stack.avatar(
                alt: member.name,
                fallback: member.name.split.map { |part| part.first }.join,
                id: "gallery-dashboard-member-#{member.id}"
              )
            end
            stack.overflow(10, label: "Ten more workspace members")
          end
        end
      end

      def render_new
        render NitroKit::Alert.new(id: "gallery-dashboard-new-success", variant: :success) do |alert|
          alert.title("Workspace created")
          alert.description("Your workspace is ready. Create a project or invite teammates to begin.")
        end

        render NitroKit::EmptyState.new(
          title: "No activity yet",
          description: "Deployments, invitations, credential changes, and billing events will appear here.",
          id: "gallery-dashboard-empty-card"
        ) do |empty|
          empty.icon NitroKit::Icon.new(:activity, id: "gallery-dashboard-empty-icon")
          empty.action NitroKit::Button.new(
            "Create the first project",
            id: "gallery-dashboard-empty-action",
            href: "#new-project",
            variant: :primary
          )
        end
      end

      def render_active
        render NitroKit::Alert.new(id: "gallery-dashboard-operational", variant: :success) do |alert|
          alert.title("All systems operational")
          alert.description("Production, background jobs, and webhook delivery are healthy.")
        end
        render_metrics
        render_request_chart(:normal)
        render_activity_section(id: "gallery-dashboard-activity", activities: Gallery::Data.activities)
      end

      def render_degraded
        render NitroKit::Alert.new(id: "gallery-dashboard-degraded-alert", variant: :error) do |alert|
          alert.title("Webhook delivery is degraded")
          alert.description("Eight Slack deliveries have failed since 09:12 UTC. Deployments are not affected.")
        end
        render_metrics
        render_request_chart(:error)
        render NitroKit::Card.new(id: "gallery-dashboard-incident-card") do |card|
          card.title("Active incident", level: 4)
          card.body do
            render NitroKit::Flex.new(dir: :col, gap: 4, align: :stretch) do
              render NitroKit::Badge.new(
                "Investigating",
                id: "gallery-dashboard-incident-status",
                color: :danger,
                size: :sm
              )
              p { "Slack notification delivery · started July 13, 2026 at 09:12 UTC" }
            end
          end
          card.footer do
            render NitroKit::Button.new(
              "Retry failed deliveries",
              id: "gallery-dashboard-retry-deliveries",
              variant: :primary
            )
          end
        end
        render_integration_section
      end

      def render_loading
        render NitroKit::Alert.new(id: "gallery-dashboard-loading-alert") do |alert|
          alert.title("Refreshing workspace data")
          alert.description("Request volume, recent activity, and service health are loading.")
        end
        render_request_chart(:loading)
        3.times do |index|
          render NitroKit::Card.new(id: "gallery-dashboard-loading-card-#{index + 1}") do |card|
            card.title("Loading summary #{index + 1}", level: 4)
            card.body { "Current value unavailable" }
          end
        end
        render NitroKit::Button.new(
          "Refreshing…",
          id: "gallery-dashboard-loading-action",
          disabled: true,
          variant: :primary
        )
      end

      def render_dense
        render NitroKit::Alert.new(id: "gallery-dashboard-dense-alert", variant: :success) do |alert|
          alert.title("Reporting window complete")
          alert.description("The dashboard includes every deterministic member, activity, integration, and invoice record.")
        end
        render_metrics
        render_request_chart(:dense)
        render_member_section
        render_activity_section(id: "gallery-dashboard-dense-activity", activities: Gallery::Data.activities)
        render_invoice_section
      end

      def render_mobile
        render NitroKit::Alert.new(id: "gallery-dashboard-mobile-alert", variant: :warning) do |alert|
          alert.title("One integration needs attention")
          alert.description(
            "Analytical Engines — Research and Production has a deliberately long workspace name and long activity " \
              "content to pressure a narrow mobile-width dashboard."
          )
        end
        render_request_chart(:mobile)
        render NitroKit::Card.new(id: "gallery-dashboard-mobile-card") do |card|
          card.title("Recent production activity and workspace access changes", level: 4)
          card.body do
            ul do
              Gallery::Data.activities.each do |activity|
                li { "#{activity.actor.name} #{activity.action} #{activity.subject} at #{activity.occurred_at.iso8601}" }
              end
            end
          end
          card.footer do
            render NitroKit::Button.new(
              "Open complete activity history",
              id: "gallery-dashboard-mobile-action",
              href: "#activity"
            )
          end
        end
      end

      def render_metrics
        render NitroKit::StatGrid.new(id: "gallery-dashboard-metrics") do |stats|
          stats.stat(key: :members, label: "Active members", value: "12", detail: "Two invitations pending")
          stats.stat(key: :deployments, label: "Deployments this week", value: "18", detail: "Four to production")
          stats.stat(key: :usage, label: "API requests", value: "1,284,320", detail: "62% of monthly allowance")
        end
      end

      def render_request_chart(mode)
        render NitroKit::Card.new(id: "gallery-dashboard-request-chart-card") do |card|
          card.title("API request volume", level: 4)
          card.body { render_request_chart_figure(mode) }

          if mode == :error
            card.footer do
              render NitroKit::Button.new(
                "Retry request chart",
                id: "gallery-dashboard-request-chart-retry",
                href: "#request-volume",
                variant: :primary
              )
            end
          end
        end
      end

      def render_request_chart_figure(mode)
        figure(
          id: "gallery-dashboard-request-chart",
          aria: {
            busy: mode == :loading ? "true" : nil,
            labelledby: "gallery-dashboard-request-chart-caption"
          }.compact,
          data: { gallery: "chart-placeholder", gallery_chart_state: mode }
        ) do
          figcaption(id: "gallery-dashboard-request-chart-caption") { request_chart_caption(mode) }

          case mode
          when :loading
            render NitroKit::Alert.new(id: "gallery-dashboard-request-chart-loading") do |alert|
              alert.title("Loading hourly request volume")
              alert.description("The chart frame remains available while 24 hourly request totals are fetched.")
            end
          when :error
            render NitroKit::Alert.new(id: "gallery-dashboard-request-chart-error", variant: :error) do |alert|
              alert.title("Request volume is unavailable")
              alert.description("No usage data was changed. Retry the chart without reloading the incident records.")
            end
          else
            render_request_chart_plot(mode)
            dl(data: { gallery: "chart-summary" }) do
              dt { "Current hour" }
              dd { mode == :dense ? "84,212 requests" : "61,483 requests" }
              dt { "Peak hour" }
              dd { mode == :mobile ? "96,420 requests at 08:00 UTC across production environments" : "96,420 requests at 08:00 UTC" }
              dt { "Monthly allowance" }
              dd { "62% used" }
            end
          end
        end
      end

      def render_request_chart_plot(mode)
        title_id = "gallery-dashboard-request-chart-plot-title"
        description_id = "gallery-dashboard-request-chart-plot-description"

        svg(
          id: "gallery-dashboard-request-chart-plot",
          viewBox: "0 0 640 360",
          preserveAspectRatio: "xMidYMid meet",
          fill: "none",
          stroke: "currentColor",
          stroke_width: 8,
          stroke_linecap: "round",
          stroke_linejoin: "round",
          focusable: false,
          role: "img",
          aria: { labelledby: "#{title_id} #{description_id}" }
        ) do |svg|
          svg.title(id: title_id) { "Hourly API request volume" }
          svg.desc(id: description_id) { request_chart_description(mode) }
          svg.polyline(points: request_chart_points(mode), vector_effect: "non-scaling-stroke")
        end
      end

      def request_chart_caption(mode)
        {
          normal: "Hourly API requests for July 13, 2026",
          loading: "Hourly API requests are loading",
          error: "Hourly API requests could not be loaded",
          dense: "Hourly API requests across every production and research environment",
          mobile: "Hourly API request volume for Analytical Engines — Research and Production on a narrow screen"
        }.fetch(mode)
      end

      def request_chart_description(mode)
        return "Twenty-four hourly totals rise from 18,420 to a peak of 96,420 before ending at 84,212." if mode == :dense
        return "The same 24-hour series remains readable in a narrow viewport and ends at 61,483 requests." if mode == :mobile

        "Hourly totals rise from 18,420 to a peak of 96,420 before ending at 61,483 requests."
      end

      def request_chart_points(mode)
        return "20,300 48,280 76,250 104,270 132,210 160,225 188,170 216,190 244,130 272,145 300,75 328,105 356,55 384,90 412,45 440,80 468,110 496,95 524,150 552,135 580,175 620,155" if mode == :dense

        "20,300 70,270 120,285 170,230 220,250 270,180 320,205 370,115 420,145 470,70 520,120 570,95 620,165"
      end

      def render_activity_section(id:, activities:)
        render NitroKit::DataSection.new(
          title: "Recent workspace activity",
          description: "Deployments, invitations, access changes, and billing events.",
          id: "#{id}-section"
        ) do |section|
          section.table NitroKit::Table.new(id:, table_html: { id: "#{id}-element" }) do |table|
            table.caption("Recent workspace activity")
            table.thead do
              table.tr do
                table.th("Actor")
                table.th("Activity")
                table.th("Time", align: :right)
              end
            end
            table.tbody do
              activities.each do |activity|
                table.tr do
                  table.th(activity.actor.name, scope: :row)
                  table.td("#{activity.action.to_s.humanize} #{activity.subject}")
                  table.td(activity.occurred_at.iso8601, align: :right)
                end
              end
            end
          end
        end
      end

      def render_member_section
        render NitroKit::DataSection.new(title: "Workspace members", id: "gallery-dashboard-dense-members-section") do |section|
          section.table NitroKit::Table.new(
            id: "gallery-dashboard-dense-members",
            table_html: { id: "gallery-dashboard-dense-members-element" }
          ) do |table|
            table.caption("Workspace members")
            table.thead do
              table.tr do
                table.th("Member")
                table.th("Role")
                table.th("Status", align: :right)
              end
            end
            table.tbody do
              Gallery::Data.members.each do |member|
                table.tr do
                  table.th(member.name, scope: :row)
                  table.td(member.role.to_s.humanize)
                  table.td(align: :right) do
                    render NitroKit::Badge.new(
                      member.status.to_s.humanize,
                      id: "gallery-dashboard-dense-member-#{member.id}-status",
                      color: member.status == :active ? :success : :warning,
                      size: :sm
                    )
                  end
                end
              end
            end
          end
        end
      end

      def render_invoice_section
        render NitroKit::DataSection.new(title: "Recent invoices", id: "gallery-dashboard-dense-invoices-section") do |section|
          section.table NitroKit::Table.new(
            id: "gallery-dashboard-dense-invoices",
            table_html: { id: "gallery-dashboard-dense-invoices-element" }
          ) do |table|
            table.caption("Recent invoices")
            table.thead do
              table.tr do
                table.th("Invoice")
                table.th("Status")
                table.th("Amount", align: :right)
              end
            end
            table.tbody do
              Gallery::Data.invoices.each do |invoice|
                table.tr do
                  table.th(invoice.number, scope: :row)
                  table.td(invoice.status.to_s.humanize)
                  table.td("#{invoice.currency} #{Kernel.format('%.2f', invoice.amount_cents.fdiv(100))}", align: :right)
                end
              end
            end
          end
        end
      end

      def render_integration_section
        render NitroKit::DataSection.new(
          title: "Integration delivery status",
          description: "Current health for every configured delivery destination.",
          id: "gallery-dashboard-integrations-section"
        ) do |section|
          section.table NitroKit::Table.new(
            id: "gallery-dashboard-integrations",
            table_html: { id: "gallery-dashboard-integrations-element" }
          ) do |table|
            table.caption("Integration delivery status")
            table.thead do
              table.tr do
                table.th("Integration")
                table.th("Status", align: :right)
              end
            end
            table.tbody do
              Gallery::Data.integrations.each do |integration|
                table.tr do
                  table.th(integration.name, scope: :row)
                  table.td(integration.status.to_s.humanize, align: :right)
                end
              end
            end
          end
        end
      end

      def workspace_status_label
        return "Degraded" if state == "degraded"
        return "Loading" if state == "loading"

        "Operational"
      end

      def workspace_status_color
        { "degraded" => :danger, "loading" => :info }.fetch(state, :success)
      end

      def state_navigation
        nav(aria: { label: "Dashboard states" }, data: { gallery: "composition-states" }) do
          entry.states.each do |name|
            a(href: entry_path(entry, state: name), aria: { current: state == name ? "page" : nil }) do
              name.humanize
            end
          end
        end
      end

      def state_description
        {
          "new" => "A newly created workspace with a successful handoff and meaningful empty activity state.",
          "active" => "Healthy status, metrics, a semantic request chart, actions, people, and deterministic recent activity.",
          "degraded" => "An error state keeps chart failure, incident impact, integration data, and recovery actions specific.",
          "loading" => "Workspace and chart frames remain visible while data and every mutable action are disabled.",
          "dense" => "Every deterministic record pressures metrics, a denser chart series, and three semantic tables at once.",
          "mobile" => "Long workspace, chart, and activity content stress the same atoms on a narrow surface."
        }.fetch(state)
      end
    end
  end
end
