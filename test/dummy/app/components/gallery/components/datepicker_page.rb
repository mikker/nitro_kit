module Gallery
  module Components
    class DatepickerPage < ComponentPage
      private

      def source_note
        "app/components/nitro_kit/datepicker.rb"
      end

      def api_note
        "NitroKit::Datepicker.new(id:, name:, value:, min:, max:)"
      end

      def component_template
        example_section(
          "Native states",
          slug: "datepicker-states",
          description: "Date selection remains a native input with server-verifiable constraints."
        ) do
          example("State matrix", slug: "datepicker-state-matrix", layout: :matrix) do
            sample("Empty", slug: "empty") do
              render_datepicker("gallery-datepicker-empty", aria: { label: "Start date" })
            end
            sample("Selected", slug: "selected") do
              render_datepicker("gallery-datepicker-selected", value: Date.new(2026, 7, 13), aria: { label: "Start date" })
            end
            sample("Required range", slug: "required-range") do
              render_datepicker(
                "gallery-datepicker-required",
                min: Date.new(2026, 7, 13),
                max: Date.new(2026, 8, 13),
                required: true,
                aria: { label: "Deployment date" }
              )
            end
            sample("Read only", slug: "readonly") do
              render_datepicker(
                "gallery-datepicker-readonly",
                value: Date.new(2026, 7, 13),
                readonly: true,
                aria: { label: "Invoice date" }
              )
            end
            sample("Disabled", slug: "disabled") do
              render_datepicker(
                "gallery-datepicker-disabled",
                value: Date.new(2026, 7, 13),
                disabled: true,
                aria: { label: "Archived date" }
              )
            end
          end
        end

        example_section(
          "Scheduling composition",
          slug: "datepicker-scheduling",
          description: "Field anatomy can explicitly own labels and help text around the dedicated date control."
        ) do
          example("Schedule a release", slug: "datepicker-release-form") do
            render NitroKit::Card.new(id: "gallery-datepicker-release-card") do |card|
              card.title("Schedule production release", level: 3)
              card.body do
                form(id: "gallery-datepicker-release-form", action: "/gallery/releases", method: "post") do
                  render NitroKit::Field.new(
                    nil,
                    :release_date,
                    id: "gallery-datepicker-release-date",
                    name: "release[date]",
                    label: "Release date",
                    description: "Choose a weekday within the next thirty days.",
                    required: true
                  ) do |field|
                    field.label
                    field.description
                    render NitroKit::Datepicker.new(
                      id: "gallery-datepicker-release-date",
                      name: "release[date]",
                      value: Date.new(2026, 7, 20),
                      min: Date.new(2026, 7, 13),
                      max: Date.new(2026, 8, 12),
                      required: true,
                      aria: { describedby: "gallery-datepicker-release-date-description" }
                    )
                  end
                  render NitroKit::Button.new(
                    "Schedule release",
                    id: "gallery-datepicker-schedule",
                    type: :submit,
                    variant: :primary
                  )
                end
              end
            end
          end
        end
      end

      def render_datepicker(id, **attributes)
        render NitroKit::Datepicker.new(id:, name: "schedule[date]", **attributes)
      end
    end
  end
end
