module Gallery
  module Components
    class FieldsetPage < ComponentPage
      private

      def source_note
        "app/components/nitro_kit/fieldset.rb"
      end

      def api_note
        "NitroKit::Fieldset.new(legend:, description:, disabled:) { fields }"
      end

      def component_template
        example_section(
          "Semantic boundaries",
          slug: "fieldset-boundaries",
          description: "A native fieldset owns one legend, optional guidance, and an explicit fields region."
        ) do
          example("Boundary states", slug: "fieldset-boundary-states", layout: :matrix) do
            sample("Empty", slug: "empty") do
              render NitroKit::Fieldset.new(
                legend: "Optional advanced settings",
                description: "No advanced settings are available for this plan.",
                html: { id: "gallery-fieldset-empty" }
              ) { nil }
            end
            sample("Disabled", slug: "disabled") do
              render NitroKit::Fieldset.new(
                legend: "Legacy synchronization",
                description: "Locked while migration is in progress.",
                disabled: true,
                name: "legacy-sync",
                html: { id: "gallery-fieldset-disabled" }
              ) do
                render NitroKit::Field.new(
                  nil,
                  :destination,
                  id: "gallery-fieldset-disabled-destination",
                  name: "legacy[destination]",
                  value: "Compliance archive",
                  label: "Destination"
                )
              end
            end
          end

          example("Compound legend and description", slug: "fieldset-compound-content") do
            render NitroKit::Fieldset.new(html: { id: "gallery-fieldset-compound" }) do |fieldset|
              fieldset.legend("Deployment targets")
              fieldset.description do
                plain "Production changes require "
                strong { "two" }
                plain " approvals."
              end
              render NitroKit::Field.new(
                nil,
                :approvers,
                as: :number,
                id: "gallery-fieldset-compound-approvers",
                name: "deployment[approvers]",
                value: 2,
                label: "Required approvers",
                min: 1,
                max: 5
              )
            end
          end

          example("Long policy section", slug: "fieldset-long-policy") do
            render NitroKit::Fieldset.new(
              legend: "Production credential rotation and revocation policy for deployment targets",
              description: "Replacement credentials are distributed before the current credential expires. Revocation begins only after every target confirms receipt.",
              html: { id: "gallery-fieldset-long" }
            ) do
              render NitroKit::FieldGroup.new(html: { id: "gallery-fieldset-long-fields" }) do
                render NitroKit::Field.new(
                  nil,
                  :rotation_window,
                  as: :number,
                  id: "gallery-fieldset-rotation-window",
                  name: "credential_policy[rotation_window]",
                  value: 14,
                  label: "Rotation window in days",
                  min: 1,
                  max: 90,
                  required: true
                )
                render NitroKit::Field.new(
                  nil,
                  :automatic_rotation,
                  as: :switch,
                  id: "gallery-fieldset-automatic-rotation",
                  name: "credential_policy[automatic_rotation]",
                  label: "Generate replacement credentials automatically",
                  checked: true
                )
              end
            end
          end
        end

        example_section(
          "Rails form builder",
          slug: "fieldset-builder",
          description: "A real model-backed multipart form composes builder fieldsets, groups, errors, choices, and actions."
        ) do
          example("Registration details", slug: "fieldset-registration-form") do
            registration = Registration.new(email: "not-an-email", role: "", terms: false, source: "gallery")
            registration.validate

            form_with(
              model: registration,
              scope: :registration,
              url: "#registration-details",
              builder: NitroKit::FormBuilder,
              id: "gallery-fieldset-registration-form"
            ) do |form|
              form.hidden_field(:source, id: "gallery-fieldset-registration-source")
              form.fieldset(
                legend: "Registration details",
                description: "Required fields preserve Rails validation and submission behavior.",
                html: { id: "gallery-fieldset-registration" }
              ) do
                form.group(html: { id: "gallery-fieldset-registration-fields" }) do
                  form.field(
                    :email,
                    as: :email,
                    id: "gallery-fieldset-registration-email",
                    description: "Used only for the registration receipt.",
                    required: true
                  )
                  form.field(
                    :role,
                    as: :select,
                    id: "gallery-fieldset-registration-role",
                    label: "Role",
                    prompt: "Choose a role",
                    options: [ [ "Developer", "developer" ], [ "Designer", "designer" ] ],
                    required: true
                  )
                  form.field(
                    :terms,
                    as: :checkbox,
                    id: "gallery-fieldset-registration-terms",
                    label: "I accept the workspace terms",
                    required: true
                  )
                  form.field(
                    :attachment,
                    as: :file,
                    id: "gallery-fieldset-registration-attachment",
                    label: "Supporting note",
                    accept: "text/plain"
                  )
                end
                form.submit("Register", id: "gallery-fieldset-registration-save")
              end
            end
          end
        end

        example_section(
          "Under pressure",
          slug: "fieldset-stress",
          description: "An unbroken legend and paragraph-length guidance from Gallery::Hostile around hostile fields, " \
            "then a disabled fieldset whose fields are also required and invalid."
        ) do
          example("Hostile legend and guidance", slug: "fieldset-hostile", stress: true) do
            options = Gallery::Hostile::CHOICES

            render NitroKit::Fieldset.new(
              legend: Gallery::Hostile::LONG_WORD,
              description: Gallery::Hostile::LONG_PARAGRAPH,
              html: { id: "gallery-fieldset-hostile" }
            ) do
              render NitroKit::FieldGroup.new(html: { id: "gallery-fieldset-hostile-fields" }) do
                render NitroKit::Field.new(
                  nil,
                  :email,
                  as: :email,
                  id: "gallery-fieldset-hostile-email",
                  name: "hostile[email]",
                  value: Gallery::Hostile::LONG_EMAIL,
                  label: Gallery::Hostile::LONG_LABEL,
                  description: Gallery::Hostile::LONG_SENTENCE,
                  errors: [ Gallery::Hostile::LONG_ERROR ],
                  required: true
                )
                render NitroKit::Field.new(
                  nil,
                  :status,
                  as: :select,
                  id: "gallery-fieldset-hostile-status",
                  name: "hostile[status]",
                  value: "hostile_3",
                  label: Gallery::Hostile::RTL_NAME,
                  description: Gallery::Hostile::CJK_NAME,
                  options:
                )
              end
            end
          end

          example("Disabled hostile fieldset", slug: "fieldset-hostile-disabled", stress: true) do
            render NitroKit::Fieldset.new(
              legend: Gallery::Hostile::LONG_LABEL,
              description: Gallery::Hostile::LONG_URL,
              disabled: true,
              name: "hostile-locked",
              html: { id: "gallery-fieldset-hostile-disabled" }
            ) do
              render NitroKit::FieldGroup.new(html: { id: "gallery-fieldset-hostile-disabled-fields" }) do
                render NitroKit::Field.new(
                  nil,
                  :slug,
                  id: "gallery-fieldset-hostile-disabled-slug",
                  name: "hostile_locked[slug]",
                  value: Gallery::Hostile::LONG_WORD,
                  label: Gallery::Hostile::LONG_WORD,
                  description: Gallery::Hostile::LONG_PARAGRAPH,
                  errors: [ Gallery::Hostile::LONG_ERROR ],
                  required: true,
                  disabled: true
                )
                render NitroKit::Field.new(
                  nil,
                  :agreement,
                  as: :checkbox,
                  id: "gallery-fieldset-hostile-disabled-agreement",
                  name: "hostile_locked[agreement]",
                  label: Gallery::Hostile::EMOJI_NAME,
                  description: Gallery::Hostile::LONG_SENTENCE,
                  errors: [ Gallery::Hostile::LONG_ERROR ],
                  required: true,
                  disabled: true
                )
              end
            end
          end
        end
      end
    end
  end
end
