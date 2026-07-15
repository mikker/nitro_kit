module Gallery
  module Components
    class SortableTablePage < ComponentPage
      include Phlex::Rails::Helpers::Request
      include Phlex::Rails::Helpers::TurboFrameTag

      FRAME_ID = "gallery-sortable-table-results"
      FILTER_KEYS = %w[name_or_owner_cont status_eq s].freeze
      SORT_KEYS = %w[name owner status seats updated_at].freeze
      PER_PAGE = 5

      private

      def source_note
        "app/components/nitro_kit/sortable_table.rb"
      end

      def api_note
        "NitroKit::SortableTable.new(current:, direction:) { |table| table.sortable_th(key, label, href:, align:) }"
      end

      def component_template
        example_section(
          "Sort state",
          slug: "sortable-table-state",
          description: "Only the active column owns native aria-sort and a visible direction indicator. Unsorted tables stay neutral."
        ) do
          example("Ascending, descending, and unsorted", slug: "sortable-table-directions", layout: :matrix, mode: :full_width) do
            sample("Ascending", slug: "sortable-table-ascending") do
              render_state_table(current: :name, direction: :asc, id: "gallery-sortable-table-ascending")
            end
            sample("Descending", slug: "sortable-table-descending") do
              render_state_table(current: :seats, direction: :desc, id: "gallery-sortable-table-descending")
            end
            sample("Unsorted", slug: "sortable-table-unsorted") do
              render_state_table(current: nil, direction: nil, id: "gallery-sortable-table-unsorted")
            end
          end
        end

        example_section(
          "Application-owned policy",
          slug: "sortable-table-policy",
          description: "The application supplies every URL and may use ordinary params, Ransack, or another query object without changing the component."
        ) do
          example("Inventory", slug: "sortable-table-inventory", mode: :full_width) do
            render NitroKit::SortableTable.new(
              current: :owner,
              direction: :asc,
              id: "gallery-sortable-table-inventory"
            ) do |table|
              table.caption("Workspace inventory ordered by owner")
              table.thead do
                table.tr do
                  table.sortable_th(:name, "Workspace", href: "?sort=name-asc")
                  table.sortable_th(:owner, href: "?sort=owner-desc")
                  table.sortable_th(:status, href: "?sort=status-asc")
                  table.sortable_th(:seats, href: "?sort=seats-asc", align: :right)
                end
              end
              table.tbody do
                Gallery::CatalogItem::EXAMPLES.first(4).each do |item|
                  table.tr do
                    table.th(item.fetch(:name), scope: :row)
                    table.td(item.fetch(:owner))
                    table.td { render_status(item.fetch(:status)) }
                    table.td(item.fetch(:seats).to_s, align: :right)
                  end
                end
              end
            end
          end

          example("No matching rows", slug: "sortable-table-empty", mode: :full_width) do
            render NitroKit::SortableTable.new(id: "gallery-sortable-table-empty") do |table|
              table.caption("No workspaces match the current filters")
              table.thead do
                table.tr do
                  table.sortable_th(:name, "Workspace", href: "?sort=name-asc")
                  table.sortable_th(:owner, href: "?sort=owner-asc")
                  table.sortable_th(:seats, href: "?sort=seats-asc", align: :right)
                end
              end
              table.tbody do
                table.tr do
                  table.td("Try a different name, owner, or status.", html: { colspan: 3 })
                end
              end
            end
          end
        end

        example_section(
          "Optional Ransack recipe",
          slug: "sortable-table-ransack",
          description: "This dummy application adapts a real Ransack::Search to Nitro links. Filtering, allowlists, and pagination remain application code. The native bulk controls intentionally do not submit; applications wire authorization and mutations themselves."
        ) do
          example(
            "Workspace catalog",
            slug: "sortable-table-ransack-catalog",
            mode: :full_width,
            code: Gallery::SourceCode.from_method(method(:render_ransack_recipe))
          ) do
            render_ransack_recipe
          end
        end
      end

      def render_state_table(current:, direction:, id:)
        render NitroKit::SortableTable.new(current:, direction:, id:) do |table|
          table.thead do
            table.tr do
              table.sortable_th(:name, href: "?sort=name-asc")
              table.sortable_th(:seats, href: "?sort=seats-asc", align: :right)
            end
          end
          table.tbody do
            table.tr do
              table.th("Atlas Workspace", scope: :row)
              table.td("42", align: :right)
            end
          end
        end
      end

      def render_ransack_recipe
        search = Gallery::CatalogItem.ransack(ransack_parameters)
        search.sorts = "name asc" if search.sorts.empty?
        sort = Gallery::RansackSort.new(search, path: entry_path(entry), filters: ransack_parameters.except("s"))
        relation = search.result(distinct: true)
        total_count = relation.count
        page = current_page(total_count)
        records = relation.offset((page - 1) * PER_PAGE).limit(PER_PAGE)

        turbo_frame_tag(FRAME_ID) do
          render NitroKit::Flex.new(dir: :col, gap: 6, align: :stretch, id: "gallery-sortable-table-recipe") do
            render_filter_form(sort)
            render_bulk_toolbar(records)
            render_results_table(records, sort)
            render_results_pagination(page:, total_count:, sort:)
          end
        end
      end

      def render_filter_form(sort)
        form_with(
          scope: :q,
          url: entry_path(entry),
          method: :get,
          builder: NitroKit::FormBuilder,
          id: "gallery-sortable-table-filter",
          data: { turbo_frame: FRAME_ID }
        ) do |form|
          form.hidden_field(:s, value: sort.parameters.fetch("s"))
          form.group do
            form.field(
              :name_or_owner_cont,
              as: :search,
              label: "Search workspaces",
              value: ransack_parameters["name_or_owner_cont"],
              placeholder: "Workspace or owner",
              autocomplete: "off"
            )
            form.field(
              :status_eq,
              as: :select,
              label: "Status",
              value: ransack_parameters["status_eq"],
              include_blank: "All statuses",
              options: Gallery::CatalogItem::STATUSES.map { |status| [ status.humanize, status ] }
            )
          end

          render NitroKit::Toolbar.new(id: "gallery-sortable-table-filter-actions") do |toolbar|
            toolbar.trailing do
              render NitroKit::Button.new(
                "Reset",
                href: entry_path(entry),
                data: { turbo_frame: FRAME_ID }
              )
              form.submit("Apply filters", id: "gallery-sortable-table-filter-submit")
            end
          end
        end
      end

      def render_bulk_toolbar(records)
        render NitroKit::Toolbar.new(id: "gallery-sortable-table-bulk-actions") do |toolbar|
          toolbar.leading do
            render NitroKit::Checkbox.new(
              label: "Select all #{records.size} visible rows",
              id: "gallery-sortable-table-select-all",
              include_hidden: false
            )
          end
          toolbar.trailing do
            render NitroKit::Button.new("Archive selection", type: :button)
            render NitroKit::Button.new("Export selection", type: :button)
          end
        end
      end

      def render_results_table(records, sort)
        render NitroKit::SortableTable.new(
          current: sort.current,
          direction: sort.direction,
          id: "gallery-sortable-table-ransack-results"
        ) do |table|
          table.caption("Filtered workspace catalog")
          table.thead do
            table.tr do
              table.th("Select")
              table.sortable_th(:name, "Workspace", href: sort.href_for(:name))
              table.sortable_th(:owner, href: sort.href_for(:owner))
              table.sortable_th(:status, href: sort.href_for(:status))
              table.sortable_th(:seats, href: sort.href_for(:seats), align: :right)
              table.sortable_th(:updated_at, "Updated", href: sort.href_for(:updated_at), align: :right)
            end
          end
          table.tbody do
            if records.any?
              records.each { |record| render_record_row(table, record) }
            else
              table.tr do
                table.td("No workspaces match these filters. Reset or broaden the search.", html: { colspan: 6 })
              end
            end
          end
        end
      end

      def render_record_row(table, record)
        table.tr(data: { gallery_catalog_row: record.sku }) do
          table.td do
            render NitroKit::Checkbox.new(
              id: "gallery-sortable-table-select-#{record.id}",
              name: "selection[]",
              value: record.id,
              include_hidden: false,
              control_aria: { label: "Select #{record.name}" }
            )
          end
          table.th(scope: :row) do
            strong { record.name }
            div { record.sku }
          end
          table.td(record.owner)
          table.td { render_status(record.status) }
          table.td(record.seats.to_s, align: :right)
          table.td(record.updated_at.to_date.iso8601, align: :right)
        end
      end

      def render_results_pagination(page:, total_count:, sort:)
        total_pages = [ (total_count.to_f / PER_PAGE).ceil, 1 ].max
        first_record = total_count.zero? ? 0 : ((page - 1) * PER_PAGE) + 1
        last_record = [ page * PER_PAGE, total_count ].min

        render NitroKit::PaginationBar.new(id: "gallery-sortable-table-pagination-bar") do |bar|
          bar.summary("Showing #{first_record}–#{last_record} of #{total_count} workspaces", aria: { live: "polite" })
          bar.pagination(
            NitroKit::Pagination.new(id: "gallery-sortable-table-pagination", label: "Workspace catalog pages")
          ) do |pagination|
            pagination.prev(href: page > 1 ? page_href(page - 1, sort) : nil)
            (1..total_pages).each do |number|
              pagination.page(number, href: number == page ? nil : page_href(number, sort), current: number == page)
            end
            pagination.next(href: page < total_pages ? page_href(page + 1, sort) : nil)
          end
        end
      end

      def render_status(status)
        render NitroKit::Badge.new(
          status.humanize,
          color: { "active" => :success, "trial" => :info, "paused" => :warning, "archived" => :neutral }.fetch(status),
          size: :sm
        )
      end

      def ransack_parameters
        @ransack_parameters ||= begin
          raw = request.query_parameters["q"]
          raw = raw.to_unsafe_h if raw.respond_to?(:to_unsafe_h)
          raw = {} unless raw.is_a?(Hash)

          raw.stringify_keys.slice(*FILTER_KEYS).filter_map do |key, value|
            next unless value.is_a?(String)
            next if key == "s" && !value.match?(/\A(?:#{SORT_KEYS.join("|")}) (?:asc|desc)\z/)
            next if key == "status_eq" && value.present? && !Gallery::CatalogItem::STATUSES.include?(value)

            [ key, value.first(120) ]
          end.to_h
        end
      end

      def current_page(total_count)
        requested = request.query_parameters["page"].to_i
        requested = 1 if requested < 1
        total_pages = [ (total_count.to_f / PER_PAGE).ceil, 1 ].max
        [ requested, total_pages ].min
      end

      def page_href(page, sort)
        query = Rack::Utils.build_nested_query(q: sort.parameters, page:)
        "#{entry_path(entry)}?#{query}"
      end
    end
  end
end
