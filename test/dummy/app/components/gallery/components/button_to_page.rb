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

        example_section(
          "Under pressure",
          slug: "button-to-stress",
          description: "Mutation buttons labelled with Gallery::Hostile text, from an eighty-character setting name and an unbroken hundred-letter word to RTL, CJK, and emoji names, all posting to a 200-character webhook URL."
        ) do
          example("Hostile mutations", slug: "button-to-hostile", layout: :row, stress: true) do
            [
              Gallery::Hostile::LONG_LABEL,
              Gallery::Hostile::LONG_WORD,
              Gallery::Hostile::RTL_NAME,
              Gallery::Hostile::CJK_NAME,
              Gallery::Hostile::EMOJI_NAME
            ].each_with_index do |label, index|
              render NitroKit::ButtonTo.new(
                label,
                href: Gallery::Hostile::LONG_URL,
                method: index.even? ? :patch : :delete,
                id: "gallery-button-to-hostile-#{index + 1}",
                variant: index.odd? ? :destructive : :default,
                icon: index.odd? ? :trash_2 : :archive
              )
            end
          end

          example("Hostile mutation in a small container", slug: "button-to-hostile-narrow", stress: true) do
            render NitroKit::Container.new(size: :sm, id: "gallery-button-to-hostile-narrow-container") do
              render NitroKit::ButtonTo.new(
                "Delete #{Gallery::Hostile::LONG_NAME}",
                href: Gallery::Hostile::LONG_URL,
                method: :delete,
                id: "gallery-button-to-hostile-narrow",
                variant: :destructive,
                icon: :trash_2,
                size: :lg
              )
            end
          end
        end
      end
    end
  end
end
