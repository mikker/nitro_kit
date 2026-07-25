module Gallery
  module Components
    class AppearancePickerPage < ComponentPage
      private

      def source_note
        "app/components/nitro_kit/appearance_picker.rb"
      end

      def api_note
        "NitroKit::AppearancePicker.new(id:, label: \"Appearance\")"
      end

      def component_template
        example_section(
          "Native preferences",
          slug: "appearance-picker-native",
          description: "Light, dark, and system remain labelled radio choices without JavaScript."
        ) do
          example("Default appearance", slug: "appearance-picker-default") do
            render NitroKit::AppearancePicker.new(id: "gallery-appearance-default")
          end

          example("Product language", slug: "appearance-picker-product-language") do
            render NitroKit::AppearancePicker.new(
              id: "gallery-appearance-product",
              label: "Color appearance"
            )
          end


          example("Navigation dropdown", slug: "appearance-picker-dropdown") do
            render NitroKit::AppearancePicker.new(
              id: "gallery-appearance-dropdown",
              presentation: :dropdown
            )
          end
        end

        example_section(
          "Synchronized subscribers",
          slug: "appearance-picker-subscribers",
          description: "Every mounted picker reflects the one document-owned preference."
        ) do
          example("Two controls for one preference", slug: "appearance-picker-two-controls", layout: :matrix) do
            sample("Navigation control", slug: "navigation-control") do
              render NitroKit::AppearancePicker.new(
                id: "gallery-appearance-navigation",
                label: "Site appearance"
              )
            end

            sample("Settings control", slug: "settings-control") do
              render NitroKit::AppearancePicker.new(
                id: "gallery-appearance-settings",
                label: "Account appearance"
              )
            end
          end
        end

        example_section(
          "Application composition",
          slug: "appearance-picker-composition",
          description: "Appearance is a document preference, even when the control lives in a settings surface."
        ) do
          example("Personalization card", slug: "appearance-picker-card") do
            render NitroKit::Card.new(id: "gallery-appearance-card") do |card|
              card.title("Personalization", level: 3)
              card.body do
                p { "Choose a fixed appearance or keep this browser in step with the operating system." }
                render NitroKit::AppearancePicker.new(
                  id: "gallery-appearance-card-control",
                  label: "Interface appearance"
                )
              end
              card.footer do
                render NitroKit::Badge.new("Saved in this browser", variant: :outline, color: :neutral)
              end
            end
          end
        end
      end
    end
  end
end
