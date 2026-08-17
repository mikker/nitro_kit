module Gallery
  module Compositions
    class OrganizationSettingsPage < ExpandedPage
      private

      def render_state
        render NitroKit::SettingsLayout.new(id: "gallery-organization-settings-layout") do |layout|
          layout.navigation(label: "Organization settings sections") do
            %w[general access integrations].each do |section|
              layout.item(
                section.humanize,
                href: flow_path(state: section),
                current: settings_section == section
              )
            end
          end
          layout.content do
            case settings_section
            when "general"
              render_general_settings
            when "access"
              render_access_settings
            when "integrations"
              render_integration_settings
            end
          end
        end
      end

      def render_general_settings
        form = organization_form
        disabled = !policy.manage_organization?

        render NitroKit::SettingsSection.new(
          title: "Organization identity",
          description: "Manage the name, URL, member defaults, and security notices used across the organization.",
          id: "gallery-organization-settings-settings-section"
        ) do |section|
          render_form_status(section, form)
          section.form do
            form_with(
              model: form,
              scope: :organization,
              url: flow_path(state: "general"),
              builder: NitroKit::FormBuilder,
              id: "gallery-organization-settings-form"
            ) do |builder|
              builder.fieldset(
                legend: "Identity and member defaults",
                description: "Changes affect member navigation and customer-visible exports.",
                disabled:,
                html: { id: "gallery-organization-settings-fieldset" }
              ) do
                builder.group do
                  builder.field(:name, required: true, disabled:)
                  builder.field(
                    :slug,
                    required: true,
                    description: "Lowercase letters, numbers, and hyphens only.",
                    disabled:
                  )
                  builder.field(
                    :default_role,
                    as: :select,
                    label: "Default member role",
                    options: [ [ "Member", "member" ], [ "Viewer", "viewer" ] ],
                    disabled:
                  )
                  builder.field(
                    :security_notifications,
                    as: :switch,
                    label: "Security notifications",
                    description: "Notify organization owners after access policy changes.",
                    disabled:
                  )
                end
              end
              render NitroKit::Toolbar.new(id: "gallery-organization-settings-form-toolbar") do |toolbar|
                toolbar.trailing do
                  builder.submit(
                    disabled ? "Owner access required" : "Save organization",
                    id: "gallery-organization-settings-submit",
                    disabled:,
                    data: { turbo_submits_with: "Saving organization…" }
                  )
                end
              end
            end
          end
        end
      end

      def render_form_status(section, form)
        case state
        when "validation"
          section.status(NitroKit::Alert.new(variant: :destructive, id: "gallery-organization-settings-validation")) do |alert|
            alert.title("Organization settings need attention")
            alert.description(form.errors.full_messages.to_sentence)
          end
        when "success"
          section.status(NitroKit::Alert.new(variant: :success, id: "gallery-organization-settings-success")) do |alert|
            alert.title("Organization settings saved")
            alert.description("Identity, member defaults, and security notifications are current.")
          end
        when "error"
          section.status(NitroKit::Alert.new(variant: :warning, id: "gallery-organization-settings-policy")) do |alert|
            alert.title("Owner access required")
            alert.description("This signed-in viewer can inspect organization settings but cannot change them.")
          end
        end
      end

      def render_access_settings
        members = Gallery::Data.members

        render NitroKit::DataSection.new(
          title: "Organization access",
          description: "Review what each member can do before changing organization access.",
          id: "gallery-organization-settings-access"
        ) do |section|
          section.actions(NitroKit::ButtonGroup.new(label: "Organization access actions")) do |actions|
            actions.button("Export access report", href: "#export-access")
            actions.button("Invite administrator", href: "#invite-administrator", variant: :primary)
          end
          section.table(NitroKit::Table.new(
            id: "gallery-organization-settings-access-table",
            table_aria: { label: "Members with organization access" }
          )) do |table|
            table.caption("Members with organization access")
            table.thead do
              table.tr do
                table.th("Member")
                table.th("Role")
                table.th("Can remove", align: :right)
              end
            end
            table.tbody do
              members.each do |member|
                table.tr do
                  table.th(member.name, scope: :row)
                  table.td(member.role.to_s.humanize)
                  table.td(policy.remove_member?(member) ? "Yes" : "No", align: :right)
                end
              end
            end
          end
        end
      end

      def render_integration_settings
        render NitroKit::DataSection.new(
          title: "Organization integrations",
          description: "Monitor connected services and resolve provider actions that interrupt delivery.",
          id: "gallery-organization-settings-integrations"
        ) do |section|
          section.actions(NitroKit::ButtonGroup.new(label: "Organization integration actions")) do |actions|
            actions.button("Connect service", href: "#connect-integration", variant: :primary)
          end
          section.table(NitroKit::Table.new(
            id: "gallery-organization-settings-integrations-table",
            table_aria: { label: "Connected organization services" }
          )) do |table|
            table.caption("Connected organization services")
            table.thead do
              table.tr do
                table.th("Service")
                table.th("Status")
                table.th("Connected")
              end
            end
            table.tbody do
              Gallery::Data.integrations.each do |integration|
                table.tr do
                  table.th(integration.name, scope: :row)
                  table.td do
                    render NitroKit::Badge.new(
                      integration.status.to_s.humanize,
                      color: integration.status == :action_required ? :warning : :info,
                      size: :sm
                    )
                  end
                  table.td(integration.connected_at&.to_fs(:long) || "Not connected")
                end
              end
            end
          end
        end
      end

      def organization_form
        attributes = {
          name: state == "long" ? "Analytical Engines — International Research, Production, Reliability Engineering, and Customer Operations" : Gallery::ExpandedData.organization.name,
          slug: Gallery::ExpandedData.organization.slug,
          default_role: "member",
          security_notifications: true
        }
        attributes[:slug] = "Not a valid slug" if state == "validation"

        Gallery::Forms::OrganizationSettings.new(attributes).tap do |form|
          form.valid? if state == "validation"
        end
      end

      def policy
        Gallery::ExpandedAccessPolicy.new(role: state == "error" ? :viewer : :owner)
      end

      def settings_section
        return "access" if state == "access"
        return "integrations" if state == "integrations"

        "general"
      end

      def screen_title
        return "Organization settings for Analytical Engines — International Research and Production" if state == "long"

        "Organization settings"
      end

      def header_actions(actions)
        actions.button(
          "Organization overview",
          href: gallery_composition_path(slug: "organization-overview", state: "active")
        )
        actions.button("Review audit log", href: "#organization-audit", variant: :primary)
      end

      def state_description
        {
          "general" => "Editable organization identity and member defaults backed by a real Active Model form.",
          "access" => "Application-owned authorization decisions beside organization member roles.",
          "integrations" => "Connected service status in the same two-region settings layout.",
          "validation" => "Server validation keeps invalid values and accessible field errors visible.",
          "success" => "A successful result leaves the editable settings form in place.",
          "error" => "A viewer can inspect settings while owner-only changes stay disabled.",
          "long" => "Long organization identity values pressure labels, fields, headings, and actions.",
          "mobile" => "The accepted SettingsLayout and Toolbar own narrow stacking without a mobile API."
        }.fetch(state)
      end
    end
  end
end
