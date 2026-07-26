module Gallery
  module Compositions
    class DataResourceSettingsPage < ExpandedPage
      private

      def render_state
        render NitroKit::SettingsLayout.new(id: "gallery-data-resource-settings-layout") do |layout|
          layout.navigation(label: "Data resource settings sections") do
            %w[general access danger].each do |section|
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
            when "danger"
              render_danger_settings
            end
          end
        end
      end

      def render_general_settings
        form = resource_form
        disabled = !policy.manage_resources?

        render NitroKit::FormSection.new(
          title: "Resource configuration",
          description: "Identity, visibility, retention, and notifications remain application-owned values.",
          id: "gallery-data-resource-settings-form-section"
        ) do |section|
          render_form_status(section, form)
          section.form do
            form_with(
              model: form,
              scope: :resource,
              url: flow_path(state: "general"),
              builder: NitroKit::FormBuilder,
              id: "gallery-data-resource-settings-form"
            ) do |builder|
              builder.fieldset(
                legend: "Resource configuration",
                description: "Retention changes apply to new records after the next successful synchronization.",
                disabled:,
                html: { id: "gallery-data-resource-settings-fieldset" }
              ) do
                builder.group do
                  builder.field(:name, required: true, disabled:)
                  builder.field(
                    :visibility,
                    as: :select,
                    options: Gallery::Forms::ResourceSettings::VISIBILITIES.map { |visibility| [ visibility.humanize, visibility ] },
                    disabled:
                  )
                  builder.field(
                    :retention_days,
                    as: :select,
                    label: "Retention period",
                    options: Gallery::Forms::ResourceSettings::RETENTION_PERIODS.map { |days| [ "#{days} days", days ] },
                    disabled:
                  )
                  builder.field(
                    :notify_failures,
                    as: :switch,
                    label: "Failure notifications",
                    description: "Notify resource owners after imports or synchronization fail.",
                    disabled:
                  )
                end
              end
              render NitroKit::Toolbar.new(id: "gallery-data-resource-settings-form-toolbar") do |toolbar|
                toolbar.trailing do
                  builder.submit(
                    disabled ? "Administrator access required" : "Save resource",
                    id: "gallery-data-resource-settings-submit",
                    disabled:,
                    data: { turbo_submits_with: "Saving resource…" }
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
          section.status(NitroKit::Alert.new(variant: :error, id: "gallery-data-resource-settings-validation")) do |alert|
            alert.title("Resource settings need attention")
            alert.description(form.errors.full_messages.to_sentence)
          end
        when "success"
          section.status(NitroKit::Alert.new(variant: :success, id: "gallery-data-resource-settings-success")) do |alert|
            alert.title("Resource settings saved")
            alert.description("Identity, retention, visibility, and notifications are current.")
          end
        when "error"
          section.status(NitroKit::Alert.new(variant: :warning, id: "gallery-data-resource-settings-policy")) do |alert|
            alert.title("Administrator access required")
            alert.description("This signed-in viewer can inspect resource settings but cannot change them.")
          end
        end
      end

      def render_access_settings
        resource = selected_resource

        render NitroKit::DataSection.new(
          title: "Resource access",
          description: "The application policy resolves mutation and deletion decisions for this resource.",
          id: "gallery-data-resource-settings-access"
        ) do |section|
          section.actions(NitroKit::ButtonGroup.new(label: "Resource access actions")) do |actions|
            actions.button("Export access report", href: "#export-resource-access")
            actions.button("Add team", href: "#add-resource-team", variant: :primary)
          end
          section.table(NitroKit::Table.new(id: "gallery-data-resource-settings-access-table")) do |table|
            table.caption("Access decisions for #{resource.name}")
            table.thead do
              table.tr do
                table.th("Role")
                table.th("Read records")
                table.th("Manage settings")
                table.th("Delete resource")
              end
            end
            table.tbody do
              %i[owner administrator member viewer].each do |role|
                access_policy = Gallery::ExpandedAccessPolicy.new(role:)
                table.tr do
                  table.th(role.to_s.humanize, scope: :row)
                  table.td("Yes")
                  table.td(access_policy.manage_resources? ? "Yes" : "No")
                  table.td(access_policy.delete_resource?(resource) ? "Yes" : "No")
                end
              end
            end
          end
        end
      end

      def render_danger_settings
        action = Gallery::Forms::ResourceBulkAction.new(
          resource_ids: [ selected_resource.id ],
          action: "archive",
          confirmed: false
        )

        render NitroKit::DangerZone.new(
          title: "Archive #{selected_resource.name}",
          description: "Imports stop immediately. Existing records remain read-only for the configured retention period.",
          id: "gallery-data-resource-settings-danger"
        ) do |zone|
          zone.confirmation do
            render NitroKit::Alert.new(id: "gallery-data-resource-settings-danger-warning", variant: :warning) do |alert|
              alert.title("Synchronization will stop")
              alert.description("Applications using this resource must switch to another source before archival.")
            end
            form_with(
              model: action,
              scope: :archive_resource,
              url: "#archive-resource",
              builder: NitroKit::FormBuilder,
              id: "gallery-data-resource-settings-danger-form"
            ) do |form|
              form.group do
                render NitroKit::Input.new(
                  type: :hidden,
                  name: "archive_resource[action]",
                  value: action.action
                )
                render NitroKit::Input.new(
                  type: :hidden,
                  name: "archive_resource[resource_ids][]",
                  value: selected_resource.id
                )
                form.field(
                  :confirmed,
                  as: :checkbox,
                  label: "I understand imports will stop for this resource",
                  required: true
                )
                form.submit(
                  "Archive resource",
                  id: "gallery-data-resource-settings-danger-submit",
                  variant: :destructive,
                  disabled: !policy.delete_resource?(selected_resource),
                  data: { turbo_submits_with: "Archiving resource…" }
                )
              end
            end
          end
          zone.escape(
            NitroKit::Button.new(
              "Return to general settings",
              href: flow_path(state: "general")
            )
          )
        end
      end

      def resource_form
        attributes = {
          name: state == "long" ? long_resource_name : selected_resource.name,
          visibility: "organization",
          retention_days: selected_resource.retention_days,
          notify_failures: true
        }
        attributes[:name] = "" if state == "validation"

        Gallery::Forms::ResourceSettings.new(attributes).tap do |form|
          form.valid? if state == "validation"
        end
      end

      def selected_resource
        Gallery::ExpandedData.resources.first
      end

      def policy
        Gallery::ExpandedAccessPolicy.new(role: state == "error" ? :viewer : :owner)
      end

      def settings_section
        return "access" if state == "access"
        return "danger" if state == "danger"

        "general"
      end

      def long_resource_name
        "Customer accounts for International Research, Production, Reliability Engineering, and Customer Operations"
      end

      def screen_title
        state == "long" ? "Settings for #{long_resource_name}" : "Customer accounts settings"
      end

      def header_actions(actions)
        actions.button("All resources", href: overview_path)
        actions.button("Resource activity", href: activity_path, variant: :primary)
      end

      def overview_path
        gallery_composition_path(slug: "data-resource-overview", state: "index")
      end

      def activity_path
        gallery_composition_path(slug: "data-resource-activity", state: "recent")
      end

      def state_description
        {
          "general" => "Editable resource identity, visibility, retention, and notifications backed by Active Model.",
          "validation" => "Server validation keeps invalid values and accessible field errors visible.",
          "success" => "A successful result leaves the editable resource settings in place.",
          "access" => "Application-owned policy decisions appear beside role-level resource access.",
          "danger" => "Archival requires explicit confirmation, policy permission, and a safe escape.",
          "error" => "A viewer can inspect settings while the caller-owned policy disables mutation.",
          "long" => "A long resource identity pressures headings, labels, fields, and actions.",
          "mobile" => "SettingsLayout and Toolbar own narrow stacking without a mobile API."
        }.fetch(state)
      end
    end
  end
end
