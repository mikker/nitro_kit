module Gallery
  module Components
    class SheetPage < ComponentPage
      Deployment = ::Data.define(:environment, :status, :owner)

      private

      def source_note
        "app/components/nitro_kit/sheet.rb"
      end

      def api_note
        "NitroKit::Sheet.new(id:, side:, size:) { |sheet| sheet.trigger; sheet.panel }"
      end

      def component_template
        example_section(
          "Side panels",
          slug: "sheet-panels",
          description: "A native modal dialog enters from either inline edge without changing surrounding flex or grid layout."
        ) do
          example("Navigation and details", slug: "sheet-constructions", layout: :row) do
            prompts = [
              [ "Set up the project", "#prompt-1" ],
              [ "Review the implementation", "#prompt-2" ],
              [ "Prepare the release", "#prompt-3" ]
            ]

            render NitroKit::Sheet.new(id: "gallery-sheet-prompts", side: :left, size: :sm) do |sheet|
              sheet.trigger("Prompts", icon: :list)
              sheet.panel(
                title: "Transcript prompts",
                description: "Jump to a prompt in this transcript."
              ) do
                render NitroKit::AppNavigation.new(label: "Transcript prompts") do |navigation|
                  navigation.body do |items|
                    prompts.each_with_index do |(text, href), index|
                      items.item(text, href:, current: index.zero?)
                    end
                  end
                end
              end
            end

            render NitroKit::Sheet.new(id: "gallery-sheet-details", side: :right, size: :md) do |sheet|
              sheet.trigger("Record details", icon_end: :panel_right)
              sheet.panel(title: "Deployment 1842", description: "Production release details") do
                render NitroKit::DetailsTable.new(
                  Deployment.new(environment: "Production", status: "Running", owner: "Ada Lovelace"),
                  label: "Deployment details"
                ) do |details|
                  details.fields(:environment, :status, :owner)
                end
              end
            end
          end

          example(
            "Sizes, long content, and unavailable",
            slug: "sheet-pressure",
            layout: :row,
            description: "A large sheet scrolls long content past its sticky close control with a custom close label; a disabled trigger keeps the panel unreachable."
          ) do
            render NitroKit::Sheet.new(
              id: "gallery-sheet-long",
              side: :right,
              size: :lg,
              close_label: "Close changelog"
            ) do |sheet|
              sheet.trigger("Full changelog")
              sheet.panel(
                title: "Release changelog",
                description: "Every change since the previous production deploy."
              ) do
                12.times do |index|
                  p do
                    "Change #{index + 1}. Deploy #{1830 + index} refreshed the ingestion " \
                      "pipeline, rotated its credentials, and re-ran the archived backfill " \
                      "verification for every affected workspace."
                  end
                end
              end
            end

            render NitroKit::Sheet.new(id: "gallery-sheet-disabled", side: :right, size: :sm) do |sheet|
              sheet.trigger("Deployment details", disabled: true)
              sheet.panel(title: "Deployment details")
            end
          end
        end
      end
    end
  end
end
