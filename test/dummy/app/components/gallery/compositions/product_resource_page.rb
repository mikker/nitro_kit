module Gallery
  module Compositions
    class ProductResourcePage < ScenarioPage
      include Phlex::Rails::Helpers::FormWith
      include Phlex::Rails::Helpers::Request
      include Phlex::Rails::Helpers::TurboFrameTag

      QUERY_FRAME_ID = "gallery-product-resource-query"
      PRODUCT_FORM_ID = "gallery-product-resource-form"
      INDEX_STATES = %w[index filtered empty paginated narrow].freeze
      FORM_STATES = %w[new new-validation edit edit-validation].freeze
      DETAIL_STATES = %w[active archived].freeze

      private

      def render_scenario
        render NitroKit::AppShell.new(
          id: "gallery-product-resource-shell",
          layout: :hybrid,
          data: {
            gallery: "composition-surface",
            gallery_shell_preview: "true",
            gallery_composition: "product-resource",
            gallery_composition_state: state,
            gallery_mobile: state == "narrow" ? "true" : nil
          }.compact
        ) do |shell|
          shell.brand { strong { "Northstar" } }
          shell.navigation { render_product_navigation }
          shell.topbar { render_product_toolbar }
          shell.main do
            div(data: { gallery: "product-resource-main" }) do
              render NitroKit::Flex.new(
                dir: :col,
                gap: 6,
                align: :stretch,
                id: "gallery-product-resource-stack"
              ) do
                render_product_state
              end
            end
          end
        end
      end

      def render_product_navigation
        render NitroKit::AppNavigation.new(
          id: "gallery-product-resource-navigation",
          label: "Northstar administration"
        ) do |navigation|
          navigation.body do
            navigation.section(label: "Catalog") do
              navigation.item("Overview", href: "#overview", icon: :house)
              navigation.item("Products", href: flow_path(state: "index"), icon: :package, current: true)
              navigation.item("Collections", href: "#collections", icon: :layers)
            end
            navigation.section(label: "Operations") do
              navigation.item("Orders", href: "#orders", icon: :shopping_cart)
              navigation.item("Inventory", href: "#inventory", icon: :warehouse)
            end
            navigation.spacer
            navigation.item("Settings", href: "#settings", icon: :settings)
          end
        end
      end

      def render_product_toolbar
        render NitroKit::Toolbar.new(id: "gallery-product-resource-toolbar") do |toolbar|
          toolbar.leading do
            render_back_button if child_state?
            h1 { route_title }
          end
          toolbar.trailing { render_toolbar_actions }
        end
      end

      def render_back_button
        render NitroKit::Button.new(
          href: back_path,
          icon: :arrow_left,
          label: back_label,
          size: :sm,
          variant: :ghost,
          id: "gallery-product-resource-back"
        )
      end

      def render_toolbar_actions
        if FORM_STATES.include?(state)
          render NitroKit::Button.new(
            state.start_with?("new") ? "Create product" : "Save product",
            type: :submit,
            form: PRODUCT_FORM_ID,
            variant: :primary,
            id: "gallery-product-resource-save",
            disabled: true,
            data: { turbo_submits_with: "Saving…" }
          )
        elsif INDEX_STATES.include?(state)
          render NitroKit::Button.new(
            "New",
            href: flow_path(state: "new"),
            variant: :primary,
            id: "gallery-product-resource-new"
          )
        else
          render NitroKit::ButtonGroup.new(
            label: "Product actions",
            id: "gallery-product-resource-toolbar-actions"
          ) do |actions|
            product_id = selected_product.id
            actions.button("History", href: flow_path(state: "history", product_id:)) unless state == "history"
            actions.button("Edit product", href: flow_path(state: "edit", product_id:), variant: :primary)
          end
        end
      end

      def render_product_state
        if INDEX_STATES.include?(state)
          render_query_region
        elsif FORM_STATES.include?(state)
          render_product_form
          render_delete_product if state.start_with?("edit")
        elsif DETAIL_STATES.include?(state)
          render_product_detail
        elsif state == "history"
          render_lifecycle_history(selected_product, full: true)
        end
      end

      def render_query_region
        turbo_frame_tag(
          QUERY_FRAME_ID,
          data: { turbo_action: "advance" }
        ) do
          render NitroKit::Flex.new(
            dir: :col,
            gap: 6,
            align: :stretch,
            id: "gallery-product-resource-query-stack"
          ) do
            render_product_filters
            render_product_results
            render_product_pagination if paginated_results?
          end
        end
      end

      def render_product_filters
        form_with(
          scope: :q,
          url: flow_path(state: "filtered"),
          method: :get,
          builder: NitroKit::FormBuilder,
          id: "gallery-product-resource-filters",
          data: {
            turbo_frame: QUERY_FRAME_ID,
            turbo_action: "replace"
          }
        ) do |form|
          form.hidden_field(:sort, value: current_sort)
          render NitroKit::Grid.new(cols: "1 md:3", gap: 3, id: "gallery-product-resource-filter-grid") do
            form.field(
              :query,
              as: :search,
              label: "Search products",
              value: filter_values[:query],
              placeholder: "Name, SKU, or description",
              autocomplete: "off",
              id: "gallery-product-resource-filter-query"
            )
            form.field(
              :status,
              as: :select,
              label: "Status",
              value: filter_values[:status],
              options: [ [ "Active", "active" ], [ "Archived", "archived" ] ],
              include_blank: "All statuses",
              id: "gallery-product-resource-filter-status"
            )
            render NitroKit::Flex.new(
              dir: :row,
              gap: 2,
              align: :end,
              justify: :end,
              wrap: :wrap,
              id: "gallery-product-resource-filter-actions"
            ) do
              render NitroKit::Button.new(
                "Reset",
                href: flow_path(state: "index"),
                data: {
                  turbo_frame: QUERY_FRAME_ID,
                  turbo_action: "replace"
                }
              )
              form.submit(
                "Apply filters",
                id: "gallery-product-resource-filter-submit",
                data: { turbo_submits_with: "Filtering…" }
              )
            end
          end
        end
      end

      def render_product_results
        render NitroKit::DataSection.new(
          title: "Product catalog",
          description: results_description,
          id: "gallery-product-resource-results"
        ) do |section|
          if products.empty?
            section.empty_state NitroKit::EmptyState.new(
              title: "No products match these filters",
              description: "Reset the query or create the first product for this catalog.",
              level: 3,
              id: "gallery-product-resource-empty"
            ) do |empty|
              empty.icon NitroKit::Icon.new(:package_search)
              empty.action NitroKit::Button.new(
                "Reset filters",
                href: flow_path(state: "index"),
                data: {
                  turbo_frame: QUERY_FRAME_ID,
                  turbo_action: "replace"
                }
              )
              empty.action NitroKit::Button.new(
                "New product",
                href: flow_path(state: "new"),
                variant: :primary,
                data: { turbo_frame: "_top" }
              )
            end
          else
            section.table NitroKit::Table.new(
              sort: current_sort,
              direction: current_direction,
              id: "gallery-product-resource-table",
              table_aria: { label: "Northstar products" }
            ) do |table|
              table.caption("Products in Northstar Commerce")
              table.thead do
                table.tr do
                  table.th(
                    "Product",
                    sort: :name,
                    href: sort_path(:name),
                    sort_data: { turbo_action: "replace" }
                  )
                  table.th("Status")
                  table.th(
                    "Price",
                    align: :right,
                    sort: :price,
                    href: sort_path(:price),
                    sort_data: { turbo_action: "replace" }
                  )
                  table.th(
                    "Updated",
                    sort: :updated_at,
                    href: sort_path(:updated_at),
                    sort_data: { turbo_action: "replace" }
                  )
                  table.th("Actions", align: :right)
                end
              end
              table.tbody do
                products.each { |product| render_product_row(table, product) }
              end
            end
          end
        end
      end

      def render_product_row(table, product)
        table.tr do
          table.th(scope: :row) do
            strong { product.name }
            small { product.sku }
          end
          table.td do
            render NitroKit::Badge.new(
              product.status.to_s.humanize,
              color: product_status_color(product.status),
              size: :sm
            )
          end
          table.td(money(product.price_cents), align: :right)
          table.td(product.updated_at.to_fs(:short))
          table.td(align: :right) do
            render NitroKit::ButtonGroup.new(label: "Actions for #{product.name}") do |actions|
              actions.button(
                "View",
                href: flow_path(
                  state: product.status == :archived ? "archived" : "active",
                  product_id: product.id
                ),
                size: :sm,
                data: { turbo_frame: "_top" }
              )
              actions.button(
                "Edit",
                href: flow_path(state: "edit", product_id: product.id),
                size: :sm,
                data: { turbo_frame: "_top" }
              )
            end
          end
        end
      end

      def render_product_pagination
        current_page = state == "paginated" ? 2 : 1

        render NitroKit::PaginationBar.new(id: "gallery-product-resource-pagination-bar") do |bar|
          bar.summary("Showing #{products.length} of #{Gallery::ProductData.products.length} products")
          bar.pagination(
            NitroKit::Pagination.new(
              id: "gallery-product-resource-pagination",
              label: "Product pages"
            )
          ) do |pagination|
            pagination.prev(href: current_page == 2 ? page_path(1) : nil)
            pagination.page(1, href: current_page == 2 ? page_path(1) : nil, current: current_page == 1)
            pagination.page(2, href: current_page == 1 ? page_path(2) : nil, current: current_page == 2)
            pagination.next(href: current_page == 1 ? page_path(2) : nil)
          end
        end
      end

      def render_product_form
        form = product_form

        render NitroKit::SettingsSection.new(
          title: state.start_with?("new") ? "Product details" : "Edit product details",
          description: "Keep catalog identity, price, inventory, status, and customer-facing details current.",
          id: "gallery-product-resource-settings-section"
        ) do |section|
          if validation_state?
            section.status NitroKit::Alert.new(
              id: "gallery-product-resource-form-error",
              variant: :destructive,
              live: :assertive
            ) do |alert|
              alert.title("Product details need attention")
              alert.description(form.errors.full_messages.to_sentence)
            end
          end
          section.form do
            form_with(
              model: form,
              scope: :product,
              url: "#product-form-demo",
              method: state.start_with?("edit") ? :patch : :post,
              builder: NitroKit::FormBuilder,
              id: PRODUCT_FORM_ID
            ) do |builder|
              builder.group do
                builder.field(:name, required: true)
                builder.field(
                  :sku,
                  label: "SKU",
                  required: true,
                  pattern: "[A-Z]{3}-[0-9]{3}",
                  description: "Three uppercase letters, a hyphen, and three digits."
                )
                builder.field(
                  :status,
                  as: :select,
                  options: Gallery::Forms::Product::STATUSES.map { |status| [ status.humanize, status ] },
                  required: true
                )
                builder.field(:price, as: :number, min: 0, step: 0.01, required: true)
                builder.field(
                  :inventory_count,
                  as: :number,
                  label: "Available inventory",
                  min: 0,
                  step: 1,
                  required: true
                )
                builder.field(
                  :description,
                  as: :textarea,
                  rows: 4,
                  maxlength: 240,
                  required: true
                )
              end
            end
          end
        end
      end

      def render_delete_product
        product = selected_product

        render NitroKit::DangerZone.new(
          title: "Delete #{product.name}",
          description: "Deletion permanently removes this product after the application verifies authorization and dependent orders.",
          id: "gallery-product-resource-danger-zone"
        ) do |zone|
          zone.confirmation do
            render NitroKit::Dialog.new(id: "gallery-product-resource-delete-dialog") do |dialog|
              dialog.trigger("Review deletion", variant: :destructive)
              dialog.panel(
                title: "Delete #{product.name}?",
                description: "This permanently removes the product after dependent orders and authorization are verified."
              ) do
                form_with(
                  scope: :product_deletion,
                  url: "#delete-product-demo",
                  method: :delete,
                  id: "gallery-product-resource-delete-form",
                  data: { turbo_frame: "_top" }
                ) do
                  render NitroKit::Button.new(
                    "Delete product",
                    type: :submit,
                    variant: :destructive,
                    disabled: true,
                    data: { turbo_submits_with: "Deleting…" }
                  )
                end
                dialog.close_button(label: "Cancel deletion")
              end
            end
          end
          zone.escape NitroKit::Button.new(
            "Keep product",
            href: flow_path(
              state: product.status == :archived ? "archived" : "active",
              product_id: product.id
            )
          )
        end
      end

      def render_product_detail
        product = selected_product

        if product.status == :archived
          render NitroKit::Alert.new(
            id: "gallery-product-resource-archived-alert",
            variant: :warning
          ) do |alert|
            alert.title("This product is archived")
            alert.description("New sales are stopped, while existing customer access and lifecycle history remain available.")
          end
        end

        render NitroKit::DetailsTable.new(
          product,
          label: "Product metadata",
          id: "gallery-product-resource-details"
        ) do |details|
          details.fields(:name, :sku)
          details.field(:status) do |status|
            render NitroKit::Badge.new(
              status.to_s.humanize,
              color: product_status_color(status),
              size: :sm
            )
          end
          details.field(:price_cents, label: "Price", value: money(product.price_cents))
          details.field(:inventory_count, label: "Available inventory")
          details.field(:description)
          details.field(:created_on, label: "Created")
          details.field(:updated_at, label: "Last updated")
        end

        render_lifecycle_history(product, full: false)
      end

      def render_lifecycle_history(product, full:)
        events = Gallery::ProductData.events_for(product)
        events = events.first(2) unless full

        render NitroKit::DataSection.new(
          title: full ? "Complete lifecycle history" : "Recent lifecycle history",
          description: "Application-owned events record the actor, timing, and provenance of each state change.",
          id: "gallery-product-resource-history-section"
        ) do |section|
          section.actions NitroKit::Button.new(
            full ? "Back to product" : "View complete history",
            href: flow_path(
              state: full ? (product.status == :archived ? "archived" : "active") : "history",
              product_id: product.id
            )
          )
          section.table NitroKit::Table.new(
            id: "gallery-product-resource-history-table",
            table_aria: { label: "Product lifecycle history" }
          ) do |table|
            table.caption("Lifecycle events for #{product.name}")
            table.thead do
              table.tr do
                table.th("Event")
                table.th("Actor")
                table.th("Occurred")
                table.th("Detail")
              end
            end
            table.tbody do
              events.each do |event|
                table.tr do
                  table.th(event.action.to_s.humanize, scope: :row)
                  table.td(event.actor)
                  table.td(event.occurred_at.to_fs(:long))
                  table.td(event.detail)
                end
              end
            end
          end
        end
      end

      def product_form
        attributes = if state.start_with?("new")
          validation_state? ? invalid_new_attributes : { status: "draft" }
        elsif validation_state?
          invalid_edit_attributes
        else
          product_attributes(selected_product)
        end

        Gallery::Forms::Product.new(**attributes).tap do |form|
          form.validate if validation_state?
        end
      end

      def product_attributes(product)
        {
          name: product.name,
          sku: product.sku,
          status: product.status.to_s,
          price: product.price_cents / 100.0,
          inventory_count: product.inventory_count,
          description: product.description
        }
      end

      def invalid_new_attributes
        {
          name: "",
          sku: "telemetry",
          status: "draft",
          price: -1,
          inventory_count: -4,
          description: ""
        }
      end

      def invalid_edit_attributes
        {
          name: "Telemetry Hub",
          sku: "TEL-1",
          status: "active",
          price: -29,
          inventory_count: -1,
          description: Gallery::ProductData.active_product.description
        }
      end

      def products
        @products ||= case state
        when "filtered"
          [ Gallery::ProductData.fetch_product("product_sensor_gateway") ]
        when "empty"
          []
        when "paginated"
          Gallery::ProductData.products.last(2)
        else
          Gallery::ProductData.products.first(4)
        end
      end

      def filter_values
        case state
        when "filtered"
          { query: "Sensor", status: "active" }
        when "empty"
          { query: "No matching product", status: "" }
        else
          { query: "", status: "" }
        end
      end

      def selected_product
        fallback = state == "archived" ? Gallery::ProductData.archived_product : Gallery::ProductData.active_product
        product_id = request.query_parameters["product_id"]
        return fallback if product_id.blank?

        Gallery::ProductData.fetch_product(product_id)
      rescue KeyError
        fallback
      end

      def current_sort
        state == "paginated" ? "updated_at" : "name"
      end

      def current_direction
        state == "paginated" ? :desc : :asc
      end

      def sort_path(key)
        direction = current_sort == key.to_s && current_direction == :asc ? :desc : :asc

        flow_path(
          state:,
          q: filter_values.compact_blank,
          sort: key,
          direction:
        )
      end

      def page_path(page)
        flow_path(
          state: page == 1 ? "index" : "paginated",
          q: filter_values.compact_blank,
          sort: current_sort,
          direction: current_direction,
          page:
        )
      end

      def flow_path(state:, **query)
        gallery_composition_path(**{ slug: entry.slug, state:, **query }.compact)
      end

      def child_state?
        !INDEX_STATES.include?(state)
      end

      def back_path
        if %w[edit edit-validation history].include?(state)
          product = selected_product
          return flow_path(
            state: product.status == :archived ? "archived" : "active",
            product_id: product.id
          )
        end

        flow_path(state: "index")
      end

      def back_label
        %w[edit edit-validation history].include?(state) ? "Back to product" : "Back to products"
      end

      def route_title
        case state
        when "new", "new-validation"
          "New product"
        when "edit", "edit-validation"
          "Edit #{selected_product.name}"
        when "active", "archived"
          selected_product.name
        when "history"
          "#{selected_product.name} history"
        else
          "Products"
        end
      end

      def results_description
        return "No product satisfies the current name, SKU, and status filters." if products.empty?
        return "One active product matches “Sensor” across name, SKU, and description." if state == "filtered"
        return "Page two preserves the active GET query, sort, and browser history." if state == "paginated"

        "Products are scoped to Northstar Commerce and ordered by name."
      end

      def validation_state?
        state.end_with?("validation")
      end

      def paginated_results?
        %w[index paginated narrow].include?(state)
      end

      def product_status_color(status)
        status == :active ? :success : :neutral
      end

      def money(cents)
        Kernel.format("$%.2f", cents / 100.0)
      end

      def section_title = "Product administration"
      def section_description = "A complete product workflow spanning search, forms, details, lifecycle history, deletion, and narrow screens."

      def state_description
        {
          "index" => "A populated GET-driven product index with sortable columns and first-page pagination.",
          "filtered" => "Filters and sort links replace the current history entry inside one stable query frame.",
          "empty" => "A valid zero-result query returns the same frame with a typed EmptyState.",
          "paginated" => "Second-page navigation inherits the frame's advance action and preserves query parameters.",
          "new" => "A new-product SettingsSection uses one toolbar-associated native submit.",
          "new-validation" => "Server validation preserves invalid new-product values and accessible errors.",
          "edit" => "The edit form keeps its single Save action in the toolbar and deletion in a separate DangerZone.",
          "edit-validation" => "An invalid edit keeps submitted values, field errors, and edit-owned deletion visible.",
          "active" => "An active product detail combines status, metadata, and recent lifecycle provenance.",
          "archived" => "An archived product remains readable with sales impact and lifecycle history.",
          "history" => "The complete product lifecycle records actor, time, action, and detail.",
          "narrow" => "The same hybrid application shell, toolbar, query frame, and table run in a narrow preview."
        }.fetch(state)
      end
    end
  end
end
