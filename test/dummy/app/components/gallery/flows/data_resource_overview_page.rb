module Gallery
  module Flows
    class DataResourceOverviewPage < ExpandedPage
      private

      def render_state
        render_search
        render_error if state == "error"
        render_bulk_action if state == "bulk"
        render_resources
        render_pagination if resources.any?
      end

      def render_search
        render NitroKit::FormSection.new(
          title: "Find data resources",
          description: "Search terms and facets are ordinary caller-owned GET parameters.",
          id: "gallery-data-resource-overview-search"
        ) do |section|
          section.form do
            form_with(
              model: search,
              scope: :resources,
              url: flow_path(state: "search"),
              method: :get,
              builder: NitroKit::FormBuilder,
              id: "gallery-data-resource-overview-search-form"
            ) do |form|
              form.fieldset(legend: "Resource filters") do
                form.group do
                  form.field(
                    :query,
                    as: :search,
                    label: "Search resources",
                    placeholder: "Name, owner, or description",
                    autocomplete: "off"
                  )
                  form.field(
                    :status,
                    as: :select,
                    options: Gallery::Forms::ResourceSearch::STATUSES.map { |status| [ status.humanize, status ] }
                  )
                  form.field(
                    :kind,
                    as: :select,
                    options: Gallery::Forms::ResourceSearch::KINDS.map { |kind| [ kind.humanize, kind ] }
                  )
                end
              end
              render NitroKit::Toolbar.new(id: "gallery-data-resource-overview-search-toolbar") do |toolbar|
                toolbar.trailing do
                  form.submit("Filter resources", id: "gallery-data-resource-overview-search-submit")
                end
              end
            end
          end
        end
      end

      def render_error
        render NitroKit::Alert.new(id: "gallery-data-resource-overview-error", variant: :error) do |alert|
          alert.title("Data resources could not be loaded")
          alert.description("The current search remains visible while the catalog service reconnects.")
        end
      end

      def render_bulk_action
        action = Gallery::Forms::ResourceBulkAction.new(
          resource_ids: %w[res_customers res_deployments],
          action: "export"
        )

        render NitroKit::FormSection.new(
          title: "Bulk resource action",
          description: "Selection and operation semantics belong to an application form object.",
          id: "gallery-data-resource-overview-bulk"
        ) do |section|
          section.form do
            form_with(
              model: action,
              scope: :bulk_resources,
              url: "#bulk-resources",
              builder: NitroKit::FormBuilder,
              id: "gallery-data-resource-overview-bulk-form"
            ) do |form|
              render NitroKit::CheckboxGroup.new(
                id: "gallery-data-resource-overview-bulk-selection",
                legend: "Resources to update",
                description: "Read-only archives can be exported but cannot resume synchronization.",
                name: "bulk_resources[resource_ids][]",
                options: Gallery::ExpandedData.resources.map do |resource|
                  NitroKit::Choice.new(
                    label: "#{resource.name} — #{resource.owner}",
                    value: resource.id,
                    disabled: resource.status == :syncing
                  )
                end,
                value: action.resource_ids,
                disabled: !policy.bulk_resources?
              )
              form.field(
                :action,
                as: :select,
                label: "Action",
                options: [
                  [ "Export records", "export" ],
                  [ "Pause synchronization", "pause_sync" ],
                  [ "Archive resources", "archive" ]
                ],
                required: true,
                disabled: !policy.bulk_resources?
              )
              render NitroKit::Toolbar.new(id: "gallery-data-resource-overview-bulk-toolbar") do |toolbar|
                toolbar.leading do
                  render NitroKit::Button.new(
                    "Cancel selection",
                    href: flow_path(state: "index"),
                    variant: :ghost
                  )
                end
                toolbar.trailing do
                  form.submit(
                    "Review 2 selected resources",
                    id: "gallery-data-resource-overview-bulk-submit",
                    disabled: !policy.bulk_resources?
                  )
                end
              end
            end
          end
        end
      end

      def render_resources
        render NitroKit::DataSection.new(
          title: "Organization data resources",
          description: results_description,
          id: "gallery-data-resource-overview-results"
        ) do |section|
          section.actions(NitroKit::ButtonGroup.new(label: "Data resource actions")) do |actions|
            actions.button("Bulk actions", href: flow_path(state: "bulk"))
            actions.button("Create resource", href: "#create-resource", variant: :primary)
          end

          if resources.empty?
            section.empty_state(
              NitroKit::EmptyState.new(
                title: state == "error" ? "Resource catalog is unavailable" : "No resources match these filters",
                description: state == "error" ? "Retry after the catalog service reconnects." : "Clear the filters or create a new organization resource.",
                level: 3,
                id: "gallery-data-resource-overview-empty"
              )
            ) do |empty|
              empty.icon(NitroKit::Icon.new(state == "error" ? "triangle-alert" : "database"))
              empty.action(
                NitroKit::Button.new(
                  state == "error" ? "Retry" : "Clear filters",
                  href: flow_path(state: "index"),
                  variant: :primary
                )
              )
            end
          else
            section.table(NitroKit::Table.new(id: "gallery-data-resource-overview-table")) do |table|
              populate_resource_table(table)
            end
          end
        end
      end

      def populate_resource_table(table)
        table.caption("Filtered organization data resources")
        table.thead do
          table.tr do
            table.th("Resource")
            table.th("Kind") unless state == "mobile"
            table.th("Owner") unless state == "mobile"
            table.th("Status")
            table.th("Records", align: :right)
          end
        end
        table.tbody do
          resources.each_with_index do |resource, index|
            table.tr do
              table.th(resource_name(resource, index), scope: :row)
              table.td(resource.kind.to_s.humanize) unless state == "mobile"
              table.td(resource.owner) unless state == "mobile"
              table.td do
                render NitroKit::Badge.new(
                  resource.status.to_s.humanize,
                  id: "gallery-data-resource-overview-resource-#{index + 1}-status",
                  color: resource_status_color(resource.status),
                  size: :sm
                )
              end
              table.td(resource.record_count.to_fs(:delimited), align: :right)
            end
          end
        end
      end

      def render_pagination
        render NitroKit::PaginationBar.new(id: "gallery-data-resource-overview-pagination-bar") do |bar|
          bar.summary("Showing #{resources.size} of 24 resources", aria: { live: "polite" })
          bar.pagination(
            NitroKit::Pagination.new(
              id: "gallery-data-resource-overview-pagination",
              label: "Data resource pages"
            )
          ) do |pagination|
            pagination.prev
            pagination.page(1, current: true)
            pagination.page(2, href: resource_page_path(2))
            pagination.page(3, href: resource_page_path(3))
            pagination.next(href: resource_page_path(2))
          end
        end
      end

      def resource_page_path(page)
        flow_path(
          state:,
          page:,
          resources: {
            query: search.query.presence,
            status: optional_filter(search.status),
            kind: optional_filter(search.kind)
          }.compact
        )
      end

      def search
        @search ||= Gallery::Forms::ResourceSearch.new(search_attributes)
      end

      def search_attributes
        case state
        when "search"
          { query: "production", status: "all", kind: "all" }
        when "filtered"
          { query: nil, status: "healthy", kind: "dataset" }
        when "empty"
          { query: "No matching resource", status: "all", kind: "all" }
        else
          { query: nil, status: "all", kind: "all" }
        end
      end

      def resources
        @resources ||= begin
          if state == "error"
            []
          else
            matches = Gallery::ExpandedData.resources(
              query: search.query.presence,
              status: optional_filter(search.status),
              kind: optional_filter(search.kind)
            )
            state == "dense" ? matches * 3 : matches
          end
        end
      end

      def optional_filter(value)
        value == "all" ? nil : value
      end

      def resource_name(resource, index)
        return resource.name unless state == "long" && index.zero?

        "Customer accounts for International Research, Production, Reliability Engineering, and Customer Operations"
      end

      def results_description
        return "The resource query failed before any records were returned." if state == "error"
        return "No caller-owned records satisfy the current query and facets." if resources.empty?

        "Searchable resources with caller-owned status, kind, owner, and record totals."
      end

      def policy
        Gallery::ExpandedAccessPolicy.new(role: :administrator)
      end

      def screen_title
        state == "long" ? "Data resources for Analytical Engines — International Research and Production" : "Data resources"
      end

      def header_actions(actions)
        actions.button("Resource activity", href: activity_path)
        actions.button("Resource settings", href: settings_path, variant: :primary)
      end

      def activity_path
        gallery_flow_path(slug: "data-resource-activity", state: "recent")
      end

      def settings_path
        gallery_flow_path(slug: "data-resource-settings", state: "general")
      end

      def state_description
        {
          "index" => "A searchable, paginated inventory of caller-owned organization resources.",
          "search" => "A resource query remains visible in the native GET form and result links.",
          "filtered" => "Status and kind facets narrow the resource collection programmatically.",
          "bulk" => "A policy-gated application form selects resources and an operation for review.",
          "empty" => "A valid zero-result query uses the typed EmptyState boundary.",
          "error" => "A catalog failure preserves filters and presents an explicit recovery route.",
          "dense" => "Repeated resources pressure the table and pagination without a density API.",
          "long" => "Long organization and resource names wrap through the accepted structures.",
          "mobile" => "Caller-owned compact columns complement Nitro-owned narrow layout behavior."
        }.fetch(state)
      end
    end
  end
end
