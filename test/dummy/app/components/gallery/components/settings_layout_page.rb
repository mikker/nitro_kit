module Gallery
  module Components
    class SettingsLayoutPage < ComponentPage
      DESTINATIONS = %i[profile security activity appearance].freeze

      private

      def source_note
        "app/components/nitro_kit/settings_layout.rb"
      end

      def api_note
        "NitroKit::SettingsLayout.new { |layout| layout.navigation(label:) { layout.item(text, href:, current:) }; layout.content { ... } }"
      end

      def component_template
        example_section(
          "Required regions",
          slug: "settings-layout-regions",
          description: "One labelled navigation list of typed destinations and one neutral content region form the complete contract."
        ) do
          example("Workspace settings", slug: "settings-layout-workspace", mode: :full_width) do
            render NitroKit::SettingsLayout.new(id: "gallery-settings-layout-workspace") do |layout|
              layout.navigation(label: "Workspace settings") do
                DESTINATIONS.each do |destination|
                  layout.item(
                    destination.to_s.humanize,
                    href: "##{destination}",
                    current: destination == :profile
                  )
                end
              end
              layout.content do
                render NitroKit::Card.new(id: "gallery-settings-layout-profile-card") do |card|
                  card.title("Public profile", level: 4)
                  card.body do
                    render NitroKit::Field.new(
                      nil,
                      :name,
                      id: "gallery-settings-layout-profile-name",
                      name: "profile[name]",
                      value: "Ada Lovelace",
                      label: "Name"
                    )
                  end
                  card.footer do
                    render NitroKit::Button.new(
                      "Save profile",
                      id: "gallery-settings-layout-profile-save",
                      variant: :primary
                    )
                  end
                end
              end
            end
          end
        end

        example_section(
          "Content cardinality",
          slug: "settings-layout-cardinality",
          description: "The regions remain explicit with one destination, a single surface, and dense caller-owned content."
        ) do
          example("One and many", slug: "settings-layout-cardinality-states", mode: :full_width) do
            sample("One destination", slug: "one") do
              render NitroKit::SettingsLayout.new(id: "gallery-settings-layout-one") do |layout|
                layout.navigation(label: "Account settings") do
                  layout.item("Profile", href: "#profile", current: true)
                end
                layout.content do
                  render NitroKit::Alert.new(id: "gallery-settings-layout-one-alert") do |alert|
                    alert.title("Nothing needs attention")
                    alert.description("Your account settings are current.")
                  end
                end
              end
            end
            sample("Dense content", slug: "many") do
              render NitroKit::SettingsLayout.new(id: "gallery-settings-layout-many") do |layout|
                layout.navigation(label: "Operations settings") do
                  DESTINATIONS.each do |destination|
                    layout.item(
                      destination.to_s.humanize,
                      href: "##{destination}",
                      current: destination == :security
                    )
                  end
                end
                layout.content do
                  render NitroKit::Flex.new(dir: :col, gap: 2, align: :stretch) do
                    6.times do |index|
                      render NitroKit::Card.new(id: "gallery-settings-layout-many-#{index + 1}") do |card|
                        card.body("Policy section #{index + 1}")
                      end
                    end
                  end
                end
              end
            end
          end
        end

        example_section(
          "Narrow and long pressure",
          slug: "settings-layout-pressure",
          description: "Nitro owns the single 48rem collapse while long labels and product copy remain application data."
        ) do
          example(
            "Long organization settings",
            slug: "settings-layout-long",
            mode: :full_width,
            api: "The two regions stack automatically at the shared max-width: 48rem condition"
          ) do
            render NitroKit::SettingsLayout.new(id: "gallery-settings-layout-long") do |layout|
              layout.navigation(label: "Analytical Engines — International Research and Production settings") do
                layout.item("Public organization identity and verified domains", href: "#identity", current: true)
                layout.item("Credential rotation and browser session policy", href: "#security")
                layout.item("Deployment notification delivery preferences", href: "#notifications")
              end
              layout.content do
                render NitroKit::Card.new(id: "gallery-settings-layout-long-card") do |card|
                  card.title("Public organization identity and verified domains", level: 4)
                  card.body(
                    "These settings apply to every administrator, production environment, customer-visible status " \
                      "notification, security event, and invoice issued by this unusually long-named workspace."
                  )
                end
              end
            end
          end
        end

        example_section(
          "Nested compositions",
          slug: "settings-layout-nesting",
          description: "SettingsLayout owns only the two regions; Toolbar and PaginationBar retain their own placement contracts."
        ) do
          example("Audit settings", slug: "settings-layout-audit", mode: :full_width) do
            render NitroKit::SettingsLayout.new(id: "gallery-settings-layout-audit") do |layout|
              layout.navigation(label: "Audit settings") do
                DESTINATIONS.each do |destination|
                  layout.item(
                    destination.to_s.humanize,
                    href: "##{destination}",
                    current: destination == :activity
                  )
                end
              end
              layout.content do
                render NitroKit::Flex.new(dir: :col, gap: 4, align: :stretch) do
                  render NitroKit::Toolbar.new(id: "gallery-settings-layout-audit-toolbar") do |toolbar|
                    toolbar.leading { h3 { "Audit retention" } }
                    toolbar.trailing do
                      render NitroKit::Button.new(
                        "Export records",
                        id: "gallery-settings-layout-audit-export",
                        variant: :primary
                      )
                    end
                  end
                  render NitroKit::PaginationBar.new(id: "gallery-settings-layout-audit-pagination-bar") do |bar|
                    bar.summary("Showing audit records 1–25 of 240")
                    bar.pagination(NitroKit::Pagination.new(label: "Audit record pages")) do |pagination|
                      pagination.prev
                      pagination.page(1, current: true)
                      pagination.page(2, href: "?page=2")
                      pagination.next(href: "?page=2")
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
