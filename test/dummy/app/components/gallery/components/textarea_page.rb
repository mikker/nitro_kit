module Gallery
  module Components
    class TextareaPage < ComponentPage
      private

      def source_note
        "app/components/nitro_kit/textarea.rb"
      end

      def api_note
        "NitroKit::Textarea.new(id:, name:, value:, rows:, wrap:)"
      end

      def component_template
        example_section(
          "Values and constraints",
          slug: "textarea-values",
          description: "Textarea values remain text content while native sizing and length constraints stay explicit."
        ) do
          example("Value matrix", slug: "textarea-value-matrix", layout: :matrix) do
            sample("Default", slug: "default") do
              render NitroKit::Textarea.new(
                id: "gallery-textarea-default",
                aria: { label: "Profile bio" },
                name: "profile[bio]",
                value: "Building reliable interfaces for analytical software.",
                rows: 4
              )
            end
            sample("Empty", slug: "empty") do
              render NitroKit::Textarea.new(
                id: "gallery-textarea-empty",
                aria: { label: "Invitation message" },
                name: "invitation[message]",
                value: "",
                placeholder: "Add an optional welcome message"
              )
            end
            sample("Constrained", slug: "constrained") do
              render NitroKit::Textarea.new(
                id: "gallery-textarea-constrained",
                aria: { label: "Incident summary" },
                name: "incident[summary]",
                value: "Customer impact was limited to delayed notifications.",
                required: true,
                rows: 6,
                cols: 48,
                minlength: 20,
                maxlength: 280,
                wrap: :hard
              )
            end
          end
        end

        example_section(
          "Availability and pressure",
          slug: "textarea-states",
          description: "Read-only, disabled, long, and invalid content preserve browser and accessibility semantics."
        ) do
          example("State matrix", slug: "textarea-state-matrix", layout: :matrix) do
            sample("Read only", slug: "readonly") do
              render NitroKit::Textarea.new(
                id: "gallery-textarea-readonly",
                aria: { label: "Audit summary" },
                name: "audit[summary]",
                value: "Export completed by Ada Lovelace on July 13, 2026.",
                readonly: true
              )
            end
            sample("Disabled", slug: "disabled") do
              render NitroKit::Textarea.new(
                id: "gallery-textarea-disabled",
                aria: { label: "Legacy notes" },
                name: "legacy[notes]",
                value: "Legacy notes cannot be edited.",
                disabled: true
              )
            end
            sample("Long content", slug: "long") do
              render NitroKit::Textarea.new(
                id: "gallery-textarea-long",
                aria: { label: "Retention policy" },
                name: "workspace[retention_policy]",
                value: "Workspace records remain available throughout the current billing period. " \
                  "Audit exports preserve their original timestamps and actor identifiers across plan changes.",
                rows: 8,
                wrap: :soft
              )
            end
          end

          example("Invalid field", slug: "textarea-invalid-field") do
            invalid_profile = Gallery::FormExamples.profile(:invalid)

            render NitroKit::Field.new(
              nil,
              :bio,
              as: :textarea,
              id: "gallery-textarea-invalid",
              name: "profile[bio]",
              value: invalid_profile.bio,
              label: "Biography",
              description: "Keep the biography under 280 characters.",
              errors: invalid_profile.errors.full_messages_for(:bio),
              required: true,
              maxlength: 280
            )
          end
        end

        example_section(
          "Rails form builder",
          slug: "textarea-builder",
          description: "Model values and validation errors flow through FormBuilder into the direct textarea component."
        ) do
          example("Invalid profile biography", slug: "textarea-profile-form") do
            profile = Gallery::FormExamples.profile(:invalid)

            form_with(
              model: profile,
              scope: :profile,
              url: "#profile-biography",
              builder: NitroKit::FormBuilder,
              id: "gallery-textarea-profile-form"
            ) do |form|
              form.field(
                :bio,
                as: :textarea,
                id: "gallery-textarea-profile-bio",
                description: "A short biography shown to workspace members.",
                required: true,
                maxlength: 280
              )
              form.submit("Save biography", id: "gallery-textarea-profile-save")
            end
          end
        end
      end
    end
  end
end
