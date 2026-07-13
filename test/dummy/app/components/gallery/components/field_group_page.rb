module Gallery
  module Components
    class FieldGroupPage < ComponentPage
      private

      def source_note
        "app/components/nitro_kit/field_group.rb"
      end

      def api_note
        "NitroKit::FieldGroup.new { fields } or form.group { fields }"
      end

      def component_template
        example_section(
          "Grouping boundaries",
          slug: "field-group-boundaries",
          description: "FieldGroup owns layout only; native field meaning remains with its composed children."
        ) do
          example("Direct groups", slug: "field-group-direct", layout: :matrix) do
            sample("One field", slug: "one") do
              render NitroKit::FieldGroup.new(html: { id: "gallery-field-group-one" }) do
                render NitroKit::Field.new(
                  nil,
                  :workspace_name,
                  id: "gallery-field-group-workspace-name",
                  name: "workspace[name]",
                  value: "Mothership",
                  label: "Workspace name",
                  required: true
                )
              end
            end
            sample("Empty", slug: "empty") do
              render NitroKit::FieldGroup.new(html: { id: "gallery-field-group-empty" }) { nil }
            end
          end

          example("Mixed controls", slug: "field-group-mixed-controls") do
            render NitroKit::FieldGroup.new(html: { id: "gallery-field-group-mixed" }) do
              render NitroKit::Field.new(
                nil,
                :summary,
                as: :textarea,
                id: "gallery-field-group-summary",
                name: "workspace[summary]",
                value: "Release planning and production operations.",
                label: "Summary"
              )
              render NitroKit::Field.new(
                nil,
                :time_zone,
                as: :select,
                id: "gallery-field-group-time-zone",
                name: "workspace[time_zone]",
                value: "Europe/Copenhagen",
                label: "Time zone",
                options: Gallery::Forms::Profile::TIME_ZONES
              )
              render NitroKit::Field.new(
                nil,
                :weekly_digest,
                as: :checkbox,
                id: "gallery-field-group-weekly-digest",
                name: "workspace[weekly_digest]",
                label: "Send a weekly digest",
                checked: true
              )
              render NitroKit::Field.new(
                nil,
                :deployment_alerts,
                as: :switch,
                id: "gallery-field-group-deployment-alerts",
                name: "workspace[deployment_alerts]",
                label: "Deployment alerts",
                description: "Notify workspace owners after production deploys."
              )
            end
          end
        end

        example_section(
          "Rails form builder",
          slug: "field-group-builder",
          description: "Builder groups organize related model fields while Rails continues to own names, values, and errors."
        ) do
          example("Profile sections", slug: "field-group-profile-form") do
            profile = Gallery::FormExamples.profile(:invalid)

            form_with(
              model: profile,
              scope: :profile,
              url: "#profile-groups",
              builder: NitroKit::FormBuilder,
              id: "gallery-field-group-profile-form"
            ) do |form|
              form.group(html: { id: "gallery-field-group-profile-identity" }) do
                form.field(:name, id: "gallery-field-group-profile-name", required: true)
                form.field(
                  :email,
                  as: :email,
                  id: "gallery-field-group-profile-email",
                  description: "Used for account recovery.",
                  required: true
                )
              end
              form.group(html: { id: "gallery-field-group-profile-details" }) do
                form.field(
                  :bio,
                  as: :textarea,
                  id: "gallery-field-group-profile-bio",
                  description: "Shown to workspace members."
                )
                form.field(
                  :time_zone,
                  as: :select,
                  id: "gallery-field-group-profile-time-zone",
                  prompt: "Choose a time zone",
                  options: Gallery::Forms::Profile::TIME_ZONES,
                  required: true
                )
              end
              form.submit("Save profile", id: "gallery-field-group-profile-save")
            end
          end
        end

        example_section(
          "Long grouped form",
          slug: "field-group-pressure",
          description: "Long labels and guidance do not require a different grouping API."
        ) do
          example("Credential policy", slug: "field-group-credential-policy") do
            render NitroKit::FieldGroup.new(html: { id: "gallery-field-group-pressure" }) do
              render NitroKit::Field.new(
                nil,
                :rotation_window,
                as: :number,
                id: "gallery-field-group-rotation-window",
                name: "credential_policy[rotation_window]",
                value: 14,
                label: "Number of days before expiration when replacement credentials should be generated",
                description: "A notification is sent first; production credentials are never revoked until every target confirms receipt.",
                min: 1,
                max: 90,
                required: true
              )
              render NitroKit::Field.new(
                nil,
                :confirmation,
                as: :checkbox,
                id: "gallery-field-group-rotation-confirmation",
                name: "credential_policy[confirmation]",
                label: "Require owner confirmation before revoking the previous production credential",
                checked: true
              )
            end
          end
        end
      end
    end
  end
end
