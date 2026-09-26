module Gallery
  module Components
    class SelectPage < ComponentPage
      private

      def source_note
        "app/components/nitro_kit/select.rb"
      end

      def api_note
        "NitroKit::Select.new(options:, id:, name:, value:, multiple:)"
      end

      def component_template
        example_section(
          "Choice normalization",
          slug: "select-choices",
          description: "Strings, arrays, hashes, and Choice records normalize into the same explicit option contract."
        ) do
          example("Mixed choice vocabulary", slug: "select-mixed-choices") do
            render NitroKit::Select.new(
              id: "gallery-select-mixed-control",
              control_aria: { label: "Workspace region" },
              name: "workspace[region]",
              value: "eu-central",
              include_blank: "No region selected",
              options: [
                "Automatic",
                [ "United States East", "us-east" ],
                { label: "European Union Central", value: "eu-central", id: "region-eu-central" },
                NitroKit::Choice.new(
                  label: "Legacy Asia Pacific",
                  value: "ap-legacy",
                  disabled: true,
                  id: "region-ap-legacy"
                )
              ],
              html: { id: "gallery-select-mixed" }
            )
          end

          example("Prompt and empty collection", slug: "select-boundaries", layout: :matrix) do
            sample("Prompt", slug: "prompt") do
              render NitroKit::Select.new(
                id: "gallery-select-prompt-control",
                control_aria: { label: "Member role" },
                name: "member[role]",
                prompt: "Choose a role",
                required: true,
                options: [ [ "Administrator", "admin" ], [ "Member", "member" ], [ "Viewer", "viewer" ] ],
                html: { id: "gallery-select-prompt" }
              )
            end
            sample("No choices", slug: "empty") do
              render NitroKit::Select.new(
                id: "gallery-select-empty-control",
                control_aria: { label: "Available region" },
                name: "workspace[available_region]",
                options: [],
                disabled: true,
                aria: { label: "No regions available" },
                html: { id: "gallery-select-empty" }
              )
            end
          end
        end

        example_section(
          "Selection states",
          slug: "select-states",
          description: "Single, multiple, disabled, and long choices retain native names and selected values."
        ) do
          example("State matrix", slug: "select-state-matrix", layout: :matrix) do
            sample("Multiple", slug: "multiple") do
              render NitroKit::Select.new(
                id: "gallery-select-multiple-control",
                control_aria: { label: "Notification channels" },
                name: "notifications[channels]",
                value: %w[email security],
                multiple: true,
                options: [
                  [ "Product updates", "product" ],
                  [ "Email summaries", "email" ],
                  [ "Security notices", "security" ]
                ],
                html: { id: "gallery-select-multiple" }
              )
            end
            sample("Disabled", slug: "disabled") do
              render NitroKit::Select.new(
                id: "gallery-select-disabled-control",
                control_aria: { label: "Billing currency" },
                name: "billing[currency]",
                value: "USD",
                disabled: true,
                options: [ [ "United States dollar", "USD" ], [ "Euro", "EUR" ] ],
                html: { id: "gallery-select-disabled" }
              )
            end
            sample("Long option", slug: "long") do
              render NitroKit::Select.new(
                id: "gallery-select-long-control",
                control_aria: { label: "Retention policy" },
                name: "retention[policy]",
                value: "regulated",
                options: [
                  [ "Standard retention for ordinary workspace activity", "standard" ],
                  [ "Extended regulated retention with immutable audit exports", "regulated" ]
                ],
                html: { id: "gallery-select-long" }
              )
            end
          end
        end

        example_section(
          "Rails form builder",
          slug: "select-builder",
          description: "The builder preserves model selection, Rails field names, prompts, and validation errors."
        ) do
          example("Profile time zone", slug: "select-profile-time-zone") do
            profile = Gallery::FormExamples.profile(:invalid)

            form_with(
              model: profile,
              scope: :profile,
              url: "#profile-time-zone",
              builder: NitroKit::FormBuilder,
              id: "gallery-select-profile-form"
            ) do |form|
              form.group do
                form.field(
                  :time_zone,
                  as: :select,
                  id: "gallery-select-profile-time-zone",
                  label: "Time zone",
                  description: "Dates in reports use this display time zone.",
                  prompt: "Choose a time zone",
                  options: Gallery::Forms::Profile::TIME_ZONES,
                  required: true
                )
                form.submit("Save time zone", id: "gallery-select-profile-save")
              end
            end
          end
        end

        example_section(
          "Under pressure",
          slug: "select-stress",
          description: "Thirty Gallery::Hostile badge labels as options, with the unbroken word selected, a paragraph " \
            "prompt, a required disabled select, and a multiple select with many hostile selections."
        ) do
          example("Hostile single selects", slug: "select-hostile-single", stress: true) do
            options = Gallery::Hostile::CHOICES

            render NitroKit::Flex.new(dir: :col, gap: 3, align: :stretch) do
              render NitroKit::Select.new(
                id: "gallery-select-hostile-word-control",
                control_aria: { label: Gallery::Hostile::LONG_LABEL },
                name: "hostile[word]",
                value: "hostile_3",
                options:,
                html: { id: "gallery-select-hostile-word" }
              )
              render NitroKit::Select.new(
                id: "gallery-select-hostile-prompt-control",
                control_aria: { label: Gallery::Hostile::LONG_LABEL },
                name: "hostile[prompt]",
                prompt: Gallery::Hostile::LONG_SENTENCE,
                required: true,
                options:,
                html: { id: "gallery-select-hostile-prompt" }
              )
              render NitroKit::Select.new(
                id: "gallery-select-hostile-blank-control",
                control_aria: { label: Gallery::Hostile::RTL_NAME },
                name: "hostile[blank]",
                include_blank: Gallery::Hostile::LONG_LABEL,
                options:,
                html: { id: "gallery-select-hostile-blank" }
              )
              render NitroKit::Select.new(
                id: "gallery-select-hostile-locked-control",
                control_aria: { label: Gallery::Hostile::CJK_NAME, invalid: true },
                name: "hostile[locked]",
                value: "hostile_1",
                required: true,
                disabled: true,
                options:,
                html: { id: "gallery-select-hostile-locked" }
              )
            end
          end

          example("Hostile multiple select", slug: "select-hostile-multiple", stress: true) do
            options = Gallery::Hostile::CHOICES

            render NitroKit::Select.new(
              id: "gallery-select-hostile-multiple-control",
              control_aria: { label: Gallery::Hostile::LONG_LABEL },
              name: "hostile[multiple]",
              value: %w[hostile_1 hostile_3 hostile_5 hostile_7 hostile_9 hostile_11 hostile_13 hostile_17],
              multiple: true,
              options:,
              html: { id: "gallery-select-hostile-multiple" }
            )
          end
        end
      end
    end
  end
end
