module Gallery
  module Components
    class ComboboxPage < ComponentPage
      COUNTRIES = [
        [ "Denmark", "dk" ],
        { label: "Sweden", value: "se" },
        NitroKit::Choice.new(label: "Norway", value: "no"),
        { label: "Finland", value: "fi", disabled: true },
        [ "Iceland", "is" ]
      ].freeze

      ENVIRONMENTS = [
        [ "Development — local data", "development" ],
        [ "Staging — shared verification", "staging" ],
        [ "Production — customer traffic", "production" ]
      ].freeze

      private

      def source_note
        "app/components/nitro_kit/combobox.rb"
      end

      def api_note
        "NitroKit::Combobox.new(id:, name:, label:, options:, value:)"
      end

      def component_template
        example_section(
          "Selection states",
          slug: "combobox-selection",
          description: "Typed choices keep display labels separate from submitted values."
        ) do
          example("Selection matrix", slug: "combobox-selection-matrix", layout: :matrix) do
            sample("Empty optional", slug: "empty") do
              render_combobox("gallery-combobox-empty", placeholder: "Choose a country")
            end
            sample("Selected", slug: "selected") do
              render_combobox("gallery-combobox-selected", value: "dk")
            end
            sample("Required", slug: "required") do
              render_combobox("gallery-combobox-required", required: true, placeholder: "Country required")
            end
            sample("Disabled", slug: "disabled") do
              render_combobox("gallery-combobox-disabled", value: "se", disabled: true)
            end
          end
        end

        example_section(
          "Placements and choice pressure",
          slug: "combobox-placements",
          description: "All placements and long labels retain deterministic IDs and native listbox semantics."
        ) do
          example("Placement matrix", slug: "combobox-placement-matrix", layout: :matrix) do
            NitroKit::Combobox::PLACEMENTS.each do |placement|
              sample(placement.to_s.humanize, slug: placement.to_s) do
                render NitroKit::Combobox.new(
                  id: "gallery-combobox-#{placement}",
                  name: "deployment[#{placement}]",
                  label: "Deployment environment",
                  options: ENVIRONMENTS,
                  value: "staging",
                  placement:
                )
              end
            end
          end
        end

        example_section(
          "Form composition",
          slug: "combobox-form",
          description: "The combobox submits one hidden value alongside ordinary Nitro fields."
        ) do
          example("Deployment target", slug: "combobox-deployment-target") do
            render NitroKit::Card.new(id: "gallery-combobox-deployment-card") do |card|
              card.title("Promote release", level: 3)
              card.body do
                form(id: "gallery-combobox-deployment-form", action: "/gallery/deployments", method: "post") do
                  render NitroKit::Field.new(
                    nil,
                    :release,
                    id: "gallery-combobox-release",
                    name: "deployment[release]",
                    label: "Release",
                    value: "2026.07.13",
                    readonly: true
                  )
                  render NitroKit::Combobox.new(
                    id: "gallery-combobox-environment",
                    name: "deployment[environment]",
                    label: "Target environment",
                    options: ENVIRONMENTS,
                    value: "production",
                    required: true
                  )
                  render NitroKit::Button.new(
                    "Promote release",
                    id: "gallery-combobox-submit",
                    type: :submit,
                    variant: :primary
                  )
                end
              end
            end
          end
        end
      end

      def render_combobox(id, **attributes)
        render NitroKit::Combobox.new(
          id:,
          name: "profile[country]",
          label: "Country",
          options: COUNTRIES,
          **attributes
        )
      end
    end
  end
end
