module Gallery
  module Flows
    class OrganizationOverviewPage < ExpandedPage
      private

      def render_state
        render_status
        render_stats
        render_resources
        render_resource_pagination if resources.any?
      end

      def render_status
        return unless state == "error"

        render NitroKit::Alert.new(id: "gallery-organization-overview-error", variant: :error) do |alert|
          alert.title("Organization resource totals are temporarily unavailable")
          alert.description("The last verified organization identity remains visible while regional totals are retried.")
        end
      end

      def render_stats
        organization = Gallery::ExpandedData.organization
        empty = state == "empty"

        render NitroKit::StatGrid.new(id: "gallery-organization-overview-stats") do |stats|
          stats.stat(key: :members, label: "Members", value: empty ? "0" : organization.member_count.to_fs(:delimited), detail: "Across 14 teams")
          stats.stat(key: :resources, label: "Data resources", value: empty ? "0" : organization.resource_count.to_s, detail: "Six resource kinds")
          stats.stat(key: :storage, label: "Storage", value: empty ? "0 GB" : "#{organization.storage_gb} GB", detail: "62% of allowance")
          if state == "dense"
            stats.stat(key: :regions, label: "Active regions", value: "4", detail: "No replication backlog")
            stats.stat(key: :requests, label: "Requests today", value: "1,284,320", detail: "99.98% successful")
            stats.stat(key: :exports, label: "Exports", value: "38", detail: "Three still processing")
          end
        end
      end

      def render_resources
        render NitroKit::DataSection.new(
          title: state == "empty" ? "Organization resources" : "Recently updated resources",
          description: resource_description,
          id: "gallery-organization-overview-resources"
        ) do |section|
          section.actions(
            NitroKit::ButtonGroup.new(label: "Organization resource actions")
          ) do |actions|
            actions.button("View all", href: data_overview_path)
            actions.button("Create resource", href: "#create-resource", variant: :primary)
          end

          if resources.empty?
            section.empty_state(
              NitroKit::EmptyState.new(
                title: state == "error" ? "Resource summary could not be loaded" : "No organization resources yet",
                description: state == "error" ? "Retry the request or review the regional status page." : "Create a resource to begin collecting application data.",
                level: 3,
                id: "gallery-organization-overview-empty"
              )
            ) do |empty|
              empty.icon(NitroKit::Icon.new(state == "error" ? "triangle-alert" : "database"))
              empty.action(
                NitroKit::Button.new(
                  state == "error" ? "Retry" : "Create resource",
                  href: state == "error" ? flow_path(state: "active") : "#create-resource",
                  variant: :primary
                )
              )
            end
          else
            section.table(resource_table) { |table| populate_resource_table(table) }
          end
        end
      end

      def resource_table
        NitroKit::Table.new(id: "gallery-organization-overview-resource-table")
      end

      def populate_resource_table(table)
        table.caption("Recently updated resources for #{Gallery::ExpandedData.organization.name}")
        table.thead do
          table.tr do
            table.th("Resource")
            table.th("Owner") unless state == "mobile"
            table.th("Status")
            table.th("Records", align: :right)
          end
        end
        table.tbody do
          resources.each_with_index do |resource, index|
            table.tr do
              table.th(resource_name(resource, index), scope: :row)
              table.td(resource.owner) unless state == "mobile"
              table.td do
                render NitroKit::Badge.new(
                  resource.status.to_s.humanize,
                  id: "gallery-organization-overview-resource-#{index + 1}-status",
                  color: resource_status_color(resource.status),
                  size: :sm
                )
              end
              table.td(resource.record_count.to_fs(:delimited), align: :right)
            end
          end
        end
      end

      def render_resource_pagination
        render NitroKit::PaginationBar.new(id: "gallery-organization-overview-pagination-bar") do |bar|
          bar.summary("Showing #{resources.size} of #{Gallery::ExpandedData.organization.resource_count} resources")
          bar.pagination(
            NitroKit::Pagination.new(
              id: "gallery-organization-overview-pagination",
              label: "Organization resource pages"
            )
          ) do |pagination|
            pagination.prev
            pagination.page(1, current: true)
            pagination.page(2, href: flow_path(state:, page: 2))
            pagination.page(3, href: flow_path(state:, page: 3))
            pagination.next(href: flow_path(state:, page: 2))
          end
        end
      end

      def resources
        return [] if state.in?(%w[empty error])
        return Gallery::ExpandedData.resources.first(3) if state == "mobile"
        return Gallery::ExpandedData.resources * 2 if state == "dense"

        Gallery::ExpandedData.resources
      end

      def resource_name(resource, index)
        return resource.name unless state == "long" && index.zero?

        "Customer accounts for International Research, Production, Reliability Engineering, and Customer Operations"
      end

      def resource_description
        return "Verified totals could not be refreshed." if state == "error"
        return "Resources appear here after the first successful import." if state == "empty"

        "Caller-owned resource records ordered by their latest verified update."
      end

      def screen_title
        return "Analytical Engines — International Research, Production, and Reliability Engineering" if state == "long"

        Gallery::ExpandedData.organization.name
      end

      def header_actions(actions)
        actions.button("Organization settings", href: organization_settings_path)
        actions.button("Invite member", href: "#invite-member", variant: :primary)
      end

      def organization_settings_path
        gallery_flow_path(slug: "organization-settings", state: "general")
      end

      def data_overview_path
        gallery_flow_path(slug: "data-resource-overview", state: "index")
      end

      def state_description
        {
          "active" => "Operational organization identity, capacity, and recently updated resources.",
          "empty" => "A new organization before members or data resources have been created.",
          "error" => "Stable organization identity with a recoverable resource-summary failure.",
          "dense" => "Additional metrics and repeated records pressure the overview without a density API.",
          "long" => "Long organization and resource names wrap through the same accepted blocks.",
          "mobile" => "The same overview uses compact table content inside Nitro-owned narrow layouts."
        }.fetch(state)
      end
    end
  end
end
