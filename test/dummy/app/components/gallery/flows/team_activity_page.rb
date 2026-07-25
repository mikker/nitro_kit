module Gallery
  module Flows
    class TeamActivityPage < ExpandedPage
      private

      def render_state
        render_filters
        render_error if state == "error"
        render_activity
        render_pagination if events.any?
      end

      def render_filters
        filter = activity_filter

        render NitroKit::FormSection.new(
          title: "Filter team activity",
          description: "Search terms and outcome filters remain caller-owned query state.",
          id: "gallery-team-activity-filters"
        ) do |section|
          section.form do
            form_with(
              model: filter,
              scope: :activity,
              url: flow_path(state: "search"),
              method: :get,
              builder: NitroKit::FormBuilder,
              id: "gallery-team-activity-filter-form"
            ) do |form|
              form.fieldset(legend: "Activity filters") do
                form.group do
                  form.field(
                    :query,
                    as: :search,
                    label: "Search activity",
                    placeholder: "Member, action, or subject"
                  )
                  form.field(
                    :outcome,
                    as: :select,
                    options: Gallery::Forms::ActivityFilter::OUTCOMES.map { |outcome| [ outcome.humanize, outcome ] }
                  )
                end
              end
              render NitroKit::Toolbar.new(id: "gallery-team-activity-filter-toolbar") do |toolbar|
                toolbar.trailing do
                  form.submit("Filter activity", id: "gallery-team-activity-filter-submit")
                end
              end
            end
          end
        end
      end

      def render_error
        render NitroKit::Alert.new(id: "gallery-team-activity-error", variant: :error) do |alert|
          alert.title("Team activity could not be loaded")
          alert.description("The query is still visible. Retry without losing the selected outcome filter.")
        end
      end

      def render_activity
        render NitroKit::DataSection.new(
          title: "Organization team activity",
          description: "Access, invitation, session, and policy events in newest-first order.",
          id: "gallery-team-activity-results"
        ) do |section|
          section.actions(NitroKit::ButtonGroup.new(label: "Team activity actions")) do |actions|
            actions.button("Export activity", href: "#export-team-activity")
          end

          if events.empty?
            section.empty_state(
              NitroKit::EmptyState.new(
                title: state == "error" ? "Activity is temporarily unavailable" : "No team activity matches these filters",
                description: state == "error" ? "Retry after the audit service reconnects." : "Change the search term or include another outcome.",
                level: 3,
                id: "gallery-team-activity-empty"
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
            section.table(NitroKit::Table.new(id: "gallery-team-activity-table")) do |table|
              populate_activity_table(table)
            end
          end
        end
      end

      def populate_activity_table(table)
        table.caption("Filtered team activity events")
        table.thead do
          table.tr do
            table.th("Member")
            table.th("Activity")
            table.th("Outcome")
            table.th("Occurred") unless state == "mobile"
          end
        end
        table.tbody do
          events.each_with_index do |event, index|
            table.tr do
              table.th(event.member_name, scope: :row)
              table.td(activity_copy(event, index))
              table.td do
                render NitroKit::Badge.new(
                  event.outcome.to_s.humanize,
                  id: "gallery-team-activity-event-#{index + 1}-outcome",
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
        render NitroKit::PaginationBar.new(id: "gallery-team-activity-pagination-bar") do |bar|
          bar.summary("Showing #{events.size} of 184 team events", aria: { live: "polite" })
          bar.pagination(
            NitroKit::Pagination.new(
              id: "gallery-team-activity-pagination",
              label: "Team activity pages"
            )
          ) do |pagination|
            pagination.prev
            pagination.page(1, current: true)
            pagination.page(2, href: activity_page_path(2))
            pagination.ellipsis(label: "Pages 3 through 7 omitted")
            pagination.page(8, href: activity_page_path(8))
            pagination.next(href: activity_page_path(2))
          end
        end
      end

      def activity_page_path(page)
        flow_path(
          state:,
          page:,
          activity: {
            query: activity_filter.query.presence,
            outcome: activity_filter.outcome == "all" ? nil : activity_filter.outcome
          }.compact
        )
      end

      def activity_filter
        @activity_filter ||= Gallery::Forms::ActivityFilter.new(filter_attributes)
      end

      def filter_attributes
        case state
        when "search"
          { query: "Grace", outcome: "all" }
        when "filtered"
          { query: "credentials", outcome: "blocked" }
        when "empty"
          { query: "No matching member or event", outcome: "success" }
        else
          { query: nil, outcome: "all" }
        end
      end

      def events
        @events ||= begin
          return [] if state == "error"

          filter = activity_filter
          matches = Gallery::ExpandedData.team_events(
            query: filter.query.presence,
            outcome: filter.outcome == "all" ? nil : filter.outcome
          )
          state == "dense" ? matches * 3 : matches
        end
      end

      def activity_copy(event, index)
        copy = "#{event.action}: #{event.subject}"
        return copy unless state == "long" && index.zero?

        "#{copy}. This change applies to International Research, Production, Reliability Engineering, " \
          "Customer Operations, and every delegated organization administrator."
      end

      def screen_title
        state == "long" ? "Team activity for Analytical Engines — International Research and Production" : "Team activity"
      end

      def header_actions(actions)
        actions.button("View members", href: gallery_flow_path(slug: "team-member", state: "active"))
        actions.button("Invite member", href: "#invite-member", variant: :primary)
      end

      def state_description
        {
          "recent" => "Recent organization access and membership events with caller-owned pagination.",
          "search" => "A realistic member search preserved in native GET form values and result links.",
          "filtered" => "Outcome filtering narrows the collection without teaching blocks query semantics.",
          "empty" => "A valid zero-result query uses the typed EmptyState content boundary.",
          "error" => "A recoverable audit-service failure preserves query controls and a retry route.",
          "dense" => "Repeated team events pressure tables and pagination without a density component option.",
          "long" => "Long organization policy copy wraps inside the same table and page blocks.",
          "mobile" => "A reduced caller-owned column set complements Nitro-owned narrow stacking."
        }.fetch(state)
      end
    end
  end
end
