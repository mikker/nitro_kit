# Queryable collection

Use one GET-driven Turbo Frame for filters, sorting, results, and pagination. The URL is the state: the query object reads parameters, the server renders the complete region, and browser history remains useful.

## Contract

- The frame has one stable ID.
- Filter forms use GET and target that frame.
- Sort and pagination links preserve the active query parameters.
- `NitroKit::SortableTable` renders the table contract but does not own query policy.
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
      turbo_frame_tag(FRAME_ID) do
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
          data: { turbo_frame: FRAME_ID }
        ) do |form|
          form.hidden_field(:s, value: query.filters["s"])
          form.group do
            form.field(:name_cont, as: :search, label: "Search", value: query.filters["name_cont"])
            form.field(:status_eq, as: :select, label: "Status", options: Project.statuses.keys, include_blank: "All statuses", value: query.filters["status_eq"])
          end
          form.submit("Apply filters", data: { turbo_submits_with: "Filtering…" })
        end
      end

      def render_results
        render NitroKit::SortableTable.new(
          current: query.current_sort,
          direction: query.direction
        ) do |table|
          table.caption("Projects")
          table.thead do
            table.tr do
              table.sortable_th(:name, href: query.sort_url(:name))
              table.sortable_th(:status, href: query.sort_url(:status))
              table.sortable_th(:updated_at, "Updated", href: query.sort_url(:updated_at), align: :right)
            end
          end
          table.tbody do
            if query.records.any?
              query.records.each { |project| render_row(table, project) }
            else
              table.tr { table.td("No projects match these filters.", html: { colspan: 3 }) }
            end
          end
        end
      end

      def render_row(table, project)
        table.tr do
          table.th(project.name, scope: :row)
          table.td { render NitroKit::Badge.new(project.status.humanize) }
          table.td(project.updated_at.to_date.to_fs(:long), align: :right)
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

Sorting and pagination links rendered inside the frame naturally navigate it. Use `data: { turbo_frame: FRAME_ID }` when a control sits outside the frame. Reset with a plain collection URL so stale query parameters disappear.

## Tests

Request tests should prove that query parameters survive sort and page changes, invalid sort keys fall back safely, and the response always contains `turbo-frame#projects-results`. A system test should cover filter → sort → paginate → Back when this is a central product flow.
