# Queryable collection

**Audience:** Coding agents and developers implementing filters, sorting, and
pagination with Turbo Frames.

## Summary

- One GET-driven Turbo Frame owns filters, sorting, results, and pagination;
  URL parameters are the state.
- An application query object owns allowlists, defaults, tenant scope, and page
  bounds; `NitroKit::Table` owns no query policy.
- Pagination advances browser history; filters, reset, and sorting replace the
  current history entry.
- Every response contains the same frame, including empty results; links that
  leave the collection target `_top`.

## Query contract

Build the query from a tenant-scoped relation:

```ruby
def index
  @query = ProjectsQuery.new(
    Current.account.projects,
    params: params.fetch(:q, {}),
    page: params[:page]
  )
end
```

The query object owns parameter allowlists, default ordering, page bounds, and
query URL generation. It may expose `records`, `filters`, `current_sort`,
`direction`, `sort_url(key)`, `pagination`, and `summary`. Ransack is one
possible implementation, not a Nitro dependency.

## Frame composition

```ruby
FRAME_ID = "projects-results"

turbo_frame_tag(FRAME_ID, data: { turbo_action: "advance" }) do
  form_with(
    scope: :q,
    url: projects_path,
    method: :get,
    builder: NitroKit::FormBuilder,
    data: { turbo_frame: FRAME_ID, turbo_action: "replace" }
  ) do |form|
    form.group do
      form.field(:name_cont, as: :search, label: "Search")
      form.submit("Apply filters")
    end
  end

  render NitroKit::Table.new(
    sort: query.current_sort,
    direction: query.direction
  ) do |table|
    table.caption("Projects")
    table.thead do
      table.tr do
        table.th(:name, sort: :name, href: query.sort_url(:name),
          sort_data: { turbo_action: "replace" })
      end
    end
    table.tbody do
      query.records.each { |project| render_project_row(table, project) }
    end
  end

  render NitroKit::PaginationBar.new do |bar|
    bar.summary(query.summary)
    bar.pagination(query.pagination)
  end
end
```

Reset with the plain collection URL so stale parameters disappear. Sort and
filter controls use `turbo_action: "replace"`; pagination inherits the frame's
`advance`. Give View, Edit, and New links
`data: { turbo_frame: "_top" }` or place them outside the frame.

No Stimulus controller is required. Optional autosubmit may call the same GET
form's `requestSubmit`; the URL remains the source of truth.

## Tests

Request-test parameter preservation, safe fallback for invalid sort keys, and
the stable frame in populated and empty responses. System-test filter → sort →
paginate → Back/Forward, address-bar changes, and a row link leaving the frame.
Use Capybara waiting assertions, not sleeps.
