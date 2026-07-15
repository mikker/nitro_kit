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
            "Minimal and grouped",
            slug: "app-navigation-cardinality",
            layout: :matrix,
            mode: :full_width,
            description: "The smallest valid body and a sectioned body share the same public grammar."
          ) do
            sample("One destination", slug: "app-navigation-minimal") do
              render_navigation(
                id: "gallery-app-navigation-minimal",
                label: "Minimal",
                destinations: [ [ "Home", "#minimal-home", :house ] ]
              )
            end

            sample("Two labelled groups", slug: "app-navigation-groups") do
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
            description: "Item labels truncate within the navigation boundary while numeric and text badges remain aligned."
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
                navigation.spacer
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
            "Destination inventory",
            slug: "app-navigation-inventory",
            mode: :full_width,
            description: "A longer real-world inventory proves body scrolling, the single spacer, and one current destination."
          ) do
            render_inventory_navigation
          end
        end
      end

      def render_navigation(id:, label:, destinations:)
        render NitroKit::AppNavigation.new(
          id:,
          label:,
          data: { gallery_navigation_preview: "minimal" }
        ) do |navigation|
          navigation.body do
            destinations.each_with_index do |(text, href, icon), index|
              navigation.item(text, href:, icon:, current: index.zero?)
            end
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
