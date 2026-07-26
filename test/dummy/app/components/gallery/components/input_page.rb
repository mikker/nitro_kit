module Gallery
  module Components
    class InputPage < ComponentPage
      private

      def source_note
        "app/components/nitro_kit/input.rb"
      end

      def api_note
        "NitroKit::Input.new(type:, id:, name:, value:)"
      end

      def component_template
        example_section(
          "Native types",
          slug: "input-types",
          description: "Representative browser types keep native value, completion, placeholder, and requirement semantics."
        ) do
          example(
            "Type matrix",
            slug: "input-type-matrix",
            mode: :full_width,
            layout: :matrix,
            density: :compact
          ) do
            Gallery::Data.input_examples.each do |input|
              sample(input.label, slug: input.slug) do
                render_input(input)
              end
            end
          end
        end

        example_section(
          "Specialized controls",
          slug: "input-specialized",
          description: "Boolean, file, and range controls retain their browser-specific attributes."
        ) do
          example("Specialized types", slug: "input-specialized-types", layout: :matrix) do
            sample("Checked checkbox", slug: "checkbox") do
              render NitroKit::Input.new(
                type: :checkbox,
                id: "gallery-input-checkbox",
                name: "preferences[weekly_digest]",
                value: "1",
                checked: true,
                aria: { label: "Send weekly digest" }
              )
            end
            sample("File upload", slug: "file") do
              render NitroKit::Input.new(
                type: :file,
                id: "gallery-input-file",
                name: "profile[avatar]",
                accept: "image/png,image/jpeg",
                aria: { label: "Profile image" }
              )
            end
            sample("Range", slug: "range") do
              render NitroKit::Input.new(
                type: :range,
                id: "gallery-input-range",
                name: "notifications[volume]",
                value: 60,
                min: 0,
                max: 100,
                step: 10,
                aria: { label: "Notification volume" }
              )
            end
          end
        end

        example_section(
          "Date controls",
          slug: "input-dates",
          description: "Date selection is an ordinary native input with server-verifiable constraints and normalized cross-browser alignment."
        ) do
          example("Date matrix", slug: "input-date-matrix", layout: :matrix) do
            sample("Empty", slug: "empty") do
              render_date("gallery-input-date-empty", aria: { label: "Start date" })
            end
            sample("Selected", slug: "selected") do
              render_date(
                "gallery-input-date-selected",
                value: Date.new(2026, 7, 13),
                aria: { label: "Start date" }
              )
            end
            sample("Required range", slug: "required-range") do
              render_date(
                "gallery-input-date-required",
                min: Date.new(2026, 7, 13),
                max: Date.new(2026, 8, 13),
                required: true,
                aria: { label: "Deployment date" }
              )
            end
            sample("Read only", slug: "readonly") do
              render_date(
                "gallery-input-date-readonly",
                value: Date.new(2026, 7, 13),
                readonly: true,
                aria: { label: "Invoice date" }
              )
            end
            sample("Disabled", slug: "disabled") do
              render_date(
                "gallery-input-date-disabled",
                value: Date.new(2026, 7, 13),
                disabled: true,
                aria: { label: "Archived date" }
              )
            end
          end

          example("Schedule a release", slug: "input-date-release-form") do
            render NitroKit::Card.new(id: "gallery-input-date-release-card") do |card|
              card.title("Schedule production release", level: 3)
              card.body do
                form(id: "gallery-input-date-release-form", action: "/gallery/releases", method: "post") do
                  render NitroKit::FieldGroup.new do
                    render NitroKit::Field.new(
                      nil,
                      :release_date,
                      as: :date,
                      id: "gallery-input-date-release-date",
                      name: "release[date]",
                      label: "Release date",
                      description: "Choose a weekday within the next thirty days.",
                      value: Date.new(2026, 7, 20),
                      min: Date.new(2026, 7, 13),
                      max: Date.new(2026, 8, 12),
                      required: true
                    )
                    render NitroKit::Button.new(
                      "Schedule release",
                      id: "gallery-input-date-schedule",
                      type: :submit,
                      variant: :primary
                    )
                  end
                end
              end
            end
          end
        end

        example_section(
          "Validation and availability",
          slug: "input-states",
          description: "Required, invalid, read-only, and disabled state remains inspectable in native attributes."
        ) do
          example("Control states", slug: "input-control-states", layout: :matrix) do
            sample("Invalid", slug: "invalid") do
              render NitroKit::Input.new(
                type: :email,
                id: "gallery-input-invalid",
                name: "billing[email]",
                value: "not-an-email",
                required: true,
                aria: { label: "Billing email", invalid: true, describedby: "gallery-input-invalid-error" }
              )
              p(id: "gallery-input-invalid-error") { "Enter a valid email address" }
            end
            sample("Length limited", slug: "length") do
              render NitroKit::Input.new(
                id: "gallery-input-length",
                name: "workspace[slug]",
                value: "mothership",
                minlength: 3,
                maxlength: 24,
                aria: { label: "Workspace slug" }
              )
            end
            sample("Read only", slug: "readonly") do
              render NitroKit::Input.new(
                id: "gallery-input-readonly",
                value: "acct_42NK",
                readonly: true,
                aria: { label: "Account identifier" }
              )
            end
            sample("Disabled", slug: "disabled") do
              render NitroKit::Input.new(
                id: "gallery-input-disabled-state",
                value: "Unavailable",
                disabled: true,
                aria: { label: "Legacy setting" }
              )
            end
          end
        end
      end

      def render_date(id, **attributes)
        render NitroKit::Input.new(type: :date, id:, name: "schedule[date]", **attributes)
      end

      def render_input(input)
        render(
          NitroKit::Input.new(
            type: input.type,
            id: "gallery-input-type-#{input.slug}",
            name: "examples[#{input.slug}]",
            value: input.value,
            placeholder: input.placeholder,
            disabled: input.disabled,
            readonly: input.readonly,
            required: input.required,
            aria: { label: input.label }
          )
        )
      end
    end
  end
end
