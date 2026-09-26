module Gallery
  module Components
    class AppShellPage < ComponentPage
      private

      def source_note
        "app/components/nitro_kit/app_shell.rb"
      end

      def api_note
        "NitroKit::AppShell.new(id:, layout: :sidebar, skip_link_label:, open_navigation_label:, close_navigation_label:, navigation_dialog_label:) { |shell| shell.navigation { ... }; shell.main { ... } }"
      end

      def component_template
        example_section(
          "Layout variants",
          slug: "app-shell-layouts",
          description: "Both layouts reflow the same AppNavigation tree while the application supplies brand, actions, routes, and main content."
        ) do
          example(
            "Sidebar workspace",
            slug: "app-shell-sidebar",
            mode: :full_width,
            description: "A sticky product sidebar surrounds a compact operational dashboard.",
            code: Gallery::SourceCode.from_method(method(:render_workspace_shell))
          ) do
            render_workspace_shell(id: "gallery-app-shell-sidebar", layout: :sidebar, current: :overview)
          end

          example(
            "Topbar workspace",
            slug: "app-shell-topbar",
            mode: :full_width,
            description: "Brand, navigation, and account actions share the desktop header before the same tree becomes a narrow drawer."
          ) do
            render_workspace_shell(id: "gallery-app-shell-topbar", layout: :topbar, current: :overview)
          end
        end

        example_section(
          "Optional chrome and pressure",
          slug: "app-shell-pressure",
          description: "Optional regions disappear cleanly while long destinations, nested content, and narrow disclosure keep the same contract."
        ) do
          example(
            "Navigation and main only",
            slug: "app-shell-minimal",
            mode: :full_width,
            description: "Brand and topbar are optional; the required navigation and main regions still form a complete application frame."
          ) do
            render_workspace_shell(
              id: "gallery-app-shell-minimal",
              layout: :sidebar,
              current: :overview,
              brand: false,
              actions: false
            )
          end

          example(
            "Long workspace pressure",
            slug: "app-shell-long",
            mode: :full_width,
            description: "Long brand, route, and content copy shrink inside the owned columns without a layout option or utility class."
          ) do
            render_workspace_shell(
              id: "gallery-app-shell-long",
              layout: :sidebar,
              current: :capacity,
              long: true,
              dense: true
            )
          end
        end

        example_section(
          "Under pressure",
          slug: "app-shell-stress",
          description: "Both layouts with Gallery::Hostile's long name as brand, every hostile navigation label with badges, a long-labelled topbar action, and a main region of unbroken headings and hostile member cards."
        ) do
          example("Hostile sidebar and topbar", slug: "app-shell-hostile", stress: true, mode: :full_width) do
            NitroKit::AppShell::LAYOUTS.each do |layout|
              sample(layout.to_s.humanize, slug: layout.to_s) do
                render NitroKit::AppShell.new(
                  id: "gallery-app-shell-hostile-#{layout}",
                  layout:,
                  navigation_dialog_label: Gallery::Hostile::LONG_LABEL,
                  data: { gallery_shell_preview: layout }
                ) do |shell|
                  shell.brand { strong { Gallery::Hostile::LONG_NAME } }

                  shell.navigation do
                    render NitroKit::AppNavigation.new(
                      id: "gallery-app-shell-hostile-#{layout}-navigation",
                      label: Gallery::Hostile::LONG_LABEL
                    ) do |navigation|
                      navigation.header { strong { Gallery::Hostile::LONG_WORD } }
                      navigation.body do
                        navigation.section(label: Gallery::Hostile::LONG_LABEL) do
                          Gallery::Hostile::NAVIGATION_LABELS.each_with_index do |label, index|
                            navigation.item(
                              label,
                              href: "#{Gallery::Hostile::LONG_URL}#destination-#{index}",
                              icon: :folder,
                              badge: Gallery::Hostile::BADGE_LABELS[index],
                              current: index.zero?
                            )
                          end
                        end
                        navigation.spacer
                        navigation.divider
                        navigation.item(Gallery::Hostile::LONG_WORD, href: Gallery::Hostile::LONG_URL, icon: :settings)
                      end
                      navigation.footer { p { Gallery::Hostile::LONG_EMAIL } }
                    end
                  end

                  shell.topbar do
                    render NitroKit::Button.new(
                      Gallery::Hostile::LONG_LABEL,
                      id: "gallery-app-shell-hostile-#{layout}-search",
                      href: Gallery::Hostile::LONG_URL,
                      size: :sm,
                      icon: :search
                    )
                  end

                  shell.main do
                    div(data: { gallery: "app-shell-main" }) do
                      render NitroKit::Container.new(size: :lg) do
                        render NitroKit::Flex.new(dir: :col, gap: 6, align: :stretch) do
                          render NitroKit::PageHeader.new(
                            title: Gallery::Hostile::LONG_WORD,
                            description: Gallery::Hostile::LONG_PARAGRAPH,
                            level: 4
                          )
                          render NitroKit::Grid.new(cols: "1 sm:2 lg:3", gap: 3) do
                            Gallery::Hostile.members(9).each do |member|
                              render NitroKit::Card.new(id: "gallery-app-shell-hostile-#{layout}-#{member.id}") do |card|
                                card.title(member.name, level: 5)
                                card.body { p { member.email } }
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
        end
      end

      def render_workspace_shell(id:, layout:, current:, brand: true, actions: true, dense: false, long: false)
        render NitroKit::AppShell.new(
          id:,
          layout:,
          navigation_dialog_label: "Workspace navigation",
          data: {
            gallery_shell_preview: layout,
            gallery_shell_long: long ? "true" : nil
          }.compact
        ) do |shell|
          shell.brand do
            strong do
              long ? "International Analytical Engine Operations" : "Northstar"
            end
          end if brand

          shell.navigation do
            render_shell_navigation(id:, current:, dense:, long:)
          end

          shell.topbar do
            render NitroKit::Button.new("Search", href: "#search", variant: :ghost, size: :sm, icon: :search)
          end if actions

          shell.main { render_workspace_main(layout:, long:) }
        end
      end

      def render_shell_navigation(id:, current:, dense:, long:)
        render NitroKit::AppNavigation.new(label: "Primary workspace", id: "#{id}-navigation") do |navigation|
          navigation.header do
            render NitroKit::Flex.new(dir: :row, gap: 2, align: :center, justify: :between) do
              strong { long ? "International Analytical Engine Operations" : "Northstar" }
              render NitroKit::Badge.new(dense ? "Live operations" : "Team plan", variant: :outline, size: :sm)
            end
          end
          navigation.body do
            navigation.section(label: "Workspace") do
              navigation.item("Overview", href: "#overview", icon: :house, current: current == :overview)
              navigation.item("Projects", href: "#projects", icon: :folder, badge: 12, current: current == :projects)
              navigation.item("People", href: "#people", icon: :users)
            end

            if dense
              navigation.section(label: "Operations") do
                navigation.item("Deployments", href: "#deployments", icon: :rocket, badge: 4)
                navigation.item("Incidents", href: "#incidents", icon: :siren, badge: 2, current: current == :incidents)
                navigation.item(
                  long ? "Cross-regional capacity forecasts and production allocation" : "Capacity",
                  href: "#capacity",
                  icon: :gauge,
                  current: current == :capacity
                )
                navigation.item("Audit log", href: "#audit-log", icon: :scroll_text)
              end
            end

            navigation.spacer
            navigation.divider
            navigation.item("Settings", href: "#settings", icon: :settings)
          end
          navigation.footer do
            render_account_menu(id: "#{id}-account")
            render NitroKit::Button.new("Help", href: "#help", variant: :ghost, size: :sm, icon: :circle_help)
          end
        end
      end

      def render_workspace_main(layout:, long:)
        div(data: { gallery: "app-shell-main" }) do
          render NitroKit::Container.new(size: :lg) do
            render NitroKit::Flex.new(dir: :col, gap: 6, align: :stretch) do
              render NitroKit::PageHeader.new(
                eyebrow: layout.to_s.capitalize,
                title: long ?
                  "International research, reliability, and production readiness" :
                  "Workspace overview",
                description: long ?
                  "Coordinate analytical engine capacity, operational handoffs, and incident readiness across every research and production region." :
                  "A caller-owned dashboard composed from ordinary Nitro components.",
                level: 4
              )

              render NitroKit::Grid.new(
                cols: "1 sm:2 lg:3"
              ) do
                workspace_card("Active projects", "12", "Three need a decision this week.")
                workspace_card("Deployments", "4", "All production checks are passing.")
                workspace_card("Open incidents", "2", "Both have an assigned responder.")
              end
            end
          end
        end
      end

      def workspace_card(title, value, description)
        render NitroKit::Card.new do |card|
          card.title(title, level: 5)
          card.body do
            strong { value }
            p { description }
          end
          card.divider
          card.footer do
            render NitroKit::Button.new("View details", href: "#details", size: :sm)
          end
        end
      end
    end
  end
end
