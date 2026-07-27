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
            render NitroKit::Sheet.new(id: "gallery-sheet-prompts", side: :left, size: :sm) do |sheet|
              sheet.trigger("Prompts", icon: :list)
              sheet.panel(
                title: "Transcript prompts",
                description: "Jump to a prompt in this transcript."
              ) do
                render NitroKit::AppNavigation.new(label: "Transcript prompts") do |navigation|
                  navigation.body do |items|
                    items.item("Set up the project", href: "#prompt-1", current: true)
                    items.item("Review the implementation", href: "#prompt-2")
                    items.item("Prepare the release", href: "#prompt-3")
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
        end
      end
    end
  end
end
