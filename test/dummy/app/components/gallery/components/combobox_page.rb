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
        { label: "Development", value: "development", description: "Local data only" },
        { label: "Staging", value: "staging", description: "Shared verification" },
        { label: "Production", value: "production", description: "Customer traffic" }
      ].freeze

      BILLING_COUNTRIES = [
        { label: "Denmark", value: "DK", description: "EU reverse-charge VAT" },
        { label: "Germany", value: "DE", description: "EU reverse-charge VAT" },
        { label: "United Kingdom", value: "GB", description: "UK VAT registration required" },
        { label: "United States", value: "US", description: "Sales tax by state" }
      ].freeze

      private

      def source_note
        "app/components/nitro_kit/combobox.rb"
      end

      def api_note
        "NitroKit::Combobox.new(id:, name:, label:, options:, value:, include_blank:) · " \
          "NitroKit::Combobox.new(id:, name:, label:, src:, selected:, multiple:)"
      end

      def component_template
        example_section(
          "Selection states",
          slug: "combobox-selection",
          description: "A named native select submits without JavaScript; enhancement adds filtering without a duplicate form value."
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
            sample("Numeric labels", slug: "numeric-labels") do
              render NitroKit::Combobox.new(
                id: "gallery-combobox-numeric",
                name: "deployment[retry_count]",
                label: "Retry count",
                options: [ [ 1, "one" ], [ 2, "two" ], [ 3, "three" ] ],
                value: "two"
              )
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
          description: "The combobox keeps one native select as its submission source alongside ordinary Nitro fields."
        ) do
          example("Deployment target", slug: "combobox-deployment-target") do
            render NitroKit::Card.new(id: "gallery-combobox-deployment-card") do |card|
              card.title("Promote release", level: 3)
              card.body do
                form(id: "gallery-combobox-deployment-form", action: "/gallery/deployments", method: "post") do
                  render NitroKit::FieldGroup.new do
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

        example_section(
          "Rails form builder",
          slug: "combobox-builder",
          description: "`form.field(:country, as: :combobox)` puts the searchable control inside an ordinary Field with its own label, description, and errors."
        ) do
          example("Billing country", slug: "combobox-billing-country") do
            contact = Gallery::FormExamples.billing_contact

            form_with(
              model: contact,
              scope: :billing_contact,
              url: "#billing-country",
              builder: NitroKit::FormBuilder,
              id: "gallery-combobox-billing-form"
            ) do |form|
              form.group do
                form.field(
                  :country,
                  as: :combobox,
                  id: "gallery-combobox-billing-country",
                  label: "Billing country",
                  description: "Invoices apply this country's tax rules.",
                  options: BILLING_COUNTRIES,
                  placeholder: "Search countries",
                  required: true
                )
                form.submit("Save billing country", id: "gallery-combobox-billing-save")
              end
            end
          end
        end

        example_section(
          "Remote relations",
          slug: "combobox-remote",
          description: "`src:` searches server-rendered `Combobox::Results`; the application keeps search, authorization, " \
            "creation, and persistence. Multiple mode submits one hidden `name[]` field per chip."
        ) do
          example(
            "Relation picker",
            slug: "combobox-relation-picker",
            description: "Search labels, select several, create a missing one from the results, then save without a title: " \
              "the 422 re-render rebuilds every chip from the submitted ids.",
            source: "test/dummy/app/controllers/gallery/combobox_labels_controller.rb",
            api: "GET query → NitroKit::Combobox::Results.new(id:) { |results| results.option(...); results.action(...) }",
            code: Gallery::SourceCode.from_method(Gallery::ComboboxReleaseForm.instance_method(:release_form))
          ) do
            render Gallery::ComboboxReleaseForm.new
          end

          example("Remote states", slug: "combobox-remote-states", layout: :matrix) do
            sample("Single selection", slug: "single") do
              render NitroKit::Combobox.new(
                id: "gallery-combobox-remote-single",
                name: "issue[label_id]",
                label: "Primary label",
                src: gallery_combobox_labels_path(combobox: "gallery-combobox-remote-single"),
                selected: [ { label: "Regression", value: 8 } ],
                placeholder: "Search labels"
              )
            end
            sample("Required multiple", slug: "required-multiple") do
              render NitroKit::Combobox.new(
                id: "gallery-combobox-remote-required",
                name: "issue[label_ids]",
                label: "Labels",
                src: gallery_combobox_labels_path(combobox: "gallery-combobox-remote-required"),
                multiple: true,
                required: true,
                placeholder: "Choose at least one label"
              )
            end
            sample("Disabled with selections", slug: "disabled") do
              render NitroKit::Combobox.new(
                id: "gallery-combobox-remote-disabled",
                name: "issue[locked_label_ids]",
                label: "Locked labels",
                src: gallery_combobox_labels_path(combobox: "gallery-combobox-remote-disabled"),
                multiple: true,
                selected: [ { label: "Security", value: 9 }, { label: "Bug", value: 1 } ],
                disabled: true
              )
            end
            sample("Unavailable search", slug: "error") do
              render NitroKit::Combobox.new(
                id: "gallery-combobox-remote-error",
                name: "issue[fallback_label_ids]",
                label: "Labels",
                src: gallery_combobox_labels_path(combobox: "gallery-combobox-remote-error", unavailable: 1),
                multiple: true,
                selected: [ { label: "Documentation", value: 5 } ],
                placeholder: "Search fails with 503"
              )
            end
          end
        end

        example_section(
          "Under pressure",
          slug: "combobox-stress",
          description: "Thirty Gallery::Hostile badge labels as searchable options with sentence-long descriptions, an " \
            "unbroken selected label, a hostile placeholder, and a required disabled combobox inside an invalid field."
        ) do
          example("Hostile comboboxes", slug: "combobox-hostile", stress: true) do
            options = Gallery::Hostile::BADGE_LABELS.each_with_index.map do |label, index|
              { label:, value: "hostile_#{index}", description: index.odd? ? Gallery::Hostile::LONG_SENTENCE : nil }
            end

            render NitroKit::Flex.new(dir: :col, gap: 4, align: :stretch) do
              render NitroKit::Combobox.new(
                id: "gallery-combobox-hostile-word",
                name: "hostile[word]",
                label: Gallery::Hostile::LONG_LABEL,
                options:,
                value: "hostile_3",
                placeholder: Gallery::Hostile::LONG_SENTENCE
              )
              render NitroKit::Combobox.new(
                id: "gallery-combobox-hostile-locked",
                name: "hostile[locked]",
                label: Gallery::Hostile::LONG_WORD,
                options:,
                value: "hostile_1",
                placement: :top_end,
                required: true,
                disabled: true
              )
            end
          end

          example("Hostile remote selections", slug: "combobox-hostile-remote", stress: true) do
            selected = (Gallery::Hostile::BADGE_LABELS + Gallery::Hostile::NAMES).each_with_index.map do |label, index|
              { label:, value: "hostile_#{index}" }
            end

            render NitroKit::Combobox.new(
              id: "gallery-combobox-hostile-remote",
              name: "hostile[label_ids]",
              label: Gallery::Hostile::LONG_LABEL,
              src: gallery_combobox_labels_path(combobox: "gallery-combobox-hostile-remote"),
              multiple: true,
              selected:,
              placeholder: Gallery::Hostile::LONG_SENTENCE,
              required: true
            )
          end

          example("Hostile combobox field", slug: "combobox-hostile-field", stress: true) do
            options = Gallery::Hostile::BADGE_LABELS.each_with_index.map do |label, index|
              { label:, value: "hostile_#{index}", description: index.even? ? Gallery::Hostile::LONG_URL : nil }
            end

            render NitroKit::Field.new(
              nil,
              :status,
              as: :combobox,
              id: "gallery-combobox-hostile-field",
              name: "hostile[status]",
              value: "hostile_3",
              label: Gallery::Hostile::LONG_LABEL,
              description: Gallery::Hostile::LONG_PARAGRAPH,
              errors: [ Gallery::Hostile::LONG_ERROR ],
              options:,
              placeholder: Gallery::Hostile::LONG_WORD,
              required: true,
              html: { id: "gallery-combobox-hostile-field-wrapper" }
            )
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
