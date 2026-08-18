module Gallery
  module Components
    class AppNavigationPage < ComponentPage
      private

      def source_note
        "app/components/nitro_kit/app_navigation.rb"
      end

      def api_note
        "NitroKit::AppNavigation.new(label:, id:) { |navigation| navigation.body { ... } }"
      end

      def component_template
        example_section(
          "Anatomy",
          slug: "app-navigation-anatomy",
          description: "The required body keeps destinations explicit while optional chrome and ordered entries remain bounded."
        ) do
          example(
            "Complete navigation",
            slug: "app-navigation-complete",
            mode: :full_width,
            description: "Header, labelled sections, icons, badges, current state, divider, spacer, and footer appear in one tree."
          ) do
            render NitroKit::AppNavigation.new(
              id: "gallery-app-navigation-complete",
              label: "Workspace",
              data: { gallery_navigation_preview: "complete" }
            ) do |navigation|
              navigation.footer do
                render NitroKit::Button.new("Sign out", href: "#sign-out", variant: :ghost, size: :sm, icon: :log_out)
              end
              navigation.body do
                navigation.section(label: "Workspace") do
                  navigation.item("Overview", href: "#overview", icon: :house, current: true)
                  navigation.item("Projects", href: "#projects", icon: :folder, badge: 12)
                  navigation.item("People", href: "#people", icon: :users)
                end
                navigation.divider
                navigation.section(label: "Manage") do
                  navigation.item("Automations", href: "#automations", icon: :zap, badge: "New")
                  navigation.item("Settings", href: "#settings", icon: :settings)
                end
                navigation.spacer
                navigation.item("Help and support", href: "#help", icon: :circle_help)
              end
              navigation.header do
                render NitroKit::Badge.new("Production", variant: :outline, size: :sm)
              end
            end
          end

          example(
            "One destination",
            slug: "app-navigation-minimal",
            mode: :full_width,
            description: "Declare the collection before the component, then consume it inside the required body slot."
          ) do
            destinations = [ [ "Home", "#minimal-home", :house ] ]

            render NitroKit::AppNavigation.new(
              id: "gallery-app-navigation-minimal",
              label: "Minimal",
              data: { gallery_navigation_preview: "minimal" }
            ) do |navigation|
              navigation.body do
                destinations.each do |text, href, icon|
                  navigation.item(text, href:, icon:, current: true)
                end
              end
            end
          end

          example(
            "Two labelled groups",
            slug: "app-navigation-groups",
            mode: :full_width,
            description: "A sectioned body shares the same public grammar as the smallest one."
          ) do
            render NitroKit::AppNavigation.new(
              id: "gallery-app-navigation-groups",
              label: "Grouped destinations",
              data: { gallery_navigation_preview: "groups" }
            ) do |navigation|
              navigation.body do
                navigation.section(label: "Plan") do
                  navigation.item("Roadmap", href: "#roadmap", icon: :map)
                  navigation.item("Milestones", href: "#milestones", icon: :flag, current: true)
                end
                navigation.section(label: "Observe") do
                  navigation.item("Activity", href: "#activity", icon: :activity)
                  navigation.item("Reports", href: "#reports", icon: :chart_no_axes_column)
                end
              end
            end
          end

          example(
            "Collapsible groups",
            slug: "app-navigation-collapsible",
            mode: :full_width,
            description: "Collapsible sections disclose through native details and summary; open state lives on the open attribute and needs no JavaScript."
          ) do
            render NitroKit::AppNavigation.new(
              id: "gallery-app-navigation-collapsible",
              label: "Collapsible destinations",
              data: { gallery_navigation_preview: "collapsible" }
            ) do |navigation|
              navigation.body do
                navigation.section(label: "Plan", collapsible: true) do
                  navigation.item("Roadmap", href: "#collapsible-roadmap", icon: :map)
                  navigation.item("Milestones", href: "#collapsible-milestones", icon: :flag, current: true)
                end
                navigation.section(label: "Archive", collapsible: true, expanded: false) do
                  navigation.item("Exports", href: "#collapsible-exports", icon: :archive)
                  navigation.item("Retired projects", href: "#collapsible-retired", icon: :folder)
                end
              end
            end
          end
        end

        example_section(
          "Pressure and composition",
          slug: "app-navigation-pressure",
          description: "Long labels, many destinations, state metadata, and ordinary Nitro children stay legible without opening the API."
        ) do
          example(
            "Long labels and dense badges",
            slug: "app-navigation-long-labels",
            mode: :full_width,
            description: "Item labels truncate within the navigation boundary, with or without an icon, while numeric and text badges remain aligned."
          ) do
            render NitroKit::AppNavigation.new(
              id: "gallery-app-navigation-pressure",
              label: "International research workspace",
              data: { gallery_navigation_preview: "pressure" }
            ) do |navigation|
              navigation.body do
                navigation.section(label: "International Research and Production") do
                  navigation.item(
                    "Analytical engine reliability and production readiness",
                    href: "#reliability",
                    icon: :gauge,
                    badge: 128,
                    current: true
                  )
                  navigation.item(
                    "Cross-regional incident response and operational handoffs",
                    href: "#incidents",
                    icon: :siren,
                    badge: "Urgent"
                  )
                  navigation.item(
                    "Quarterly capacity forecasts and allocation planning",
                    href: "#capacity",
                    icon: :calendar_range
                  )
                end
                navigation.section(label: "Unaccompanied labels") do
                  navigation.item(
                    "Regional data residency and retention commitments",
                    href: "#residency",
                    badge: 64
                  )
                  navigation.item(
                    "Deprecated provisioning workflows awaiting removal",
                    href: "#deprecated"
                  )
                end
                navigation.spacer
                navigation.divider
                navigation.item("Workspace settings", href: "#workspace-settings", icon: :settings)
              end
              navigation.footer do
                render NitroKit::ButtonGroup.new(label: "Workspace help") do |group|
                  group.button("Docs", href: "#docs", size: :sm)
                  group.button("Support", href: "#support", size: :sm)
                end
              end
            end
          end

          example(
            "Item attributes and badge colors",
            slug: "app-navigation-item-attributes",
            mode: :full_width,
            description: "Items carry ordinary link attributes through html:, aria:, and data:, and each badge picks its own color."
          ) do
            render NitroKit::AppNavigation.new(
              id: "gallery-app-navigation-item-attributes",
              label: "Item attributes"
            ) do |navigation|
              navigation.body do
                navigation.item(
                  "Incidents",
                  href: "#item-attributes-incidents",
                  icon: :siren,
                  badge: 3,
                  badge_color: :destructive,
                  current: true,
                  data: { turbo_frame: "gallery-content" }
                )
                navigation.item(
                  "Deployments",
                  href: "#item-attributes-deployments",
                  icon: :rocket,
                  badge: "Live",
                  badge_color: :success
                )
                navigation.item(
                  "Status page",
                  href: "https://status.example.com",
                  icon: :external_link,
                  html: { target: "_blank", rel: "noopener noreferrer" },
                  aria: { describedby: "gallery-app-navigation-external-note" }
                )
              end
              navigation.footer do
                p(id: "gallery-app-navigation-external-note") { "External destinations open in a new tab." }
              end
            end
          end

          example(
            "Destination inventory",
            slug: "app-navigation-inventory",
            mode: :full_width,
            description: "A longer real-world inventory proves body scrolling, the single spacer, and one current destination."
          ) do
            render_inventory_navigation
          end
        end
      end

      def render_inventory_navigation
        render NitroKit::AppNavigation.new(
          id: "gallery-app-navigation-inventory",
          label: "Operations",
          data: { gallery_navigation_preview: "inventory" }
        ) do |navigation|
          navigation.header { strong { "Operations" } }
          navigation.body do
            navigation.section(label: "Monitor") do
              navigation.item("Overview", href: "#inventory-overview", icon: :layout_dashboard)
              navigation.item("Deployments", href: "#deployments", icon: :rocket, badge: 4)
              navigation.item("Incidents", href: "#inventory-incidents", icon: :siren, badge: 2, current: true)
              navigation.item("Audit log", href: "#audit", icon: :scroll_text)
            end
            navigation.section(label: "Configure") do
              navigation.item("Environments", href: "#environments", icon: :boxes)
              navigation.item("API credentials", href: "#credentials", icon: :key_round)
              navigation.item("Integrations", href: "#integrations", icon: :plug)
              navigation.item("Team access", href: "#access", icon: :user_round_cog)
            end
            navigation.spacer
            navigation.divider
            navigation.item("Documentation", href: "#inventory-docs", icon: :book_open)
          end
        end
      end
    end
  end
end
