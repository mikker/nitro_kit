module Gallery
  module Compositions
    class TopbarApplicationPage < ApplicationPage
      MEDIA_ITEMS = [
        [ "Ada launch interview", "Ready for review", :healthy ],
        [ "Analytical engine field notes", "Encoding captions", :waiting ],
        [ "Production workspace tour", "Scheduled tomorrow", :queued ]
      ].freeze

      private

      def application_template
        application_section(
          "Editorial workspace states",
          slug: "topbar-application-states",
          description: "A horizontal application frame carries a populated media library, an honest loading view, and long operational content without cloning navigation."
        ) do
          application_example(
            "Populated light library",
            slug: "topbar-application-populated",
            description: "Progressive media, per-record menus, header actions, and a saved-result toast exercise a complete content workflow.",
            source: :render_topbar_populated
          ) { render_topbar_populated }

          application_example(
            "Loading system library",
            slug: "topbar-application-loading",
            description: "Busy semantics, progressive image placeholders, and disabled actions keep partial server output understandable.",
            source: :render_topbar_loading
          ) { render_topbar_loading }

          application_example(
            "Long dark release archive",
            slug: "topbar-application-long",
            description: "Long titles, sortable records, and a native release dialog pressure the topbar layout without application classes.",
            source: :render_topbar_long
          ) { render_topbar_long }
        end
      end

      def render_topbar_populated
        render NitroKit::AppShell.new(
          id: "gallery-topbar-application-populated",
          layout: :topbar,
          data: {
            gallery_shell_preview: "true",
            gallery_application: "topbar",
            gallery_application_state: "populated",
            theme: "light"
          }
        ) do |shell|
          shell.brand { strong { "Northstar Studio" } }
          shell.navigation do
            render_application_navigation(
              id: "gallery-topbar-application-populated-navigation",
              current: :projects,
              context: "Editorial",
              compact: true
            )
          end
          shell.topbar do
            render NitroKit::ButtonGroup.new(label: "Library actions") do |group|
              group.button("Search", href: "#search", variant: :ghost, size: :sm, icon: :search)
              group.button("Upload", href: "#upload", variant: :primary, size: :sm, icon: :upload)
            end
          end
          shell.main do
            render_application_main do
              render NitroKit::PageHeader.new(
                title: "Media library",
                description: "Review interviews, workspace tours, and release media before publication.",
                id: "gallery-topbar-application-populated-header"
              )

              render NitroKit::Grid.new(cols: "1 sm:2 lg:3", id: "gallery-topbar-application-media-grid") do
                MEDIA_ITEMS.each_with_index do |(title, detail, status), index|
                  render NitroKit::Card.new(id: "gallery-topbar-application-media-#{index + 1}") do |card|
                    card.full do
                      render NitroKit::ProgressiveImage.new(
                        attachment: demo_attachment,
                        alt: "Abstract workspace cover for #{title}",
                        size: :sm,
                        id: "gallery-topbar-application-image-#{index + 1}"
                      )
                    end
                    card.title(title, level: 3)
                    card.body do
                      render NitroKit::Flex.new(dir: :col, gap: 2, align: :start) do
                        status_badge(status, id: "gallery-topbar-application-media-status-#{index + 1}")
                        p { detail }
                      end
                    end
                    card.footer do
                      render NitroKit::Dropdown.new(id: "gallery-topbar-application-menu-#{index + 1}") do |menu|
                        menu.trigger("Media actions", variant: :ghost, size: :sm)
                        menu.item("Open details", href: "#media-#{index + 1}")
                        menu.item("Duplicate")
                        menu.separator
                        menu.item("Archive", variant: :destructive)
                      end
                    end
                  end
                end
              end

              render NitroKit::Toast.new(
                duration: 600_000,
                label: "Editorial notifications",
                id: "gallery-topbar-application-toast"
              ) do |toast|
                toast.item(
                  title: "Caption draft saved",
                  description: "The review team can now comment on the latest transcript.",
                  variant: :success
                )
              end
            end
          end
        end
      end

      def render_topbar_loading
        render NitroKit::AppShell.new(
          id: "gallery-topbar-application-loading",
          layout: :topbar,
          aria: { busy: true },
          data: {
            gallery_shell_preview: "true",
            gallery_application: "topbar",
            gallery_application_state: "loading"
          }
        ) do |shell|
          shell.brand { strong { "Northstar Studio" } }
          shell.navigation do
            render_application_navigation(
              id: "gallery-topbar-application-loading-navigation",
              current: :projects,
              context: "Loading",
              compact: true
            )
          end
          shell.topbar do
            render NitroKit::Button.new("Upload", disabled: true, size: :sm, icon: :upload)
          end
          shell.main do
            render_application_main do
              render NitroKit::PageHeader.new(
                title: "Loading the media library",
                description: "Previously verified navigation remains available while records and image variants arrive.",
                id: "gallery-topbar-application-loading-header"
              )

              render NitroKit::Alert.new(id: "gallery-topbar-application-loading-alert") do |alert|
                alert.title("Refreshing three media records")
                alert.description("Actions remain unavailable until the current library snapshot is complete.")
              end

              render NitroKit::Grid.new(cols: "1 sm:2 lg:3", id: "gallery-topbar-application-loading-grid") do
                3.times do |index|
                  render NitroKit::Card.new(id: "gallery-topbar-application-loading-card-#{index + 1}") do |card|
                    card.full do
                      render NitroKit::ProgressiveImage.new(
                        attachment: demo_attachment,
                        alt: "Loading media preview #{index + 1}",
                        size: :sm,
                        id: "gallery-topbar-application-loading-image-#{index + 1}"
                      )
                    end
                    card.title("Loading record #{index + 1}", level: 3)
                    card.body { p { "Metadata and publication status are still being verified." } }
                    card.footer do
                      render NitroKit::Button.new("Open record", disabled: true, size: :sm)
                    end
                  end
                end
              end
            end
          end
        end
      end

      def render_topbar_long
        render NitroKit::AppShell.new(
          id: "gallery-topbar-application-long",
          layout: :topbar,
          data: {
            gallery_shell_preview: "true",
            gallery_application: "topbar",
            gallery_application_state: "long",
            theme: "dark"
          }
        ) do |shell|
          shell.brand { strong { "International Research Publishing" } }
          shell.navigation do
            render_application_navigation(
              id: "gallery-topbar-application-long-navigation",
              current: :projects,
              context: "Release archive",
              compact: true
            )
          end
          shell.topbar do
            render NitroKit::Dialog.new(id: "gallery-topbar-application-release-dialog") do |dialog|
              dialog.trigger("Release notes", size: :sm)
              dialog.panel(
                title: "Publish the international reliability archive?",
                description: "The archive includes reviewed field notes from research, production reliability, regulatory operations, and customer support."
              ) do
                render NitroKit::Badge.new("12 reviewed records", color: :info, size: :sm)
                dialog.close_button(label: "Keep as draft")
              end
            end
          end
          shell.main do
            render_application_main do
              render NitroKit::PageHeader.new(
                title: "International analytical engine reliability, production readiness, and cross-regional incident response archive",
                description: "Long caller-owned content wraps inside the application canvas while navigation, actions, and sortable record columns retain their own geometry.",
                id: "gallery-topbar-application-long-header"
              )

              render NitroKit::Table.new(
                sort: :updated,
                direction: :desc,
                id: "gallery-topbar-application-long-table"
              ) do |table|
                table.caption("Reviewed release records")
                table.thead do
                  table.tr do
                    table.th(sort: :record, href: "?sort=record-asc")
                    table.th(sort: :owner, href: "?sort=owner-asc")
                    table.th(sort: :status, href: "?sort=status-asc")
                    table.th(sort: :updated, href: "?sort=updated-asc", align: :right)
                  end
                end
                table.tbody do
                  [
                    [ "International Research and Production readiness review", "Ada Lovelace", :healthy, "Jul 13" ],
                    [ "Cross-regional incident response and operational handoff", "Grace Hopper", :waiting, "Jul 12" ],
                    [ "Regulatory evidence retention and customer communication", "Katherine Johnson", :queued, "Jul 11" ]
                  ].each_with_index do |(record, owner, status, updated), index|
                    table.tr do
                      table.th(record, scope: :row)
                      table.td(owner)
                      table.td { status_badge(status, id: "gallery-topbar-application-long-status-#{index + 1}") }
                      table.td(updated, align: :right)
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
