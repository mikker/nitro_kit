module Gallery
  module Components
    class AppShellPage < ComponentPage
      private

      def source_note
        "app/components/nitro_kit/app_shell.rb"
      end

      def api_note
        "NitroKit::AppShell.new(id:, layout: :sidebar, collapsible: false, sidebar: :expanded, sidebar_toggle_label:, skip_link_label:, open_navigation_label:, close_navigation_label:, navigation_dialog_label:) { |shell| shell.navigation { ... }; shell.main { ... } }"
      end

      def component_template
        example_section(
          "Sidebar configurations and topbar",
          slug: "app-shell-layouts",
          description: "Compare static, pinned, icon-rail, and application-owned inset sidebars. Topbar uses the same navigation tree without sidebar pinning; every layout becomes the mobile drawer at narrow widths."
        ) do
          example(
            "Collapsible sidebar — starts expanded",
            slug: "app-shell-sidebar",
            mode: :full_width,
            description: "collapsible: true, sidebar: :expanded. Unpin to collapse immediately; leave and re-enter the rail to peek, or focus it with the keyboard."
          ) do
            render NitroKit::AppShell.new(
              id: "gallery-app-shell-sidebar",
              layout: :sidebar,
              collapsible: true,
              sidebar: :expanded,
              navigation_dialog_label: "Workspace navigation",
              data: { gallery_shell_preview: :sidebar }
            ) do |shell|
              shell.brand(icon: :star) { strong { "Northstar" } }
              shell.navigation do
                render_shell_navigation(id: "gallery-app-shell-sidebar", current: :overview, dense: false, long: false)
              end
              shell.topbar { render NitroKit::Button.new("Search", href: "#search", size: :sm, icon: :search) }
              shell.main { render_workspace_main(layout: :sidebar, long: false) }
            end
          end

          example(
            "Static sidebar — default",
            slug: "app-shell-static",
            mode: :full_width,
            description: "collapsible: false. Navigation stays expanded with no pin button or hover peek; the mobile drawer still works."
          ) do
            render NitroKit::AppShell.new(
              id: "gallery-app-shell-static",
              layout: :sidebar,
              collapsible: false,
              navigation_dialog_label: "Workspace navigation",
              data: { gallery_shell_preview: :sidebar }
            ) do |shell|
              shell.brand { strong { "Northstar" } }
              shell.navigation do
                render_shell_navigation(id: "gallery-app-shell-static", current: :overview, dense: false, long: false)
              end
              shell.topbar { render NitroKit::Button.new("Search", href: "#search", size: :sm, icon: :search) }
              shell.main { render_workspace_main(layout: :sidebar, long: false) }
            end
          end

          example(
            "Collapsible sidebar — starts collapsed",
            slug: "app-shell-rail",
            mode: :full_width,
            description: "collapsible: true, sidebar: :collapsed. Icons and the brand mark stay aligned; hover or focus to peek without shifting content, or click to pin open."
          ) do
            render NitroKit::AppShell.new(
              id: "gallery-app-shell-rail",
              collapsible: true,
              sidebar: :collapsed,
              data: { gallery_shell_preview: :sidebar }
            ) do |shell|
              shell.brand(icon: :star) { strong { "Northstar" } }
              shell.navigation do
                render NitroKit::AppNavigation.new(label: "Rail workspace") do |navigation|
                  navigation.body do
                    navigation.section(label: "Workspace") do
                      navigation.item("Overview", href: "#overview", icon: :house, current: true)
                      navigation.item("Projects", href: "#projects", icon: :folder)
                      navigation.item("People", href: "#people", icon: :users)
                    end
                    navigation.spacer
                    navigation.item("Help", href: "#help", icon: :circle_help)
                    navigation.item("Settings", href: "#settings", icon: :settings)
                  end
                end
              end
              shell.topbar { render NitroKit::Button.new("New project", icon: :plus, variant: :primary) }
              shell.main do
                div(data: { gallery: "app-shell-main" }) do
                  render NitroKit::PageHeader.new(
                    title: "Projects",
                    description: "Peek at navigation without moving this canvas, or pin it to reserve layout space.",
                    level: 4
                  )
                end
              end
            end
          end

          example(
            "Inset sidebar workspace",
            slug: "app-shell-inset",
            mode: :full_width,
            description: "Application-owned inset_workspace.css joins the toolbar and content into one rounded canvas. Use data-ui hooks, not an inset component option; navigation and the mobile drawer remain Nitro-owned."
          ) do
            render NitroKit::AppShell.new(
              id: "gallery-app-shell-inset",
              layout: :sidebar,
              collapsible: false,
              data: { ui: "inset-workspace", gallery_shell_preview: :sidebar }
            ) do |shell|
              shell.brand { strong { "Northstar" } }
              shell.navigation do
                render NitroKit::AppNavigation.new(label: "Northstar workspace") do |navigation|
                  navigation.body do
                    navigation.section(label: "Workspace") do
                      navigation.item("Overview", href: "#overview", icon: :house, current: true)
                      navigation.item("Projects", href: "#projects", icon: :folder, badge: 12)
                      navigation.item("People", href: "#people", icon: :users)
                    end
                    navigation.spacer
                    navigation.item("Settings", href: "#settings", icon: :settings)
                  end
                  navigation.footer { render NitroKit::Button.new("Help", href: "#help", size: :sm, icon: :circle_help) }
                end
              end
              shell.topbar do
                render NitroKit::Toolbar.new do |toolbar|
                  toolbar.leading { h4 { "Workspace overview" } }
                  toolbar.trailing { render NitroKit::Button.new("New project", href: "#new-project", variant: :primary) }
                end
              end
              shell.main do
                render NitroKit::Flex.new(dir: :col, gap: 6, align: :stretch, data: { ui: "workspace-content" }) do
                  p { "One content gutter, an independently scrolling canvas, and a quiet navigation rail." }
                  render NitroKit::StatGrid.new do |stats|
                    stats.stat(key: :projects, label: "Active projects", value: "12", detail: "Three need a decision")
                    stats.stat(key: :deployments, label: "Deployments", value: "4", detail: "All checks passing")
                    stats.stat(key: :incidents, label: "Open incidents", value: "2", detail: "Both assigned")
                  end
                end
              end
            end
          end

          example(
            "Inset sidebar — collapsible",
            slug: "app-shell-inset-collapsible",
            mode: :full_width,
            description: "Combine the application-owned inset canvas with collapsible: true. Start pinned open, unpin to an icon rail, then hover or focus to peek without moving the inset toolbar or content."
          ) do
            render NitroKit::AppShell.new(
              id: "gallery-app-shell-inset-collapsible",
              layout: :sidebar,
              collapsible: true,
              sidebar: :expanded,
              data: { ui: "inset-workspace", gallery_shell_preview: :sidebar }
            ) do |shell|
              shell.brand(icon: :star) { strong { "Northstar" } }
              shell.navigation do
                render NitroKit::AppNavigation.new(label: "Northstar workspace") do |navigation|
                  navigation.body do
                    navigation.section(label: "Workspace") do
                      navigation.item("Overview", href: "#overview", icon: :house, current: true)
                      navigation.item("Projects", href: "#projects", icon: :folder, badge: 12)
                      navigation.item("People", href: "#people", icon: :users)
                    end
                    navigation.spacer
                    navigation.item("Settings", href: "#settings", icon: :settings)
                  end
                  navigation.footer { render NitroKit::Button.new("Help", href: "#help", size: :sm, icon: :circle_help) }
                end
              end
              shell.topbar do
                render NitroKit::Toolbar.new do |toolbar|
                  toolbar.leading { h4 { "Workspace overview" } }
                  toolbar.trailing { render NitroKit::Button.new("New project", href: "#new-project", variant: :primary) }
                end
              end
              shell.main do
                render NitroKit::Flex.new(dir: :col, gap: 6, align: :stretch, data: { ui: "workspace-content" }) do
                  p { "Pin to reserve navigation space, or peek over the canvas without reflowing this content." }
                  render NitroKit::StatGrid.new do |stats|
                    stats.stat(key: :projects, label: "Active projects", value: "12", detail: "Three need a decision")
                    stats.stat(key: :deployments, label: "Deployments", value: "4", detail: "All checks passing")
                    stats.stat(key: :incidents, label: "Open incidents", value: "2", detail: "Both assigned")
                  end
                end
              end
            end
          end

          example(
            "Topbar workspace",
            slug: "app-shell-topbar",
            mode: :full_width,
            description: "Brand, navigation, and account actions share the desktop header before the same tree becomes a narrow drawer."
          ) do
            render_workspace_shell(id: "gallery-app-shell-topbar", layout: :topbar, current: :overview, collapsible: false)
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
              collapsible: true,
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
              collapsible: true,
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
                  collapsible: true,
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
                                card.description(member.email)
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

      def render_workspace_shell(id:, layout:, current:, collapsible:, brand: true, actions: true, dense: false, long: false)
        render NitroKit::AppShell.new(
          id:,
          layout:,
          collapsible:,
          navigation_dialog_label: "Workspace navigation",
          data: {
            gallery_shell_preview: layout,
            gallery_shell_long: long ? "true" : nil
          }.compact
        ) do |shell|
          shell.brand(icon: collapsible ? :star : nil) do
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
          card.header do
            card.title(title, level: 5)
            card.description(description)
          end
          card.divider
          card.footer do
            strong { value }
            card.actions { render NitroKit::Button.new("View details", href: "#details", size: :sm) }
          end
        end
      end
    end
  end
end
