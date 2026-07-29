module Gallery
  class CommandPaletteResults < Primitive
    def initialize(query:)
      @destinations = CommandPaletteCatalog.search(query)
    end

    def view_template
      render NitroKit::CommandPalette::Results.new(id: "gallery-command-palette-async") do |results|
        @destinations.each do |destination|
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
