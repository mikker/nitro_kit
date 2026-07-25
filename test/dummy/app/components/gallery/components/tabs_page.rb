module Gallery
  module Components
    class TabsPage < ComponentPage
      private

      def source_note
        "app/components/nitro_kit/tabs.rb"
      end

      def api_note
        "NitroKit::Tabs.new(id:, default:) { |tabs| tabs.tab(key, label) { panel } }"
      end

      def component_template
        example_section(
          "Workspace settings",
          slug: "tabs-settings",
          description: "Each declaration owns its panel; all panels remain readable until Stimulus enhances the APG tab behavior."
        ) do
          example("Settings sections", slug: "tabs-settings-sections") do
            render NitroKit::Tabs.new(
              id: "gallery-tabs-settings",
              default: :members,
              label: "Workspace settings"
            ) do |tabs|
              tabs.tab(:general, "General") { "Workspace name and regional preferences." }
              tabs.tab(:members, "Members") { "Manage roles, invitations, and access." }
              tabs.tab(:billing, "Billing") { "Review plan, payment method, and invoices." }
            end
          end
        end

        example_section(
          "Orientation and activation",
          slug: "tabs-behavior",
          description: "Horizontal and vertical tablists expose automatic or manual keyboard activation after enhancement."
        ) do
          example("Vertical manual tabs", slug: "tabs-vertical-manual") do
            render NitroKit::Tabs.new(
              id: "gallery-tabs-vertical-manual",
              default: :security,
              label: "Account controls",
              orientation: :vertical,
              activation: :manual
            ) do |tabs|
              tabs.tab(:profile, "Profile") { "Name, photo, and public account details." }
              tabs.tab(:security, "Security") { "Password, recovery codes, and active sessions." }
              tabs.tab(:notifications, "Notifications") { "Email and workspace notification preferences." }
              tabs.tab(:legacy, "Legacy authentication", disabled: true) do
                "Legacy authentication is unavailable for new workspaces."
              end
            end
          end

          example("Single tab", slug: "tabs-single") do
            render NitroKit::Tabs.new(id: "gallery-tabs-one", label: "Release information") do |tabs|
              tabs.tab(:summary, "Summary") { "Release 1842 is operational in the EU region." }
            end
          end
        end

        example_section(
          "Content pressure",
          slug: "tabs-pressure",
          description: "Many tabs, long labels, long panel copy, and disabled choices retain deterministic relationships."
        ) do
          example("Many long tabs", slug: "tabs-many-long") do
            render NitroKit::Tabs.new(
              id: "gallery-tabs-pressure",
              default: :regional_preferences,
              label: "Extended workspace administration"
            ) do |tabs|
              tabs.tab(:general, "General") { "Workspace identity and ownership." }
              tabs.tab(:regional_preferences, "Regional preferences and time-zone behavior") do
                p do
                  "Dates use the workspace locale while audit timestamps retain their original UTC value. " \
                    "Individual members may choose a different display time zone without changing stored events."
                end
              end
              tabs.tab(:members, "Members") { "Roles, invitations, and deactivation." }
              tabs.tab(:security, "Security") { "Sessions, recovery, and authentication policies." }
              tabs.tab(:integrations, "Integrations") { "Connected services and delivery status." }
              tabs.tab(:billing, "Billing") { "Plan, payment method, and invoice history." }
              tabs.tab(:legacy, "Legacy provisioning", disabled: true) do
                "Legacy provisioning is no longer available."
              end
            end
          end
        end

        example_section(
          "Settings composition",
          slug: "tabs-settings-composition",
          description: "A complete settings surface nests forms, cards, status, tables, and grouped actions in panels."
        ) do
          example("Workspace administration", slug: "tabs-workspace-administration") do
            render NitroKit::Tabs.new(
              id: "gallery-tabs-administration",
              default: :profile,
              label: "Workspace administration",
              orientation: :vertical,
              activation: :manual
            ) do |tabs|
              tabs.tab(:profile, "Profile") { render_profile_settings }
              tabs.tab(:members, "Members") { render_member_settings }
              tabs.tab(:billing, "Billing") { render_billing_settings }
            end
          end
        end
      end

      def render_profile_settings
        render NitroKit::Card.new(id: "gallery-tabs-profile-card") do |card|
          card.title("Workspace profile", level: 3)
          card.body do
            form(id: "gallery-tabs-profile-form", action: "#workspace-profile", method: "post") do
              render NitroKit::Field.new(
                nil,
                :name,
                id: "gallery-tabs-profile-name",
                name: "workspace[name]",
                value: "Mothership",
                label: "Workspace name",
                required: true
              )
              render NitroKit::Field.new(
                nil,
                :time_zone,
                id: "gallery-tabs-profile-time-zone",
                name: "workspace[time_zone]",
                value: "Europe/Copenhagen",
                label: "Time zone",
                description: "Used for reports and scheduled notifications."
              )
            end
          end
          card.footer do
            render NitroKit::ButtonGroup.new(
              id: "gallery-tabs-profile-actions",
              label: "Workspace profile actions"
            ) do |group|
              group.button(
                "Save changes",
                id: "gallery-tabs-profile-save",
                type: :submit,
                form: "gallery-tabs-profile-form",
                variant: :primary,
                size: :sm
              )
              group.button(
                "Reset",
                id: "gallery-tabs-profile-reset",
                type: :reset,
                form: "gallery-tabs-profile-form",
                size: :sm
              )
            end
          end
        end
      end

      def render_member_settings
        render NitroKit::Card.new(id: "gallery-tabs-members-card") do |card|
          card.title("Members", level: 3)
          card.body do
            render NitroKit::Table.new(
              id: "gallery-tabs-members-table",
              table_html: { id: "gallery-tabs-members-table-element" }
            ) do |table|
              table.caption("Workspace member access")
              table.thead do
                table.tr do
                  table.th("Member")
                  table.th("Role")
                  table.th("Status", align: :right)
                end
              end
              table.tbody do
                Gallery::Data.members.each do |member|
                  table.tr do
                    table.th(member.name, scope: :row)
                    table.td(member.role.to_s.humanize)
                    table.td(align: :right) do
                      render NitroKit::Badge.new(
                        member.status.to_s.humanize,
                        id: "gallery-tabs-member-#{member.id}-status",
                        color: member.status == :active ? :success : :warning,
                        size: :sm
                      )
                    end
                  end
                end
              end
            end
          end
          card.footer do
            render NitroKit::Button.new(
              "Invite member",
              id: "gallery-tabs-members-invite",
              href: "#invite-member",
              variant: :primary,
              size: :sm,
              icon: :user_plus
            )
          end
        end
      end

      def render_billing_settings
        render NitroKit::Card.new(id: "gallery-tabs-billing-card") do |card|
          card.title("Team plan", level: 3)
          card.body do
            render NitroKit::Badge.new(
              "Current plan",
              id: "gallery-tabs-billing-status",
              variant: :outline,
              color: :info
            )
            p { "USD 49.00 monthly · renews August 1, 2026" }
          end
          card.footer do
            render NitroKit::ButtonGroup.new(
              id: "gallery-tabs-billing-actions",
              label: "Billing actions"
            ) do |group|
              group.button(
                "Change plan",
                id: "gallery-tabs-billing-change",
                href: "#change-plan",
                size: :sm
              )
              group.button(
                "View invoices",
                id: "gallery-tabs-billing-invoices",
                href: "#invoices",
                size: :sm
              )
            end
          end
        end
      end
    end
  end
end
