module Gallery
  module Components
    class CommandPalettePage < ComponentPage
      private

      def source_note
        "app/components/nitro_kit/command_palette.rb"
      end

      def api_note
        "NitroKit::CommandPalette.new(id:, search_url: nil) { |palette| palette.destination(...) }"
      end

      def component_template
        example_section(
          "Destination search",
          slug: "command-palette-search",
          description: "A native dialog and links remain usable without JavaScript; enhancement adds Command-K, filtering, and result announcements."
        ) do
          sample(
            "Dialog contents",
            slug: "command-palette-dialog-contents",
            description: "Open-state anatomy, shown inline so the result hierarchy is visible at a glance."
          ) do
            render CommandPaletteDialogPreview.new
          end

          example("Workspace destinations", slug: "command-palette-workspace") do
            render NitroKit::CommandPalette.new(
              id: "gallery-command-palette-workspace",
              label: "Search workspace…",
              placeholder: "Search destinations…",
              shortcut: false
            ) do |palette|
              palette.destination("Dashboard", href: "#dashboard", description: "Workspace overview")
              palette.destination("Projects", href: "#projects", description: "Active and archived work")
              palette.destination(
                "Billing",
                href: "#billing",
                description: "Plans, invoices, and payment methods"
              )
              palette.destination("Team members", href: "#team-members")
              palette.destination(
                "Buttons",
                href: "/gallery/components/button",
                description: "Component reference"
              )
            end
          end

          example(
            "Global shortcut",
            slug: "command-palette-shortcut",
            description: "The default shortcut: true owns Command-K, labels the trigger hint, and exposes aria-keyshortcuts."
          ) do
            render NitroKit::CommandPalette.new(
              id: "gallery-command-palette-shortcut",
              label: "Search workspace…",
              placeholder: "Search destinations…"
            ) do |palette|
              palette.destination("Dashboard", href: "#dashboard", description: "Workspace overview")
              palette.destination("Projects", href: "#projects", description: "Active and archived work")
              palette.destination("Billing", href: "#billing", description: "Plans and invoices")
            end
          end

          example(
            "Many long destinations",
            slug: "command-palette-many-destinations",
            description: "A long result list scrolls inside the panel instead of growing past its 26rem cap."
          ) do
            render NitroKit::CommandPalette.new(
              id: "gallery-command-palette-many",
              label: "Search workspace…",
              placeholder: "Search destinations…",
              shortcut: false
            ) do |palette|
              (1..18).each do |number|
                palette.destination(
                  "Quarterly compliance and audit-retention report #{number}",
                  href: "#report-#{number}",
                  description: "Retention evidence, reviewer sign-off, and export history for period #{number}"
                )
              end
            end
          end

          example(
            "Server-rendered results",
            slug: "command-palette-async",
            description: "The search form targets a Turbo Frame; the endpoint returns CommandPalette::Results HTML.",
            source: "app/controllers/command_palette_results_controller.rb + index view",
            api: "GET query → NitroKit::CommandPalette::Results.new(id: same_palette_id)"
          ) do
            render NitroKit::CommandPalette.new(
              id: "gallery-command-palette-async",
              label: "Search workspace…",
              placeholder: "Search destinations…",
              search_url: gallery_command_palette_results_path,
              shortcut: false
            ) do |palette|
              palette.destination("Dashboard", href: "#dashboard", description: "Workspace overview")
              palette.destination("Projects", href: "#projects", description: "Active and archived work")
              palette.destination("Billing", href: "#billing", description: "Plans and invoices")
            end
          end
        end

        example_section(
          "Under pressure",
          slug: "command-palette-stress",
          description: "Every Gallery::Hostile navigation label as a destination with a long URL and a long or unbroken description, behind a long-labelled trigger and again as inline open results."
        ) do
          example("Hostile trigger and dialog", slug: "command-palette-hostile", stress: true) do
            render NitroKit::CommandPalette.new(
              id: "gallery-command-palette-hostile",
              label: Gallery::Hostile::LONG_LABEL,
              placeholder: Gallery::Hostile::LONG_SENTENCE,
              empty_text: Gallery::Hostile::LONG_PARAGRAPH,
              shortcut: false
            ) do |palette|
              Gallery::Hostile::NAVIGATION_LABELS.each_with_index do |label, index|
                palette.destination(
                  label,
                  href: "#{Gallery::Hostile::LONG_URL}#destination-#{index}",
                  description: index.even? ? Gallery::Hostile::LONG_SENTENCE : Gallery::Hostile::LONG_WORD
                )
              end
            end
          end

          example("Hostile open results", slug: "command-palette-hostile-results", stress: true) do
            h2(id: "gallery-command-palette-hostile-results-title") { Gallery::Hostile::LONG_LABEL }
            render NitroKit::CommandPalette::Results.new(id: "gallery-command-palette-hostile-results") do |results|
              Gallery::Hostile::NAVIGATION_LABELS.each_with_index do |label, index|
                results.destination(
                  label,
                  href: "#{Gallery::Hostile::LONG_URL}#result-#{index}",
                  description: index.even? ? Gallery::Hostile::LONG_SENTENCE : Gallery::Hostile::LONG_WORD
                )
              end
            end
          end
        end
      end
    end
  end
end
