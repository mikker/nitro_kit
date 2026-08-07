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
      end
    end
  end
end
