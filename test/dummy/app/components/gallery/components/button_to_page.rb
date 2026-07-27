module Gallery
  module Components
    class ButtonToPage < ComponentPage
      private

      def source_note
        "app/components/nitro_kit/button_to.rb"
      end

      def api_note
        "NitroKit::ButtonTo.new(text, href:, method:, variant:)"
      end

      def component_template
        example_section(
          "Rails mutations",
          slug: "button-to-mutations",
          description: "A layout-transparent Rails method form carries one typed submit Button."
        ) do
          example("Mutation treatments", slug: "button-to-treatments", layout: :matrix) do
            sample("Patch", slug: "patch") do
              render NitroKit::ButtonTo.new(
                "Archive project",
                href: "#archive-project",
                method: :patch,
                id: "gallery-button-to-archive",
                icon: :archive
              )
            end
            sample("Delete", slug: "delete") do
              render NitroKit::ButtonTo.new(
                "Delete project",
                href: "#delete-project",
                method: :delete,
                icon: :trash,
                variant: :destructive,
                data: { turbo_confirm: "Delete this project?" }
              )
            end
            sample("Icon only", slug: "icon-only") do
              render NitroKit::ButtonTo.new(
                nil,
                href: "#revoke-token",
                method: :delete,
                id: "gallery-button-to-revoke",
                icon: :x,
                label: "Revoke API token",
                size: :xs
              )
            end
          end
        end
      end
    end
  end
end
