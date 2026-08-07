module Gallery
  module Components
    class PaginationPage < ComponentPage
      private

      def source_note
        "app/components/nitro_kit/pagination.rb"
      end

      def api_note
        "NitroKit::Pagination.new(label:, pagy: nil) { |pagination| pagination.page; pagination.ellipsis }"
      end

      def gallery_pagy(page)
        Pagy::Method # loads Pagy::Request
        Pagy::Offset.new(
          count: 287,
          page:,
          limit: 25,
          request: Pagy::Request.new(request: { path: "/gallery/records", params: { "status" => "active" } })
        )
      end

      def component_template
        example_section(
          "Boundary states",
          slug: "pagination-boundaries",
          description: "First, middle, and last pages expose one current item and disabled outer boundaries."
        ) do
          example("First, middle, last", slug: "pagination-boundary-matrix", layout: :matrix) do
            Gallery::Data.pagination_boundaries.each do |pagination|
              sample(pagination.label, slug: pagination.slug) do
                render_boundary(pagination)
              end
            end
          end
        end

        example_section(
          "Pagy",
          slug: "pagination-pagy",
          description: "A real Pagy object supplies previous, series, gap, current, and next items through its public API. The application still owns the query and the route."
        ) do
          example("First, middle, and last Pagy pages", slug: "pagination-pagy-pages", layout: :matrix, mode: :full_width) do
            [ [ "First page", 1 ], [ "Middle page", 6 ], [ "Last page", 12 ] ].each do |label, page|
              sample(label, slug: "pagination-pagy-#{page}") do
                render NitroKit::Pagination.new(
                  pagy: gallery_pagy(page),
                  id: "gallery-pagination-pagy-#{page}",
                  label: "#{label} of workspace records"
                )
              end
            end
          end
        end

        example_section(
          "Ranges and ellipses",
          slug: "pagination-ranges",
          description: "Compact and long ranges use non-interactive, accessibly labelled ellipses."
        ) do
          example("Compact range", slug: "pagination-compact-range") do
            render NitroKit::Pagination.new(
              id: "gallery-pagination-compact",
              label: "Compact result pages"
            ) do |pagination|
              pagination.prev(href: "/gallery/results?page=1", id: "gallery-pagination-compact-previous")
              pagination.page(1, href: "/gallery/results?page=1", id: "gallery-pagination-compact-page-1")
              pagination.page(2, current: true, id: "gallery-pagination-compact-page-2")
              pagination.page(3, href: "/gallery/results?page=3", id: "gallery-pagination-compact-page-3")
              pagination.next(href: "/gallery/results?page=3", id: "gallery-pagination-compact-next")
            end
          end

          example("Long range", slug: "pagination-long-range", mode: :full_width) do
            render NitroKit::Pagination.new(
              id: "gallery-pagination-long",
              label: "Long audit log pages"
            ) do |pagination|
              pagination.prev(href: "/gallery/audit?page=6", id: "gallery-pagination-long-previous")
              pagination.page(1, href: "/gallery/audit?page=1", id: "gallery-pagination-long-page-1")
              pagination.ellipsis(label: "Pages 2 through 5 omitted")
              pagination.page(6, href: "/gallery/audit?page=6", id: "gallery-pagination-long-page-6")
              pagination.page(7, current: true, id: "gallery-pagination-long-page-7")
              pagination.page(8, href: "/gallery/audit?page=8", id: "gallery-pagination-long-page-8")
              pagination.ellipsis(label: "Pages 9 through 23 omitted")
              pagination.page(24, href: "/gallery/audit?page=24", id: "gallery-pagination-long-page-24")
              pagination.next(href: "/gallery/audit?page=8", id: "gallery-pagination-long-next")
            end
          end
        end

        example_section(
          "Labels and pressure",
          slug: "pagination-content",
          description: "Long navigation copy, block page labels, icon-only boundaries, and wide ranges remain semantic."
        ) do
          example("Long labels", slug: "pagination-long-labels", mode: :full_width) do
            render NitroKit::Pagination.new(
              id: "gallery-pagination-labels",
              label: "Archived audit record pages"
            ) do |pagination|
              pagination.prev(
                "Back to newer archived records",
                href: "/gallery/archive?page=4",
                icon: nil,
                id: "gallery-pagination-labels-previous"
              )
              pagination.page(href: "/gallery/archive?page=5", id: "gallery-pagination-labels-page") do
                "A custom page label"
              end
              pagination.next(
                "Continue to older archived records",
                href: "/gallery/archive?page=6",
                icon: nil,
                id: "gallery-pagination-labels-next"
              )
            end
          end

          example("Horizontal pressure", slug: "pagination-horizontal-pressure", mode: :full_width) do
            render NitroKit::Pagination.new(
              id: "gallery-pagination-pressure",
              label: "Twelve visible pages"
            ) do |pagination|
              pagination.prev(href: "/gallery/pressure?page=5", id: "gallery-pagination-pressure-previous")
              (1..12).each do |page|
                pagination.page(
                  page,
                  href: "/gallery/pressure?page=#{page}",
                  current: page == 6,
                  id: "gallery-pagination-pressure-page-#{page}"
                )
              end
              pagination.next(href: "/gallery/pressure?page=7", id: "gallery-pagination-pressure-next")
            end
          end
        end

        example_section(
          "Paginated results",
          slug: "pagination-results",
          description: "Field, Input, Table, Badge, Button, and Pagination compose into searchable member results."
        ) do
          example("Member search", slug: "pagination-member-search", mode: :full_width) do
            render NitroKit::Field.new(
              nil,
              :query,
              as: :search,
              id: "gallery-pagination-search",
              name: "search[query]",
              value: "engineering",
              label: "Search members",
              placeholder: "Name or email",
              html: { id: "gallery-pagination-search-field" }
            )

            render NitroKit::Table.new(
              id: "gallery-pagination-results-table",
              table_html: { id: "gallery-pagination-results-table-element" }
            ) do |table|
              table.caption("Three of 128 matching members")
              table.thead do
                table.tr do
                  table.th("Name")
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
                        id: "gallery-pagination-result-status-#{member.id}",
                        color: member_status_color(member.status),
                        size: :sm
                      )
                    end
                  end
                end
              end
            end

            render NitroKit::Pagination.new(
              id: "gallery-pagination-results",
              label: "Member search result pages"
            ) do |pagination|
              pagination.prev(id: "gallery-pagination-results-previous")
              pagination.page(1, current: true, id: "gallery-pagination-results-page-1")
              pagination.page(2, href: "/gallery/members?query=engineering&page=2", id: "gallery-pagination-results-page-2")
              pagination.ellipsis(label: "Pages 3 through 15 omitted")
              pagination.page(16, href: "/gallery/members?query=engineering&page=16", id: "gallery-pagination-results-page-16")
              pagination.next(
                href: "/gallery/members?query=engineering&page=2",
                id: "gallery-pagination-results-next"
              )
            end
          end
        end
      end

      def render_boundary(example)
        render NitroKit::Pagination.new(
          id: "gallery-pagination-boundary-#{example.slug}",
          label: example.label
        ) do |pagination|
          pagination.prev(
            href: example.previous_href,
            id: "gallery-pagination-boundary-#{example.slug}-previous"
          )
          example.pages.each do |page|
            pagination.page(
              page,
              href: "/gallery/search?page=#{page}",
              current: page == example.current_page,
              id: "gallery-pagination-boundary-#{example.slug}-page-#{page}"
            )
          end
          pagination.next(
            href: example.next_href,
            id: "gallery-pagination-boundary-#{example.slug}-next"
          )
        end
      end

      def member_status_color(status)
        { active: :success, invited: :info }.fetch(status)
      end
    end
  end
end
