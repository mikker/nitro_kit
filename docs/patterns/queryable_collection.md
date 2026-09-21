# Queryable collection

**Audience:** Coding agents and developers implementing filters, sorting, and
pagination with ordinary Rails GET requests and Turbo Drive.

## Summary

- Default to ordinary GET forms and links with Turbo Drive for a full-page
  collection. URL parameters are the state; keep Turbo's default caching.
- An application query object owns allowlists, defaults, tenant scope, and page
  bounds; `NitroKit::Table` owns no query policy.
- Pagination advances browser history; filters, reset, and sorting replace the
  current history entry.
- Add a Turbo Frame only when the collection is an independently navigable
  region of a larger page, not merely to make pagination feel faster.

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

## Page composition

```ruby
form_with(
  scope: :q,
  url: projects_path,
  method: :get,
  builder: NitroKit::FormBuilder,
  data: { turbo_action: "replace" }
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
```

Reset with the plain collection URL so stale parameters disappear. Sort,
filter, and reset controls may use `turbo_action: "replace"` to avoid filling
history with refinements; pagination uses ordinary links and advances history.
No result frame, frame targets, cache opt-out, or custom JavaScript is needed.
Optional autosubmit may call the same GET form's `requestSubmit`.

## When a frame is useful

For an independent collection within a larger page, wrap the region in a
stable `turbo_frame_tag("projects-results", data: { turbo_action: "advance" })`.
Return that frame for populated and empty responses, and target `_top` on
links that should open complete pages. Exercise repeated refinements followed
by pagination and Back/Forward, checking actual rows and controls as well as
the URL. Do not disable Turbo caching just to make a flaky history test pass;
first distinguish preview/test timing from an incorrect restored snapshot.

## Keep tables intact at every viewport

Every Table owns a horizontal scroll wrapper. Keep all columns and row actions
in their desktop arrangement on mobile; scroll the table instead of hiding
columns, stacking buttons, or forcing narrow column widths. Cells preserve
unbroken labels so controls retain their intrinsic size.

This complete table uses application-owned hooks. Adapt the fields and routes,
then load the accompanying CSS after Nitro Kit:

```ruby
Table(data: { ui: "resource-table" }, table_aria: { label: "Projects" }) do |table|
  table.thead do
    table.tr do
      table.th("Project", data: { resource_column: "name" })
      table.th("Status", data: { resource_column: "status" })
      table.th("Updated", data: { resource_column: "secondary" })
      table.th("Actions", data: { resource_column: "actions" })
    end
  end
  table.tbody do
    projects.each do |project|
      table.tr do
        table.th(project.name, scope: :row, data: { resource_column: "name" })
        table.td(data: { resource_column: "status" }) do
          Badge(project.archived? ? "Archived" : "Active", size: :sm)
        end
        table.td(project.updated_at.to_date.to_fs(:long), data: { resource_column: "secondary" })
        table.td(data: { resource_column: "actions" }) do
          Flex(dir: :row, gap: 1, align: :stretch, justify: :end) do
            Button("View", href: project_path(project), size: :sm)
            Button("Edit", href: edit_project_path(project), size: :sm)
          end
        end
      end
    end
  end
end
```

```css
/* Table owns horizontal scrolling; record names keep their secondary line. */
:where([data-ui="resource-table"] tbody [data-resource-column="name"] > *) {
  display: block;
}
```

The public Product resource gallery runs this composition. Table provides the
scroll wrapper automatically; no extra overflow wrapper is needed.

## Tests

Request-test parameter preservation, safe fallback for invalid sort keys, and
populated and empty responses. System-test repeated filter → sort →
paginate → Back/Forward, restored controls and rows, address-bar changes, and
full-page row links. A correct URL alone does not prove restoration worked.
When a visit displays a cached preview, wait for `html[data-turbo-preview]` to
disappear before entering fields or submitting another form. Keep caching
enabled in the test.
Use Capybara waiting assertions, not sleeps. At 390px, assert that the page stays within the viewport and the table scrolls
horizontally to reveal intact row actions, including a long unbroken resource
name and a multi-word status. Repeat in light and dark appearances.
