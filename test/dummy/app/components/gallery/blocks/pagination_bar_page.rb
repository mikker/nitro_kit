module Gallery
  module Blocks
    class PaginationBarPage < ComponentPage
      private

      def source_note
        "app/components/nitro_kit/pagination_bar.rb"
      end

      def api_note
        "NitroKit::PaginationBar.new { |bar| bar.summary(...); bar.pagination(NitroKit::Pagination.new(...)) { |pagination| ... } }"
      end

      def component_template
        example_section(
          "Page boundaries",
          slug: "pagination-bar-boundaries",
          description: "Caller-owned summaries pair with typed Pagination at first, middle, and final page boundaries."
        ) do
          example("First, middle, and final", slug: "pagination-bar-page-states", layout: :matrix, mode: :full_width) do
            sample("First page", slug: "first") do
              render_boundary_bar("first", current: 1, total: 12, range: "1–25", previous: nil, following: 2)
            end
            sample("Middle page", slug: "middle") do
              render_boundary_bar("middle", current: 6, total: 12, range: "126–150", previous: 5, following: 7)
            end
            sample("Final page", slug: "final") do
              render_boundary_bar("final", current: 12, total: 12, range: "276–287", previous: 11, following: nil)
            end
          end
        end

        example_section(
          "Optional summary",
          slug: "pagination-bar-summary",
          description: "The summary may be omitted; when declared it accepts caller text or direct Phlex content."
        ) do
          example("Absent and rich summary", slug: "pagination-bar-summary-states", layout: :matrix, mode: :full_width) do
            sample("No summary", slug: "none") do
              render NitroKit::PaginationBar.new(id: "gallery-pagination-bar-no-summary") do |bar|
                bar.pagination(NitroKit::Pagination.new(label: "Compact pages")) do |pagination|
                  pagination.prev
                  pagination.page(1, current: true)
                  pagination.page(2, href: "?page=2")
                  pagination.next(href: "?page=2")
                end
              end
            end
            sample("Phlex summary", slug: "phlex") do
              render NitroKit::PaginationBar.new(id: "gallery-pagination-bar-rich-summary") do |bar|
                bar.summary do
                  plain("Showing 26–50 of 418 invoices ")
                  render NitroKit::Badge.new(
                    "Filtered",
                    id: "gallery-pagination-bar-rich-summary-badge",
                    size: :sm,
                    variant: :outline
                  )
                end
                bar.pagination(NitroKit::Pagination.new(label: "Filtered invoice pages")) do |pagination|
                  pagination.prev(href: "?status=paid&page=1")
                  pagination.page(2, current: true)
                  pagination.next(href: "?status=paid&page=3")
                end
              end
            end
          end
        end

        example_section(
          "Query and content pressure",
          slug: "pagination-bar-pressure",
          description: "Long summaries, omitted ranges, and preserved filter parameters stay outside the block's responsibilities."
        ) do
          example("Filtered directory", slug: "pagination-bar-filtered", mode: :full_width) do
            render NitroKit::PaginationBar.new(id: "gallery-pagination-bar-filtered") do |bar|
              bar.summary(
                "Showing users 201–225 of 4,892 matching “international research and production administrators” " \
                  "with active security-key enrollment",
                html: { id: "gallery-pagination-bar-filtered-summary" },
                aria: { live: "polite" }
              )
              bar.pagination(NitroKit::Pagination.new(label: "Filtered workspace user pages")) do |pagination|
                pagination.prev(href: "?query=research&status=active&page=8")
                pagination.page(1, href: "?query=research&status=active&page=1")
                pagination.ellipsis(label: "Pages 2 through 7 omitted")
                pagination.page(8, href: "?query=research&status=active&page=8")
                pagination.page(9, current: true)
                pagination.page(10, href: "?query=research&status=active&page=10")
                pagination.ellipsis(label: "Pages 11 through 195 omitted")
                pagination.page(196, href: "?query=research&status=active&page=196")
                pagination.next(href: "?query=research&status=active&page=10")
              end
            end
          end

          example("Twelve visible pages", slug: "pagination-bar-dense", mode: :full_width, density: :compact) do
            render NitroKit::PaginationBar.new(id: "gallery-pagination-bar-dense") do |bar|
              bar.summary("Page 6 of 12 · 287 records")
              bar.pagination(NitroKit::Pagination.new(label: "Dense record pages")) do |pagination|
                pagination.prev(href: "?page=5")
                12.times do |index|
                  page = index + 1
                  pagination.page(page, href: "?page=#{page}", current: page == 6)
                end
                pagination.next(href: "?page=7")
              end
            end
          end
        end

        example_section(
          "Collection composition",
          slug: "pagination-bar-collection",
          description: "Table data, captions, counts, and links remain caller-owned around the placement block."
        ) do
          example("Invoice history", slug: "pagination-bar-invoices", mode: :full_width) do
            render NitroKit::Card.new(id: "gallery-pagination-bar-invoices-card") do |card|
              card.title("Invoice history", level: 4)
              card.body do
                render NitroKit::Table.new(id: "gallery-pagination-bar-invoices-table") do |table|
                  table.caption("Recent workspace invoices")
                  table.thead do
                    table.tr do
                      table.th("Invoice")
                      table.th("Status")
                      table.th("Amount", align: :right)
                    end
                  end
                  table.tbody do
                    Gallery::Data.invoices.each do |invoice|
                      table.tr do
                        table.th(invoice.number, scope: :row)
                        table.td { render NitroKit::Badge.new(invoice.status.to_s.humanize, size: :sm) }
                        table.td("$#{invoice.amount_cents / 100}.00", align: :right)
                      end
                    end
                  end
                end
                render NitroKit::PaginationBar.new(id: "gallery-pagination-bar-invoices") do |bar|
                  bar.summary("Showing the three most recent of 36 invoices")
                  bar.pagination(NitroKit::Pagination.new(label: "Invoice history pages")) do |pagination|
                    pagination.prev(href: "?page=11")
                    pagination.page(1, href: "?page=1")
                    pagination.ellipsis(label: "Pages 2 through 10 omitted")
                    pagination.page(11, href: "?page=11")
                    pagination.page(12, current: true)
                    pagination.next
                  end
                end
              end
            end
          end
        end
      end

      def render_boundary_bar(slug, current:, total:, range:, previous:, following:)
        render NitroKit::PaginationBar.new(id: "gallery-pagination-bar-#{slug}") do |bar|
          bar.summary("Showing records #{range} of 287")
          bar.pagination(
            NitroKit::Pagination.new(
              id: "gallery-pagination-bar-#{slug}-pagination",
              label: "#{slug.humanize} boundary pages"
            )
          ) do |pagination|
            pagination.prev(href: previous && "?page=#{previous}", id: "gallery-pagination-bar-#{slug}-previous")
            [ 1, current, total ].uniq.each do |page|
              pagination.page(
                page,
                href: "?page=#{page}",
                current: page == current,
                id: "gallery-pagination-bar-#{slug}-page-#{page}"
              )
            end
            pagination.next(href: following && "?page=#{following}", id: "gallery-pagination-bar-#{slug}-next")
          end
        end
      end
    end
  end
end
