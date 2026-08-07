module Gallery
  module Compositions
    class SidebarApplicationPage < ApplicationPage
      Incident = ::Data.define(:service, :region, :owner, :started_at, :last_update)

      INCIDENT = Incident.new(
        service: "Workspace synchronization",
        region: "eu-central",
        owner: nil,
        started_at: Time.zone.parse("2026-07-13 18:42:00 UTC"),
        last_update: nil
      )

      private

      def application_template
        application_section(
          "Operational workspace states",
          slug: "sidebar-application-states",
          description: "A persistent sidebar surrounds populated, empty, and failed operational screens. Each preview is the executable method shown in its Code tab."
        ) do
          application_example(
            "Populated system workspace",
            slug: "sidebar-application-populated",
            description: "Live system appearance, summary statistics, sortable incidents, account actions, and a durable result notification share one application frame.",
            source: :render_sidebar_populated
          ) { render_sidebar_populated }

          application_example(
            "Empty light workspace",
            slug: "sidebar-application-empty",
            description: "A missing optional description, true empty state, and ordinary multipart Dropzone keep the first-run path useful.",
            source: :render_sidebar_empty
          ) { render_sidebar_empty }

          application_example(
            "Failed dark workspace",
            slug: "sidebar-application-error",
            description: "An explicit service failure combines recovery guidance, partial record details, and a native diagnostic dialog.",
            source: :render_sidebar_error
          ) { render_sidebar_error }
        end
      end

      def render_sidebar_populated
        render NitroKit::AppShell.new(
          id: "gallery-sidebar-application-populated",
          layout: :sidebar,
          data: {
            gallery_shell_preview: "true",
            gallery_application: "sidebar",
            gallery_application_state: "populated"
          }
        ) do |shell|
          shell.brand { strong { "Northstar Operations" } }
          shell.navigation do
            render_application_navigation(
              id: "gallery-sidebar-application-populated-navigation",
              current: :overview,
              context: "Production"
            )
          end
          shell.topbar do
            render NitroKit::Dropdown.new(id: "gallery-sidebar-application-account") do |menu|
              menu.trigger("Account", variant: :ghost, size: :sm)
              menu.item("Profile", href: "#profile")
              menu.item("Sign out")
            end
          end
          shell.main do
            render_application_main do
              render NitroKit::PageHeader.new(
                title: "Operations overview",
                description: "Production workspaces, active incidents, and deployment readiness at a glance.",
                id: "gallery-sidebar-application-populated-header"
              ) do |header|
                header.actions NitroKit::ButtonGroup.new(label: "Operations actions") do |group|
                  group.button("New deployment", href: "#new-deployment", variant: :primary)
                  group.button("Export", href: "#export")
                end
              end

              appearance_picker("gallery-sidebar-application-appearance", label: "Workspace appearance")

              render NitroKit::StatGrid.new(id: "gallery-sidebar-application-stats") do |stats|
                stats.stat(key: :workspaces, label: "Workspaces", value: "18", detail: "16 healthy")
                stats.stat(key: :deployments, label: "Deployments today", value: "42", detail: "All checks complete")
                stats.stat(key: :incidents, label: "Open incidents", value: "2", detail: "Both assigned")
              end

              render NitroKit::Table.new(
                sort: :started,
                direction: :desc,
                id: "gallery-sidebar-application-incidents"
              ) do |table|
                table.caption("Active production incidents")
                table.thead do
                  table.tr do
                    table.th(sort: :service, href: "?sort=service-asc")
                    table.th(sort: :region, href: "?sort=region-asc")
                    table.th(sort: :status, href: "?sort=status-asc")
                    table.th(sort: :started, href: "?sort=started-asc", align: :right)
                  end
                end
                table.tbody do
                  [
                    [ "Workspace synchronization", "eu-central", :waiting, "18:42" ],
                    [ "Audit export", "us-east", :healthy, "17:08" ],
                    [ "Invoice delivery", "global", :queued, "15:31" ]
                  ].each_with_index do |(service, region, status, started), index|
                    table.tr do
                      table.th(service, scope: :row)
                      table.td(region)
                      table.td { status_badge(status, id: "gallery-sidebar-application-status-#{index + 1}") }
                      table.td(started, align: :right)
                    end
                  end
                end
              end

              render NitroKit::Toast.new(
                duration: 600_000,
                label: "Operations notifications",
                id: "gallery-sidebar-application-toast"
              ) do |toast|
                toast.item(
                  title: "Production checks finished",
                  description: "Release 2026.07.13 is ready to promote.",
                  variant: :success
                )
              end
            end
          end
        end
      end

      def render_sidebar_empty
        render NitroKit::AppShell.new(
          id: "gallery-sidebar-application-empty",
          layout: :sidebar,
          data: {
            gallery_shell_preview: "true",
            gallery_application: "sidebar",
            gallery_application_state: "empty",
            theme: "light"
          }
        ) do |shell|
          shell.brand { strong { "Northstar Projects" } }
          shell.navigation do
            render_application_navigation(
              id: "gallery-sidebar-application-empty-navigation",
              current: :projects,
              context: "New workspace"
            )
          end
          shell.main do
            render_application_main do
              render NitroKit::PageHeader.new(
                title: "Projects",
                id: "gallery-sidebar-application-empty-header"
              )

              render NitroKit::DataSection.new(
                title: "Workspace projects",
                description: "Projects appear after their first successful import.",
                id: "gallery-sidebar-application-empty-section"
              ) do |section|
                section.empty_state(
                  NitroKit::EmptyState.new(
                    title: "No projects yet",
                    description: "Create a project manually or import a small evidence bundle.",
                    level: 3,
                    id: "gallery-sidebar-application-empty-state"
                  )
                ) do |empty|
                  empty.icon NitroKit::Icon.new(:folder)
                  empty.action NitroKit::Button.new("Create project", href: "#create-project", variant: :primary)
                end
              end

              render NitroKit::SettingsSection.new(
                title: "Import project evidence",
                description: "This example uses ordinary multipart submission and remains useful without JavaScript.",
                id: "gallery-sidebar-application-import"
              ) do |section|
                section.form do
                  form_with(
                    scope: :project_import,
                    url: "#import-project",
                    builder: NitroKit::FormBuilder,
                    id: "gallery-sidebar-application-import-form"
                  ) do |form|
                    form.group do
                      form.dropzone(
                        :files,
                        id: "gallery-sidebar-application-dropzone",
                        label: "Add project files",
                        description: "Up to three CSV, JSON, or text files.",
                        direct_upload: false,
                        multiple: true,
                        accept: ".csv,.json,text/plain",
                        max_files: 3,
                        max_bytes: 2 * 1024 * 1024
                      )
                      form.submit("Import files", id: "gallery-sidebar-application-import-submit")
                    end
                  end
                end
              end
            end
          end
        end
      end

      def render_sidebar_error
        render NitroKit::AppShell.new(
          id: "gallery-sidebar-application-error",
          layout: :sidebar,
          data: {
            gallery_shell_preview: "true",
            gallery_application: "sidebar",
            gallery_application_state: "error",
            theme: "dark"
          }
        ) do |shell|
          shell.brand { strong { "Northstar Reliability" } }
          shell.navigation do
            render_application_navigation(
              id: "gallery-sidebar-application-error-navigation",
              current: :incidents,
              context: "Degraded",
              dense: true
            )
          end
          shell.main do
            render_application_main(size: :lg) do
              render NitroKit::PageHeader.new(
                title: "Workspace synchronization incident",
                description: "The last verified snapshot remains available while the regional service recovers.",
                id: "gallery-sidebar-application-error-header"
              )

              render NitroKit::Alert.new(
                variant: :error,
                id: "gallery-sidebar-application-error-alert"
              ) do |alert|
                alert.icon NitroKit::Icon.new(:circle_x)
                alert.title("Live synchronization is unavailable")
                alert.description("No customer data was changed. Retry after reviewing the partial incident record below.")
              end

              render NitroKit::DetailsTable.new(
                INCIDENT,
                id: "gallery-sidebar-application-error-details"
              ) do |details|
                details.fields(:service, :region, :owner, :started_at, :last_update)
              end

              render NitroKit::Dialog.new(id: "gallery-sidebar-application-diagnostics") do |dialog|
                dialog.trigger("Review diagnostics", variant: :primary)
                dialog.panel(
                  title: "Regional diagnostics",
                  description: "The service is reachable, but the replication checkpoint is 14 minutes behind."
                ) do
                  render NitroKit::Badge.new("Read only", color: :warning, size: :sm)
                  dialog.close_button(label: "Close diagnostics")
                end
              end
            end
          end
        end
      end
    end
  end
end
