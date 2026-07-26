# Queryable collection

Use one GET-driven Turbo Frame for filters, sorting, results, and pagination. The URL is the state: the query object reads parameters, the server renders the complete region, and browser history remains useful.

## Contract

- The frame has one stable ID.
- The frame promotes pagination with `data-turbo-action="advance"` so each page
  remains a meaningful Back and Forward step.
- Filter forms use GET, target that frame, and replace the current history entry.
- A small filter set stays in one responsive row at wide widths and stacks on
  narrow screens. Do not turn two fields and two actions into a full-page form.
- Sort and pagination links preserve the active query parameters. Sort links
  replace the current history entry; pagination inherits the frame's `advance`.
- `NitroKit::Table` renders the sortable table contract but does not own query policy.
- The HTML response always contains the same frame, including empty results.
- No Stimulus controller is required for submit-based filters. An optional autosubmit controller may submit the same GET form without becoming the source of truth.

## Controller

Keep parameter normalization and allowlists in an application query object. Ransack is one possible implementation, not a Nitro dependency.

```ruby
class ProjectsController < ApplicationController
  def index
    @query = ProjectsQuery.new(Project.all, params: params.fetch(:q, {}), page: params[:page])
  end
end
```

The query object should expose `records`, `filters`, `current_sort`, `direction`, `sort_url(key)`, and pagination URLs. It is also the right place for Ransack allowlists, default ordering, and page bounds.

## Phlex region

```ruby
module UI
  class ProjectsTable < Phlex::HTML
    include Phlex::Rails::Helpers::FormWith
    include Phlex::Rails::Helpers::TurboFrameTag

    FRAME_ID = "projects-results"

    def initialize(query)
      @query = query
    end

    def view_template
      turbo_frame_tag(FRAME_ID, data: { turbo_action: "advance" }) do
        render NitroKit::Flex.new(dir: :col, gap: 6, align: :stretch) do
          render_filters
          render_results
          render_pagination
        end
      end
    end

    private
      attr_reader :query

      def render_filters
        form_with(
          scope: :q,
          url: "/projects",
          method: :get,
          builder: NitroKit::FormBuilder,
          data: {
            turbo_frame: FRAME_ID,
            turbo_action: "replace"
          }
        ) do |form|
          form.hidden_field(:s, value: query.filters["s"])
          render NitroKit::Grid.new(cols: "1 md:3", gap: 3) do
            form.field(:name_cont, as: :search, label: "Search", value: query.filters["name_cont"])
            form.field(:status_eq, as: :select, label: "Status", options: Project.statuses.keys, include_blank: "All statuses", value: query.filters["status_eq"])
            render NitroKit::Flex.new(dir: :row, gap: 2, align: :end, justify: :end) do
              render NitroKit::Button.new(
                "Reset",
                href: "/projects",
                data: {
                  turbo_frame: FRAME_ID,
                  turbo_action: "replace"
                }
              )
              form.submit("Apply filters", data: { turbo_submits_with: "Filtering…" })
            end
          end
        end
      end

      def render_results
        render NitroKit::Table.new(
          sort: query.current_sort,
          direction: query.direction
        ) do |table|
          table.caption("Projects")
          table.thead do
            table.tr do
              table.th(
                sort: :name,
                href: query.sort_url(:name),
                sort_data: { turbo_action: "replace" }
              )
              table.th(
                sort: :status,
                href: query.sort_url(:status),
                sort_data: { turbo_action: "replace" }
              )
              table.th(
                "Updated",
                sort: :updated_at,
                href: query.sort_url(:updated_at),
                align: :right,
                sort_data: { turbo_action: "replace" }
              )
              table.th("Actions", align: :right)
            end
          end
          table.tbody do
            if query.records.any?
              query.records.each { |project| render_row(table, project) }
            else
              table.tr { table.td("No projects match these filters.", html: { colspan: 4 }) }
            end
          end
        end
      end

      def render_row(table, project)
        table.tr do
          table.th(project.name, scope: :row)
          table.td { render NitroKit::Badge.new(project.status.humanize) }
          table.td(project.updated_at.to_date.to_fs(:long), align: :right)
          table.td(align: :right) do
            render NitroKit::Button.new(
              "View",
              href: project_path(project),
              data: { turbo_frame: "_top" }
            )
          end
        end
      end

      def render_pagination
        render NitroKit::PaginationBar.new do |bar|
          bar.summary(query.summary)
          bar.pagination(query.pagination)
        end
      end
  end
end
```

Sorting and pagination links rendered inside the frame naturally navigate it.
The frame's `advance` action makes pagination a browser-history step. Filters,
reset links, and sort links override that default with `turbo_action: "replace"`
so repeated query refinements do not fill history with disposable states. Use
`data: { turbo_frame: FRAME_ID }` when a query control sits outside the frame.
Reset with a plain collection URL so stale query parameters disappear.

Links that leave the collection, including View, Edit, and New, are not frame
navigations. Give them `data: { turbo_frame: "_top" }`, or place them outside
the results frame. Otherwise Turbo will look for the collection frame in the
destination response and replace the region with “Content missing.”

## Tests

Request tests should prove that query parameters survive sort and page changes,
invalid sort keys fall back safely, and the response always contains
`turbo-frame#projects-results`. A system test should use real clicks, scope
result assertions to that frame, cover filter → sort → paginate → Back and
Forward, assert the address bar after each query transition, and open a row
action without a frame-missing error. Use Capybara's retrying assertions rather
than sleeps or arbitrary waits.
