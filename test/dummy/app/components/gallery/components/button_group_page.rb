module Gallery
  module Components
    class ButtonGroupPage < ComponentPage
      private

      def source_note
        "app/components/nitro_kit/button_group.rb"
      end

      def api_note
        "NitroKit::ButtonGroup.new(label:) { |group| group.button }"
      end

      def component_template
        example_section(
          "Member counts",
          slug: "button-group-counts",
          description: "One, two, and larger groups share the same labelled native group contract."
        ) do
          example("Count scale", slug: "button-group-count-scale", layout: :matrix) do
            sample("One action", slug: "one") do
              render NitroKit::ButtonGroup.new(
                id: "gallery-button-group-one",
                label: "Single record action",
                buttons: [
                  NitroKit::Button.new(
                    "Edit",
                    id: "gallery-button-group-one-edit",
                    icon: :pencil
                  )
                ]
              )
            end
            sample("Two actions", slug: "two") do
              render NitroKit::ButtonGroup.new(
                id: "gallery-button-group-two",
                label: "Form actions"
              ) do |group|
                group.button("Save", id: "gallery-button-group-two-save", variant: :primary)
                group.button("Cancel", id: "gallery-button-group-two-cancel", variant: :ghost)
              end
            end
            sample("Four actions", slug: "four") do
              render NitroKit::ButtonGroup.new(
                id: "gallery-button-group-four",
                label: "Document actions"
              ) do |group|
                group.button("Open", id: "gallery-button-group-four-open")
                group.button("Duplicate", id: "gallery-button-group-four-duplicate")
                group.button("Archive", id: "gallery-button-group-four-archive")
                group.button("Delete", id: "gallery-button-group-four-delete", variant: :destructive)
              end
            end
          end
        end

        example_section(
          "Mixed actions",
          slug: "button-group-content",
          description: "Buttons, links, leading and trailing icons, long labels, blocks, and disabled state can coexist."
        ) do
          example("Mixed member contract", slug: "button-group-mixed-members", mode: :full_width) do
            render NitroKit::ButtonGroup.new(
              id: "gallery-button-group-mixed",
              label: "Audit record actions"
            ) do |group|
              group.button(
                "Return to audit log",
                id: "gallery-button-group-mixed-back",
                href: "#audit-log",
                icon: :arrow_left
              )
              group.button(
                "Export every selected record as a comma-separated value file",
                id: "gallery-button-group-mixed-export",
                href: "#audit-export",
                icon: :download
              )
              group.button(
                "Archive",
                id: "gallery-button-group-mixed-archive",
                icon_right: :archive,
                disabled: true
              )
              group.button(
                id: "gallery-button-group-mixed-delete",
                icon: :trash_2,
                variant: :destructive,
                aria: { label: "Delete selected audit records" }
              )
              group.button(id: "gallery-button-group-mixed-block") { "Block-provided action" }
            end
          end
        end

        example_section(
          "Record toolbar",
          slug: "button-group-record-toolbar",
          description: "Card, Badge, ButtonGroup, and Button compose into a focused record toolbar."
        ) do
          example("API credential", slug: "button-group-api-credential") do
            render NitroKit::Card.new(id: "gallery-button-group-record-card") do |card|
              card.title("Production API key", level: 3)
              card.body do
                render NitroKit::Badge.new(
                  "Read and write",
                  id: "gallery-button-group-record-access",
                  color: :info,
                  size: :sm
                )
                p { "nk_live_7P3F · Last used July 13, 2026 at 08:31 UTC" }
              end
              card.footer do
                render NitroKit::ButtonGroup.new(
                  id: "gallery-button-group-record-actions",
                  label: "Production API key actions"
                ) do |group|
                  group.button(
                    "Copy prefix",
                    id: "gallery-button-group-record-copy",
                    icon: :copy
                  )
                  group.button(
                    "Rotate key",
                    id: "gallery-button-group-record-rotate",
                    icon: :refresh_cw
                  )
                  group.button(
                    "Revoke",
                    id: "gallery-button-group-record-revoke",
                    variant: :destructive,
                    icon: :trash_2
                  )
                end
              end
            end
          end
        end

        example_section(
          "Table toolbar",
          slug: "button-group-table-toolbar",
          description: "A labelled bulk-action group remains separate from the semantic records table it controls."
        ) do
          example("Selected members", slug: "button-group-selected-members", mode: :full_width) do
            render NitroKit::ButtonGroup.new(
              id: "gallery-button-group-table-actions",
              label: "Two selected member actions"
            ) do |group|
              group.button("Change role", id: "gallery-button-group-table-role", icon: :user_cog)
              group.button("Deactivate", id: "gallery-button-group-table-deactivate", disabled: true)
              group.button(
                "Remove",
                id: "gallery-button-group-table-remove",
                variant: :destructive,
                icon: :user_minus
              )
            end

            render NitroKit::Table.new(
              id: "gallery-button-group-members-table",
              table_html: { id: "gallery-button-group-members-table-element" }
            ) do |table|
              table.caption("Selected workspace members")
              table.thead do
                table.tr do
                  table.th("Name")
                  table.th("Role")
                  table.th("Status", align: :right)
                end
              end
              table.tbody do
                Gallery::Data.members.first(2).each do |member|
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
      end
    end
  end
end
