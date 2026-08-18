module Gallery
  module Compositions
    class ActivityAuditPage < ExpandedPage
      private

      def render_state
        render_filters
        render_error if state == "error"
        render_events
        render_pagination if events.any?
      end

      def render_filters
        form_with(model: audit_filter, scope: :audit, url: flow_path(state: "filter"), method: :get, builder: NitroKit::FormBuilder, id: "gallery-activity-audit-filter-form") do |form|
          form.fieldset(legend: "Filter audit history", html: { id: "gallery-activity-audit-filter-section" }) do
            form.group do
              render NitroKit::Grid.new(cols: "1 md:3", gap: 3) do
                form.field(:query, as: :search, label: "Search activity", placeholder: "Actor, action, or subject", autocomplete: "off")
                form.field(
                  :category,
                  as: :select,
                  label: "Category",
                  options: Gallery::Forms::AuditFilter::CATEGORIES.map { |category| [ category.humanize, category ] }
                )
                render NitroKit::Flex.new(dir: :row, gap: 2, align: :end, justify: :end, wrap: :wrap) do
                  if audit_filter.query.present? || audit_filter.category != "all"
                    render NitroKit::Button.new("Clear", href: flow_path(state: "normal"))
                  end
                  form.submit("Apply filters", id: "gallery-activity-audit-filter-submit")
                end
              end
            end
          end
        end
      end

      def render_error
        render NitroKit::Alert.new(id: "gallery-activity-audit-error", variant: :destructive) do |alert|
          alert.icon NitroKit::Icon.new(:circle_x, id: "gallery-activity-audit-error-icon")
          alert.title("Audit history could not be loaded")
          alert.description("The current filters remain visible. No export or audit record was changed.")
        end
      end

      def render_events
        render NitroKit::DataSection.new(
          title: "Workspace audit history",
          description: "Security, access, data, billing, and integration events ordered newest first.",
          id: "gallery-activity-audit-results"
        ) do |section|
          if events.empty?
            section.empty_state NitroKit::EmptyState.new(
              title: state == "error" ? "Audit history is temporarily unavailable" : "No audit events match these filters",
              description: state == "error" ? "Retry after the audit service reconnects." : "Clear the search or select another category.",
              variant: :borderless,
              level: 3,
              id: "gallery-activity-audit-empty"
            ) do |empty|
              empty.icon NitroKit::Icon.new(state == "error" ? :triangle_alert : :search, id: "gallery-activity-audit-empty-icon")
              empty.action NitroKit::Button.new(
                state == "error" ? "Retry" : "Clear filters",
                href: flow_path(state: "normal"),
                variant: :primary,
                id: "gallery-activity-audit-empty-action"
              )
            end
          else
            section.table NitroKit::Table.new(id: "gallery-activity-audit-table") do |table|
              populate_events_table(table)
            end
          end
        end
      end

      def populate_events_table(table)
        table.caption("Filtered workspace audit events")
        table.thead do
          table.tr do
            table.th("Actor")
            table.th("Activity")
            table.th("Category") unless state == "mobile"
            table.th("Outcome")
            table.th("IP address") unless state == "mobile"
            table.th("Occurred") unless state == "mobile"
          end
        end
        table.tbody do
          events.each_with_index do |event, index|
            table.tr do
              table.th(event.actor, scope: :row)
              table.td("#{event.action}: #{event.subject}")
              table.td(event.category.to_s.humanize) unless state == "mobile"
              table.td do
                render NitroKit::Badge.new(
                  event.outcome.to_s.humanize,
                  id: "gallery-activity-audit-event-#{index + 1}-outcome",
                  color: outcome_color(event.outcome),
                  size: :sm
                )
              end
              table.td(event.ip_address) unless state == "mobile"
              table.td(event.occurred_at.to_fs(:long)) unless state == "mobile"
            end
          end
        end
      end

      def render_pagination
        render NitroKit::PaginationBar.new(id: "gallery-activity-audit-pagination-bar") do |bar|
          bar.summary("Showing #{events.size} of 842 audit events", aria: { live: "polite" })
          bar.pagination(
            NitroKit::Pagination.new(
              id: "gallery-activity-audit-pagination",
              label: "Audit history pages"
            )
          ) do |pagination|
            pagination.prev
            pagination.page(1, current: true)
            pagination.page(2, href: flow_path(state:, page: 2, query: audit_filter.query.presence))
            pagination.ellipsis(label: "Pages 3 through 140 omitted")
            pagination.page(141, href: flow_path(state:, page: 141, query: audit_filter.query.presence))
            pagination.next(href: flow_path(state:, page: 2, query: audit_filter.query.presence))
          end
        end
      end

      def audit_filter
        @audit_filter ||= Gallery::Forms::AuditFilter.new(filter_attributes)
      end

      def filter_attributes
        case state
        when "filter"
          { query: "credential", category: "security" }
        when "empty"
          { query: "No matching actor or event", category: "billing" }
        else
          { query: nil, category: "all" }
        end
      end

      def events
        @events ||= begin
          return [] if state == "error"

          matches = Gallery::OperationalData.audit_events
          if audit_filter.query.present?
            query = audit_filter.query.downcase
            matches = matches.select do |event|
              [ event.actor, event.action, event.subject ].any? { |value| value.downcase.include?(query) }
            end
          end
          if audit_filter.category != "all"
            matches = matches.select { |event| event.category.to_s == audit_filter.category }
          end
          state == "dense" ? matches * 3 : matches
        end
      end

      def header_actions(actions)
        actions.button("Retention policy", href: "#audit-retention")
        actions.button("Export audit history", href: "#audit-export", variant: :primary)
      end

      def screen_title = state == "mobile" ? "Audit activity" : "Workspace activity and audit log"

      def state_description
        {
          "normal" => "Review who changed workspace access, data, billing, and integrations, newest first.",
          "filter" => "One security-related event matches the current search and category.",
          "empty" => "No billing events match this search. Try a broader term or another category.",
          "dense" => "Review a longer period of workspace activity with the same filters and export path.",
          "error" => "Audit history is temporarily unavailable, but your current filters have been preserved.",
          "mobile" => "Recent actors, activity, and outcomes remain available on a narrow screen."
        }.fetch(state)
      end
    end
  end
end
