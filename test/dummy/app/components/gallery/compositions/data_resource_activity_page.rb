module Gallery
  module Compositions
    class DataResourceActivityPage < ExpandedPage
      private

      def render_state
        render_filters
        render_error if state == "error"
        render_activity
        render_pagination if events.any?
      end

      def render_filters
        render NitroKit::SettingsSection.new(
          title: "Filter resource activity",
          description: "Find imports, synchronization, retention, and mutation events by resource or outcome.",
          id: "gallery-data-resource-activity-filters"
        ) do |section|
          section.form do
            form_with(
              model: filter,
              scope: :activity,
              url: flow_path(state: "filtered"),
              method: :get,
              builder: NitroKit::FormBuilder,
              id: "gallery-data-resource-activity-filter-form"
            ) do |form|
              form.group do
                render NitroKit::Grid.new(cols: "1 md:4", gap: 3, id: "gallery-data-resource-activity-filter-grid") do
                  form.field(
                    :query,
                    as: :search,
                    label: "Search activity",
                    placeholder: "Resource, actor, or event"
                  )
                  form.field(
                    :resource_id,
                    as: :select,
                    label: "Resource",
                    options: resource_options,
                    include_blank: "All resources"
                  )
                  form.field(
                    :outcome,
                    as: :select,
                    options: Gallery::Forms::ResourceActivityFilter::OUTCOMES.map { |outcome| [ outcome.humanize, outcome ] }
                  )
                  render NitroKit::Flex.new(dir: :row, gap: 2, align: :end, justify: :end, wrap: :wrap) do
                    render NitroKit::Button.new("Clear", href: flow_path(state: "recent"))
                    form.submit("Filter activity", id: "gallery-data-resource-activity-filter-submit")
                  end
                end
              end
            end
          end
        end
      end

      def render_error
        render NitroKit::Alert.new(id: "gallery-data-resource-activity-error", variant: :destructive) do |alert|
          alert.title("Resource activity could not be loaded")
          alert.description("The current query and resource selection remain available for a retry.")
        end
      end

      def render_activity
        render NitroKit::DataSection.new(
          title: "Resource activity",
          description: "Imports, synchronization, retention, and application mutations in newest-first order.",
          id: "gallery-data-resource-activity-results"
        ) do |section|
          unless state == "error"
            section.actions NitroKit::Button.new("Export activity", href: "#export-resource-activity")
          end

          if events.empty?
            section.empty_state(
              NitroKit::EmptyState.new(
                title: state == "error" ? "Activity is temporarily unavailable" : "No resource activity matches these filters",
                description: state == "error" ? "Retry after the activity service reconnects." : "Clear the resource or outcome filter and try again.",
                level: 3,
                id: "gallery-data-resource-activity-empty"
              )
            ) do |empty|
              empty.icon(NitroKit::Icon.new(state == "error" ? "triangle-alert" : "search"))
              empty.action(
                NitroKit::Button.new(
                  state == "error" ? "Retry" : "Clear filters",
                  href: flow_path(state: "recent"),
                  variant: :primary
                )
              )
            end
          else
            section.table(NitroKit::Table.new(
              id: "gallery-data-resource-activity-table",
              table_aria: { label: "Filtered data resource activity" }
            )) do |table|
              populate_activity_table(table)
            end
          end
        end
      end

      def populate_activity_table(table)
        table.caption("Filtered data resource activity")
        table.thead do
          table.tr do
            table.th("Resource")
            table.th("Activity")
            table.th("Actor") unless state == "mobile"
            table.th("Outcome")
            table.th("Occurred") unless state == "mobile"
          end
        end
        table.tbody do
          events.each_with_index do |event, index|
            table.tr do
              table.th(event.resource_name, scope: :row)
              table.td(activity_copy(event, index))
              table.td(event.actor) unless state == "mobile"
              table.td do
                render NitroKit::Badge.new(
                  event.outcome.to_s.humanize,
                  id: "gallery-data-resource-activity-event-#{index + 1}-outcome",
                  color: outcome_color(event.outcome),
                  size: :sm
                )
              end
              table.td(event.occurred_at.to_fs(:long)) unless state == "mobile"
            end
          end
        end
      end

      def render_pagination
        render NitroKit::PaginationBar.new(id: "gallery-data-resource-activity-pagination-bar") do |bar|
          bar.summary("Showing #{events.size} of 486 resource events", aria: { live: "polite" })
          bar.pagination(
            NitroKit::Pagination.new(
              id: "gallery-data-resource-activity-pagination",
              label: "Resource activity pages"
            )
          ) do |pagination|
            pagination.prev
            pagination.page(1, current: true)
            pagination.page(2, href: activity_page_path(2))
            pagination.ellipsis(label: "Pages 3 through 11 omitted")
            pagination.page(12, href: activity_page_path(12))
            pagination.next(href: activity_page_path(2))
          end
        end
      end

      def activity_page_path(page)
        flow_path(
          state:,
          page:,
          activity: {
            query: filter.query.presence,
            outcome: optional_outcome,
            resource_id: filter.resource_id.presence
          }.compact
        )
      end

      def filter
        @filter ||= Gallery::Forms::ResourceActivityFilter.new(filter_attributes)
      end

      def filter_attributes
        case state
        when "filtered"
          { query: "replication", outcome: "warning", resource_id: "res_audit" }
        when "empty"
          { query: "No matching resource event", outcome: "success", resource_id: nil }
        else
          { query: nil, outcome: "all", resource_id: nil }
        end
      end

      def events
        @events ||= begin
          if state == "error"
            []
          else
            matches = Gallery::ExpandedData.resource_events(
              query: filter.query.presence,
              outcome: optional_outcome,
              resource_id: filter.resource_id.presence
            )
            state == "dense" ? matches * 4 : matches
          end
        end
      end

      def optional_outcome
        filter.outcome == "all" ? nil : filter.outcome
      end

      def resource_options
        Gallery::ExpandedData.resources.map { |resource| [ resource.name, resource.id ] }
      end

      def activity_copy(event, index)
        return event.action unless state == "long" && index.zero?

        "#{event.action} across International Research, Production, Reliability Engineering, " \
          "Customer Operations, and every European replica"
      end

      def screen_title
        state == "long" ? "Data resource activity for International Research and Production" : "Data resource activity"
      end

      def header_actions(actions)
        actions.button("All resources", href: overview_path)
        actions.button("Resource settings", href: settings_path, variant: :primary)
      end

      def overview_path
        gallery_composition_path(slug: "data-resource-overview", state: "index")
      end

      def settings_path
        gallery_composition_path(slug: "data-resource-settings", state: "general")
      end

      def state_description
        {
          "recent" => "Recent imports, synchronization, retention, and mutation events across resources.",
          "filtered" => "Resource, outcome, and text filters narrow the event history together.",
          "empty" => "A valid zero-result activity query renders an explicit EmptyState.",
          "error" => "An activity-service failure preserves filters and separates unavailable from empty.",
          "dense" => "Repeated events pressure the activity table and pagination without a density API.",
          "long" => "Long operational event copy wraps inside the same accepted table structure.",
          "mobile" => "Caller-owned compact columns complement Nitro-owned narrow layout behavior."
        }.fetch(state)
      end
    end
  end
end
