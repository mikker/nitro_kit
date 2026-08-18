module Gallery
  module Compositions
    class IntegrationManagementPage < ScenarioPage
      include Phlex::Rails::Helpers::FormWith

      private

      def render_scenario
        workspace_surface do
          render_header

          case state
          when "catalog", "mobile"
            render_catalog
          when "detail"
            render_provider_detail
          when "connected"
            render_connected
          when "config-error"
            render_configuration(invalid: true)
          end
        end
      end

      def render_header
        render NitroKit::PageHeader.new(
          title: integration_title,
          description: state_description,
          id: "gallery-integration-management-header"
        ) do |header|
          header.actions(
            NitroKit::ButtonGroup.new(
              id: "gallery-integration-management-header-actions",
              label: "Integration navigation"
            )
          ) { |actions| render_header_actions(actions) }
        end
      end

      def render_header_actions(actions)
        case state
        when "catalog", "mobile"
          actions.button("Connected services", href: entry_path(entry, state: "connected"))
        when "detail"
          actions.button("Back to catalog", href: entry_path(entry, state: "catalog"), icon: :arrow_left)
        when "connected"
          actions.button("Connect another service", href: entry_path(entry, state: "catalog"), variant: :primary, icon: :plus)
        when "config-error"
          actions.button("Connected services", href: entry_path(entry, state: "connected"), icon: :arrow_left)
        end
      end

      def render_catalog
        render NitroKit::DataSection.new(
          title: "Available integrations",
          description: "Connect the services your team already uses for source control, incidents, communication, and billing.",
          id: "gallery-integration-catalog-section"
        ) do |section|
          section.actions(
            NitroKit::ButtonGroup.new(id: "gallery-integration-catalog-actions", label: "Catalog actions")
          ) do |actions|
            actions.button("Request a provider", href: "#request-provider")
          end
          section.table NitroKit::Table.new(id: "gallery-integration-catalog-table") do |table|
            populate_catalog_table(table)
          end
        end
      end

      def populate_catalog_table(table)
        table.caption("Available workspace integration providers")
        table.thead do
          table.tr do
            table.th("Provider")
            table.th("Category") unless state == "mobile"
            table.th("Status")
            table.th("Action", align: :right)
          end
        end
        table.tbody do
          providers.each do |provider|
            table.tr do
              table.th(provider.name, scope: :row)
              table.td(provider.category.to_s.humanize) unless state == "mobile"
              table.td do
                render NitroKit::Badge.new(
                  provider.status.to_s.humanize,
                  id: "gallery-integration-#{provider.id}-status",
                  color: provider_status_color(provider.status),
                  size: :sm
                )
              end
              table.td(align: :right) do
                render NitroKit::Button.new(
                  provider.status == :available ? "View" : "Manage",
                  href: entry_path(entry, state: provider.status == :connected ? "connected" : "detail"),
                  id: "gallery-integration-#{provider.id}-action",
                  size: :sm,
                  aria: { label: "#{provider.status == :available ? 'View' : 'Manage'} #{provider.name}" }
                )
              end
            end
          end
        end
      end

      def render_provider_detail
        provider = providers.fetch(2)

        render NitroKit::Flex.new(dir: :col, gap: 6, align: :stretch, id: "gallery-integration-detail-grid") do
          render NitroKit::DataSection.new(
            title: "Before you connect",
            description: provider.summary,
            id: "gallery-integration-detail-card"
          ) do |section|
            section.actions NitroKit::Button.new(
              "Provider documentation",
              href: provider.documentation_url,
              icon_end: :external_link,
              id: "gallery-integration-detail-documentation"
            )
            section.table NitroKit::DetailsTable.new(
              provider,
              caption: "Sentry connection details",
              data: { gallery: "integration-detail-metadata" }
            ) do |details|
              details.field(:status, value: "Available")
              details.field(:category) { |category| plain category.to_s.humanize }
              details.field(:authorization, value: "Workspace owner approval required")
              details.field(:data_shared, value: "Release names, deployment references, and error identifiers")
            end
          end
          render_configuration(invalid: false)
        end
      end

      def render_configuration(invalid:)
        configuration = integration_configuration(invalid:)

        render NitroKit::SettingsSection.new(
          title: invalid ? "Repair Slack configuration" : "Configure Sentry",
          description: invalid ? "Update the delivery destination and webhook settings to resume notifications." : "Choose where incident events should be delivered after authorization.",
          id: "gallery-integration-configuration-section"
        ) do |section|
          if invalid
            section.status NitroKit::Alert.new(
              variant: :destructive,
              id: "gallery-integration-configuration-error"
            ) do |alert|
              alert.title("Notifications cannot be delivered")
              alert.description("Choose a destination, use an HTTPS webhook URL, and select a supported event.")
            end
          end
          section.form do
            form_with(
              model: configuration,
              url: "#integration-configurations",
              builder: NitroKit::FormBuilder,
              id: "gallery-integration-configuration-form"
            ) do |form|
              form.hidden_field(:provider)
              form.group do
                form.field(:destination, label: "Destination", placeholder: "#production-incidents", required: true)
                form.field(
                  :webhook_url,
                  as: :url,
                  label: "Webhook URL",
                  autocomplete: "url",
                  description: "Credentials are encrypted before they are stored.",
                  required: true
                )
                form.field(
                  :event,
                  as: :select,
                  label: "Event type",
                  options: Gallery::Forms::IntegrationConfiguration::EVENTS.map { |event| [ event.humanize, event ] },
                  prompt: "Choose an event",
                  required: true
                )
                render NitroKit::Toolbar.new(id: "gallery-integration-configuration-toolbar") do |toolbar|
                  toolbar.trailing do
                    form.submit(
                      invalid ? "Retry configuration" : "Connect Sentry",
                      id: "gallery-integration-configuration-submit",
                      data: { turbo_submits_with: "Saving configuration…" }
                    )
                  end
                end
              end
            end
          end
        end
      end

      def render_connected
        connected = providers.select { |provider| provider.connected_at }

        render NitroKit::Alert.new(variant: :success, id: "gallery-integration-connected-alert") do |alert|
          alert.icon NitroKit::Icon.new(:circle_check, id: "gallery-integration-connected-icon")
          alert.title("GitHub is connected")
          alert.description("Pull request and deployment events are now available to this workspace.")
        end
        render NitroKit::DataSection.new(
          title: "Connected services",
          description: "Review active authorizations and repair connections that need attention.",
          id: "gallery-integration-connected-section"
        ) do |section|
          section.actions(
            NitroKit::ButtonGroup.new(id: "gallery-integration-connected-actions", label: "Connected service actions")
          ) do |actions|
            actions.button("Connect another service", href: entry_path(entry, state: "catalog"), variant: :primary)
          end
          section.table NitroKit::Table.new(id: "gallery-integration-connected-table") do |table|
            table.caption("Connected workspace integrations")
            table.thead do
              table.tr do
                table.th("Provider")
                table.th("Connected")
                table.th("State")
                table.th("Action", align: :right)
              end
            end
            table.tbody do
              connected.each do |provider|
                table.tr do
                  table.th(provider.name, scope: :row)
                  table.td(provider.connected_at.to_fs(:long))
                  table.td do
                    render NitroKit::Badge.new(
                      provider.status.to_s.humanize,
                      color: provider_status_color(provider.status),
                      size: :sm
                    )
                  end
                  table.td(align: :right) do
                    render NitroKit::Button.new(
                      "Manage",
                      href: provider.status == :configuration_error ? entry_path(entry, state: "config-error") : "#github",
                      size: :sm,
                      aria: { label: "Manage #{provider.name}" }
                    )
                  end
                end
              end
            end
          end
        end
      end

      def integration_configuration(invalid:)
        attributes = if invalid
          { provider: "slack", destination: "", webhook_url: "http://expired.example.test", event: "everything" }
        else
          { provider: "sentry", destination: "production-web", webhook_url: "https://hooks.example.test/sentry", event: "incidents" }
        end

        Gallery::Forms::IntegrationConfiguration.new(**attributes).tap do |configuration|
          configuration.validate if invalid
        end
      end

      def providers
        @providers ||= if state == "mobile"
          Gallery::OperationalData.integration_providers.first(3)
        else
          Gallery::OperationalData.integration_providers
        end
      end

      def provider_status_color(status)
        { available: :info, connected: :success, configuration_error: :destructive }.fetch(status)
      end

      def integration_title
        {
          "catalog" => "Connect your tools",
          "detail" => "Connect Sentry",
          "connected" => "Connected integrations",
          "config-error" => "Repair Slack integration",
          "mobile" => "Integrations"
        }.fetch(state)
      end

      def section_title = "Workspace integration operations"
      def section_description = "Provider discovery, detail, connection records, configuration recovery, and narrow catalog pressure."

      def state_description
        {
          "catalog" => "Bring source control, incident, communication, and billing events into one workspace.",
          "detail" => "Review what Sentry can access, then choose which incidents should reach your team.",
          "connected" => "Your workspace has two active connections, and one needs updated delivery settings.",
          "config-error" => "Slack is still authorized, but its notification destination needs to be repaired.",
          "mobile" => "Browse available services and see connection health at a glance."
        }.fetch(state)
      end
    end
  end
end
