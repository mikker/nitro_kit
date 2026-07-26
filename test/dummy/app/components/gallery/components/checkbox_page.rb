module Gallery
  module Components
    class CheckboxPage < ComponentPage
      private

      def source_note
        "app/components/nitro_kit/checkbox.rb"
      end

      def api_note
        "NitroKit::Checkbox.new(label:, id:, name:, value:, checked:)"
      end

      def component_template
        example_section(
          "Submission states",
          slug: "checkbox-states",
          description: "Checked and unchecked state stay native. Only indeterminate needs an enhancer, because HTML cannot express it."
        ) do
          example("Boolean states", slug: "checkbox-boolean-states", layout: :matrix) do
            sample("Unchecked", slug: "unchecked") do
              render NitroKit::Checkbox.new(
                label: "Email summaries",
                id: "gallery-checkbox-unchecked-control",
                name: "preferences[email_summaries]",
                value: "enabled",
                unchecked_value: "disabled",
                html: { id: "gallery-checkbox-unchecked" }
              )
            end
            sample("Checked", slug: "checked") do
              render NitroKit::Checkbox.new(
                label: "Security notices",
                id: "gallery-checkbox-checked-control",
                name: "preferences[security_notices]",
                checked: true,
                required: true,
                html: { id: "gallery-checkbox-checked" }
              )
            end
            sample("Indeterminate", slug: "indeterminate") do
              render NitroKit::Checkbox.new(
                label: "Select visible members",
                id: "gallery-checkbox-indeterminate-control",
                name: "members[visible]",
                indeterminate: true,
                include_hidden: false,
                html: { id: "gallery-checkbox-indeterminate" }
              )
            end
            sample("Disabled", slug: "disabled") do
              render NitroKit::Checkbox.new(
                label: "Legacy synchronization",
                id: "gallery-checkbox-disabled-control",
                name: "preferences[legacy_sync]",
                checked: true,
                disabled: true,
                html: { id: "gallery-checkbox-disabled" }
              )
            end
            sample("Invalid", slug: "invalid") do
              render NitroKit::Checkbox.new(
                label: "Accept the processing agreement",
                id: "gallery-checkbox-invalid-control",
                name: "preferences[processing_agreement]",
                required: true,
                invalid: true,
                html: { id: "gallery-checkbox-invalid" }
              )
            end
          end

          example("Sizes", slug: "checkbox-sizes", layout: :matrix) do
            sample("Medium", slug: "medium") do
              render NitroKit::Checkbox.new(
                label: "Medium checkbox",
                id: "gallery-checkbox-medium-control",
                name: "preferences[medium]",
                checked: true,
                size: :md,
                html: { id: "gallery-checkbox-medium" }
              )
            end
            sample("Large", slug: "large") do
              render NitroKit::Checkbox.new(
                label: "Large checkbox",
                id: "gallery-checkbox-large-control",
                name: "preferences[large]",
                checked: true,
                size: :lg,
                html: { id: "gallery-checkbox-large" }
              )
            end
          end
        end

        example_section(
          "Label boundaries",
          slug: "checkbox-labels",
          description: "Standalone controls need an explicit accessible name; block labels and long agreement text remain native."
        ) do
          example("Label pressure", slug: "checkbox-label-pressure", layout: :matrix) do
            sample("Standalone", slug: "standalone") do
              render NitroKit::Checkbox.new(
                id: "gallery-checkbox-standalone-control",
                name: "rows[selected]",
                include_hidden: false,
                control_aria: { label: "Select deployment row" },
                html: { id: "gallery-checkbox-standalone" }
              )
            end
            sample("Block label", slug: "block") do
              render NitroKit::Checkbox.new(
                id: "gallery-checkbox-block-control",
                name: "preferences[activity]",
                checked: true,
                html: { id: "gallery-checkbox-block" }
              ) do
                strong { "Activity reports" }
                plain(" every Monday morning")
              end
            end
            sample("Long agreement", slug: "long") do
              render NitroKit::Checkbox.new(
                label: "I understand that rotating this production credential immediately invalidates every existing deployment token",
                id: "gallery-checkbox-long-control",
                name: "credential[confirm_rotation]",
                required: true,
                html: { id: "gallery-checkbox-long" }
              )
            end
          end
        end

        example_section(
          "Rails form builder",
          slug: "checkbox-builder",
          description: "The builder keeps model truthiness, hidden unchecked values, errors, and Rails names together."
        ) do
          example("Terms validation", slug: "checkbox-registration-terms") do
            registration = Registration.new(email: "ada@example.test", role: "developer", terms: false)
            registration.validate

            form_with(
              model: registration,
              scope: :registration,
              url: "#registration-terms",
              builder: NitroKit::FormBuilder,
              id: "gallery-checkbox-registration-form"
            ) do |form|
              form.field(
                :terms,
                as: :checkbox,
                id: "gallery-checkbox-registration-terms",
                label: "I accept the workspace terms",
                description: "Required before the invitation can be accepted.",
                checked_value: "yes",
                unchecked_value: "no",
                required: true
              )
              form.submit("Accept invitation", id: "gallery-checkbox-registration-save")
            end
          end
        end
      end
    end
  end
end
