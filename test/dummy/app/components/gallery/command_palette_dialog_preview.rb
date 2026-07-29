module Gallery
  class CommandPaletteDialogPreview < Primitive
    def view_template
      div(
        role: "img",
        aria: { label: "Open command palette dialog" },
        inert: true,
        data: {
          nk: "command-palette",
          enhanced: "true",
          gallery: "command-palette-dialog-preview"
        }
      ) do
        div(data: { slot: "command-palette-panel" }) do
          h2(
            id: "gallery-command-palette-preview-title",
            data: { slot: "command-palette-title" }
          ) { "Search workspace" }

          div(data: { slot: "command-palette-search" }) do
            span(data: { slot: "command-palette-search-icon" }) do
              render NitroKit::Icon.new(:search, size: :sm)
            end
            span(data: { gallery: "command-palette-preview-input" }) { "Search destinations…" }
            span(data: { slot: "command-palette-close" }) do
              render NitroKit::Icon.new(:x, size: :sm)
            end
          end

          render NitroKit::CommandPalette::Results.new(id: "gallery-command-palette-preview") do |results|
            CommandPaletteCatalog::DESTINATIONS.first(3).each do |destination|
              results.destination(
                destination.label,
                href: destination.href,
                description: destination.description
              )
            end
          end
        end
      end
    end
  end
end
