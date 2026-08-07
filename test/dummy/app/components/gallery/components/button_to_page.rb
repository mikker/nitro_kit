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

          example(
            "Boundaries and states",
            slug: "button-to-boundaries",
            layout: :matrix,
            description: "GET forms, disabled and loading submits, and the nested button_* boundaries that decorate the trigger instead of the form root."
          ) do
            sample("GET", slug: "get") do
              render NitroKit::ButtonTo.new(
                "View audit log",
                href: "#audit-log",
                method: :get,
                id: "gallery-button-to-get"
              )
            end
            sample("Disabled", slug: "disabled") do
              render NitroKit::ButtonTo.new(
                "Delete workspace",
                href: "#delete-locked",
                method: :delete,
                id: "gallery-button-to-disabled",
                variant: :destructive,
                disabled: true
              )
            end
            sample("Loading", slug: "loading") do
              render NitroKit::ButtonTo.new(
                "Archiving project",
                href: "#archive-loading",
                method: :patch,
                id: "gallery-button-to-loading",
                loading: true
              )
            end
            sample("Nested button boundaries", slug: "nested-boundaries") do
              render NitroKit::ButtonTo.new(
                "Export data",
                href: "#export-data",
                id: "gallery-button-to-boundaries",
                button_html: { title: "Runs in the background" },
                button_aria: { keyshortcuts: "Meta+E" },
                button_data: { turbo_submits_with: "Exporting…" }
              )
            end
          end
        end
      end
    end
  end
end
