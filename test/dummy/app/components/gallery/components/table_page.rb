module Gallery
  module Components
    class TablePage < ComponentPage
      include Phlex::Rails::Helpers::Request
      include Phlex::Rails::Helpers::TurboFrameTag

      FRAME_ID = "gallery-table-results"
      FILTER_KEYS = %w[name_or_owner_cont status_eq s].freeze
      SORT_KEYS = %w[name owner status seats updated_at].freeze
      PER_PAGE = 5

      private

      def source_note
        "app/components/nitro_kit/table.rb"
      end

      def api_note
        "NitroKit::Table.new(sort:, direction:) { |table| table.thead { table.tr { table.th(\"Name\", sort: :name, href: \"?sort=name\") } } }"
      end

      def component_template
        example_section(
          "Semantic structure",
          slug: "table-structure",
          description: "Captions, column headers, row headers, and alignment remain explicit in Ruby and HTML."
        ) do
          example("Workspace members", slug: "table-workspace-members", mode: :full_width) do
            render NitroKit::Table.new(
              id: "gallery-table-members",
              table_html: { id: "gallery-table-members-element" }
            ) do |table|
              table.caption("Workspace members")
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
                    table.td(member.status.to_s.humanize, align: :right)
                  end
                end
              end
            end
          end
        end

        example_section(
          "Data and actions",
          slug: "table-actions",
          description: "Badges and compact actions compose inside cells without weakening table semantics."
        ) do
          example("Invoice history", slug: "table-invoice-history", mode: :full_width) do
            render NitroKit::Table.new(
              id: "gallery-table-invoices",
              table_html: { id: "gallery-table-invoices-element" }
            ) do |table|
              table.caption("Invoice history")
              table.thead do
                table.tr do
                  table.th("Invoice")
                  table.th("Issued")
                  table.th("Status")
                  table.th("Amount", align: :right)
                  table.th("Action", align: :right)
                end
              end
              table.tbody do
                Gallery::Data.invoices.each do |invoice|
                  table.tr do
                    table.th(invoice.number, scope: :row)
                    table.td(invoice.issued_on.iso8601)
                    table.td do
                      render NitroKit::Badge.new(
                        invoice.status.to_s.humanize,
                        id: "gallery-table-invoice-#{invoice.id}-status",
                        color: invoice_status_color(invoice.status),
                        size: :sm
                      )
                    end
                    table.td(format_amount(invoice), align: :right)
                    table.td(align: :right) do
                      render NitroKit::Button.new(
                        "View",
                        id: "gallery-table-invoice-#{invoice.id}-view",
                        href: "#invoice-#{invoice.id}",
                        size: :sm
                      )
                    end
                  end
                end
              end
            end
          end
        end

        example_section(
          "Alignment",
          slug: "table-alignment",
          description: "Headers and cells declare left, center, and right alignment independently."
        ) do
          example("All alignments", slug: "table-all-alignments", mode: :full_width) do
            render NitroKit::Table.new(
              id: "gallery-table-alignment",
              table_html: { id: "gallery-table-alignment-element" }
            ) do |table|
              table.caption("Deployment timing")
              table.thead do
                table.tr do
                  table.th("Environment", align: :left)
                  table.th("State", align: :center)
                  table.th("Duration", align: :right)
                end
              end
              table.tbody do
                table.tr do
                  table.th("Production", scope: :row, align: :left)
                  table.td("Operational", align: :center)
                  table.td("2m 14s", align: :right)
                end
                table.tr do
                  table.th("Staging", scope: :row, align: :left)
                  table.td("Queued", align: :center)
                  table.td("—", align: :right)
                end
              end
            end
          end
        end

        example_section(
          "Content pressure",
          slug: "table-pressure",
          description: "Long identifiers, multiline descriptions, dense records, status, and grouped actions stay semantic."
        ) do
          example("API credential inventory", slug: "table-api-credentials", mode: :full_width) do
            render NitroKit::Table.new(
              id: "gallery-table-credentials",
              table_html: { id: "gallery-table-credentials-element" }
            ) do |table|
              table.caption("API credential inventory")
              table.thead do
                table.tr do
                  table.th("Credential and identifier")
                  table.th("Access", align: :center)
                  table.th("Last used")
                  table.th("Actions", align: :right)
                end
              end
              table.tbody do
                Gallery::Data.api_keys.each do |api_key|
                  table.tr do
                    table.th(scope: :row) do
                      strong { api_key.name }
                      div { "#{api_key.prefix}••••••••••••••••" }
                    end
                    table.td(align: :center) do
                      render NitroKit::Badge.new(
                        api_key.access.to_s.humanize,
                        id: "gallery-table-credential-#{api_key.id}-access",
                        variant: :outline,
                        color: :info,
                        size: :sm
                      )
                    end
                    table.td(api_key.last_used_at&.iso8601 || "Never used")
                    table.td(align: :right) do
                      render NitroKit::ButtonGroup.new(
                        id: "gallery-table-credential-#{api_key.id}-actions",
                        label: "Actions for #{api_key.name} credential"
                      ) do |group|
                        group.button(
                          "Rotate",
                          id: "gallery-table-credential-#{api_key.id}-rotate",
                          size: :sm,
                        )
                        group.button(
                          "Revoke",
                          id: "gallery-table-credential-#{api_key.id}-revoke",
                          size: :sm,
                          variant: :destructive
                        )
                      end
                    end
                  end
                end
              end
            end
          end

          example("Integration descriptions", slug: "table-integration-descriptions", mode: :full_width) do
            render NitroKit::Table.new(
              id: "gallery-table-integrations",
              table_html: { id: "gallery-table-integrations-element" }
            ) do |table|
              table.caption("Integration delivery and connection status")
              table.thead do
                table.tr do
                  table.th("Integration")
                  table.th("Purpose and delivery behavior")
                  table.th("Status", align: :right)
                end
              end
              table.tbody do
                Gallery::Data.integrations.each do |integration|
                  table.tr do
                    table.th(integration.name, scope: :row)
                    table.td(integration.description)
                    table.td(align: :right) do
                      render NitroKit::Badge.new(
                        integration.status.to_s.humanize,
                        id: "gallery-table-integration-#{integration.id}-status",
                        color: integration_status_color(integration.status),
                        size: :sm
                      )
                    end
                  end
                end
              end
            end
          end
        end

        example_section(
          "Constrained width",
          slug: "table-constrained",
          description: "A table wider than its container scrolls horizontally inside a focusable region named by its caption."
        ) do
          example("Invoices in a small container", slug: "table-constrained-invoices", mode: :full_width) do
            render NitroKit::Container.new(size: :sm, id: "gallery-table-constrained-container") do
              render NitroKit::Table.new(id: "gallery-table-constrained") do |table|
                table.caption("Invoice history in a constrained container")
                table.thead do
                  table.tr do
                    table.th("Invoice")
                    table.th("Issued")
                    table.th("Status")
                    table.th("Amount", align: :right)
                    table.th("Action", align: :right)
                  end
                end
                table.tbody do
                  Gallery::Data.invoices.each do |invoice|
                    table.tr do
                      table.th(invoice.number, scope: :row)
                      table.td(invoice.issued_on.iso8601)
                      table.td(invoice.status.to_s.humanize)
                      table.td(format_amount(invoice), align: :right)
                      table.td("View", align: :right)
                    end
                  end
                end
              end
            end
          end
        end

        example_section(
          "Empty state",
          slug: "table-empty",
          description: "An empty collection remains a valid table with a caption, headers, and one spanning message."
        ) do
          example("No API keys", slug: "table-no-api-keys", mode: :full_width) do
            render NitroKit::Table.new(
              id: "gallery-table-empty",
              table_html: { id: "gallery-table-empty-element" }
            ) do |table|
              table.caption("API credentials")
              table.thead do
                table.tr do
                  table.th("Name")
                  table.th("Access")
                  table.th("Last used", align: :right)
                end
              end
              table.tbody do
                table.tr do
                  table.td(
                    "No API credentials have been created.",
                    html: { colspan: 3 }
                  )
                end
              end
            end
          end
        end

        example_section(
          "Sort state",
          slug: "table-sort-state",
          description: "Only the active column owns native aria-sort and a direction indicator. Sortable but unsorted columns stay neutral with aria-sort=\"none\"."
        ) do
          example("Ascending, descending, and unsorted", slug: "table-sort-directions", layout: :matrix, mode: :full_width) do
            sample("Ascending", slug: "table-sort-ascending") do
              render_sort_state_table(sort: :name, direction: :asc, id: "gallery-table-sort-ascending")
            end
            sample("Descending", slug: "table-sort-descending") do
              render_sort_state_table(sort: :seats, direction: :desc, id: "gallery-table-sort-descending")
            end
            sample("Unsorted", slug: "table-sort-unsorted") do
              render_sort_state_table(sort: nil, direction: nil, id: "gallery-table-sort-unsorted")
            end
          end

          example("Inventory", slug: "table-sort-inventory", mode: :full_width) do
            render NitroKit::Table.new(
              sort: :owner,
              direction: :asc,
              id: "gallery-table-sort-inventory"
            ) do |table|
              table.caption("Workspace inventory ordered by owner")
              table.thead do
                table.tr do
                  table.th("Workspace", sort: :name, href: "?sort=name-asc")
                  table.th(sort: :owner, href: "?sort=owner-desc")
                  table.th(sort: :status, href: "?sort=status-asc")
                  table.th(sort: :seats, href: "?sort=seats-asc", align: :right)
                end
              end
              table.tbody do
                Gallery::CatalogItem::EXAMPLES.first(4).each do |item|
                  table.tr do
                    table.th(item.fetch(:name), scope: :row)
                    table.td(item.fetch(:owner))
                    table.td { render_catalog_status(item.fetch(:status)) }
                    table.td(item.fetch(:seats).to_s, align: :right)
                  end
                end
              end
            end
          end
        end

        example_section(
          "Optional Ransack recipe",
          slug: "table-ransack",
          description: "This dummy application adapts a real Ransack::Search to Nitro sort links. Filtering, allowlists, and pagination remain application code."
        ) do
          example(
            "Workspace catalog",
            slug: "table-ransack-catalog",
            mode: :full_width,
            code: Gallery::SourceCode.from_method(method(:render_ransack_recipe))
          ) do
            render_ransack_recipe
          end
        end
      end

      def render_sort_state_table(sort:, direction:, id:)
        render NitroKit::Table.new(sort:, direction:, id:) do |table|
          table.thead do
            table.tr do
              table.th(sort: :name, href: "?sort=name-asc")
              table.th(sort: :seats, href: "?sort=seats-asc", align: :right)
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

        turbo_frame_tag(FRAME_ID, data: { turbo_action: "advance" }) do
          render NitroKit::Flex.new(dir: :col, gap: 6, align: :stretch, id: "gallery-table-recipe") do
            render_filter_form(sort)
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
          id: "gallery-table-filter",
          data: {
            turbo_frame: FRAME_ID,
            turbo_action: "replace"
          }
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

          render NitroKit::Toolbar.new(id: "gallery-table-filter-actions") do |toolbar|
            toolbar.trailing do
              render NitroKit::Button.new(
                "Reset",
                href: entry_path(entry),
                data: {
                  turbo_frame: FRAME_ID,
                  turbo_action: "replace"
                }
              )
              form.submit("Apply filters", id: "gallery-table-filter-submit")
            end
          end
        end
      end

      def render_results_table(records, sort)
        render NitroKit::Table.new(
          sort: sort.current,
          direction: sort.direction,
          id: "gallery-table-ransack-results"
        ) do |table|
          table.caption("Filtered workspace catalog")
          table.thead do
            table.tr do
              table.th(
                "Workspace",
                sort: :name,
                href: sort.href_for(:name),
                sort_data: { turbo_action: "replace" }
              )
              table.th(
                sort: :owner,
                href: sort.href_for(:owner),
                sort_data: { turbo_action: "replace" }
              )
              table.th(
                sort: :status,
                href: sort.href_for(:status),
                sort_data: { turbo_action: "replace" }
              )
              table.th(
                sort: :seats,
                href: sort.href_for(:seats),
                align: :right,
                sort_data: { turbo_action: "replace" }
              )
              table.th(
                "Updated",
                sort: :updated_at,
                href: sort.href_for(:updated_at),
                align: :right,
                sort_data: { turbo_action: "replace" }
              )
            end
          end
          table.tbody do
            if records.any?
              records.each { |record| render_catalog_row(table, record) }
            else
              table.tr do
                table.td("No workspaces match these filters. Reset or broaden the search.", html: { colspan: 5 })
              end
            end
          end
        end
      end

      def render_catalog_row(table, record)
        table.tr(data: { gallery_catalog_row: record.sku }) do
          table.th(scope: :row) do
            strong { record.name }
            div { record.sku }
          end
          table.td(record.owner)
          table.td { render_catalog_status(record.status) }
          table.td(record.seats.to_s, align: :right)
          table.td(record.updated_at.to_date.iso8601, align: :right)
        end
      end

      def render_results_pagination(page:, total_count:, sort:)
        total_pages = [ (total_count.to_f / PER_PAGE).ceil, 1 ].max
        first_record = total_count.zero? ? 0 : ((page - 1) * PER_PAGE) + 1
        last_record = [ page * PER_PAGE, total_count ].min

        render NitroKit::PaginationBar.new(id: "gallery-table-pagination-bar") do |bar|
          bar.summary("Showing #{first_record}–#{last_record} of #{total_count} workspaces")
          bar.pagination(
            NitroKit::Pagination.new(id: "gallery-table-pagination", label: "Workspace catalog pages")
          ) do |pagination|
            pagination.prev(href: page > 1 ? page_href(page - 1, sort) : nil)
            (1..total_pages).each do |number|
              pagination.page(number, href: number == page ? nil : page_href(number, sort), current: number == page)
            end
            pagination.next(href: page < total_pages ? page_href(page + 1, sort) : nil)
          end
        end
      end

      def render_catalog_status(status)
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

      def invoice_status_color(status)
        { paid: :success, refunded: :warning }.fetch(status)
      end

      def integration_status_color(status)
        { connected: :success, action_required: :warning, available: :neutral }.fetch(status)
      end

      def format_amount(invoice)
        amount = invoice.amount_cents.fdiv(100)
        "#{invoice.currency} #{Kernel.format("%.2f", amount)}"
      end
    end
  end
end
