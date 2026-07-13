module Gallery
  module Components
    class SwitchPage < ComponentPage
      private

      def source_note
        "app/components/nitro_kit/switch.rb"
      end

      def api_note
        "NitroKit::Switch.new(label:, description:, id:, name:, checked:, size:)"
      end

      def component_template
        example_section(
          "Submission states",
          slug: "switch-states",
          description: "Switches remain native checkboxes with hidden unchecked values and an owned switch role."
        ) do
          example("State and size matrix", slug: "switch-state-matrix", layout: :matrix) do
            sample("Small off", slug: "small-off") do
              render NitroKit::Switch.new(
                label: "Weekly digest",
                description: "One summary every Monday morning.",
                id: "gallery-switch-small-control",
                name: "preferences[weekly_digest]",
                size: :sm,
                html: { id: "gallery-switch-small" }
              )
            end
            sample("Medium on", slug: "medium-on") do
              render NitroKit::Switch.new(
                label: "Deployment alerts",
                description: "Notify the operations channel after production deploys.",
                id: "gallery-switch-medium-control",
                name: "preferences[deployment_alerts]",
                checked: true,
                size: :md,
                html: { id: "gallery-switch-medium" }
              )
            end
            sample("Required", slug: "required") do
              render NitroKit::Switch.new(
                label: "Security notices",
                id: "gallery-switch-required-control",
                name: "preferences[security_notices]",
                checked: true,
                required: true,
                html: { id: "gallery-switch-required" }
              )
            end
            sample("Disabled", slug: "disabled") do
              render NitroKit::Switch.new(
                label: "Legacy synchronization",
                description: "Locked while migration is in progress.",
                id: "gallery-switch-disabled-control",
                name: "preferences[legacy_sync]",
                checked: true,
                disabled: true,
                html: { id: "gallery-switch-disabled" }
              )
            end
          end
        end

        example_section(
          "Accessible labels",
          slug: "switch-labels",
          description: "Block content, long descriptions, and control-only accessible names cover compact and verbose uses."
        ) do
          example("Label pressure", slug: "switch-label-pressure", layout: :matrix) do
            sample("Block label", slug: "block") do
              render NitroKit::Switch.new(
                id: "gallery-switch-block-control",
                name: "preferences[activity]",
                checked: true,
                html: { id: "gallery-switch-block" }
              ) do
                strong { "Activity reports" }
                plain(" for workspace owners")
              end
            end
            sample("ARIA only", slug: "aria") do
              render NitroKit::Switch.new(
                id: "gallery-switch-aria-control",
                name: "table[compact_rows]",
                include_hidden: false,
                control_aria: { label: "Use compact table rows" },
                html: { id: "gallery-switch-aria" }
              )
            end
            sample("Long description", slug: "long") do
              render NitroKit::Switch.new(
                label: "Automatic credential rotation",
                description: "Create and distribute a replacement production credential before the current credential expires, then revoke the old credential after every deployment target confirms receipt.",
                id: "gallery-switch-long-control",
                name: "credentials[automatic_rotation]",
                html: { id: "gallery-switch-long" }
              )
            end
          end
        end

        example_section(
          "Rails form builder",
          slug: "switch-builder",
          description: "Builder fields map model booleans and validation errors into submittable switch controls."
        ) do
          example("Terms requirement", slug: "switch-registration-terms") do
            registration = Registration.new(email: "ada@example.test", role: "developer", terms: false)
            registration.validate

            form_with(
              model: registration,
              scope: :registration,
              url: "#registration-switch",
              builder: NitroKit::FormBuilder,
              id: "gallery-switch-registration-form"
            ) do |form|
              form.field(
                :terms,
                as: :switch,
                id: "gallery-switch-registration-terms",
                label: "Accept workspace terms",
                description: "Required before registration is complete.",
                required: true
              )
              form.submit("Continue", id: "gallery-switch-registration-save")
            end
          end
        end
      end
    end
  end
end
