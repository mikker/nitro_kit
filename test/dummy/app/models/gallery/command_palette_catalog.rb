module Gallery
  module CommandPaletteCatalog
    Destination = ::Data.define(:label, :href, :description)

    DESTINATIONS = [
      Destination.new(label: "Dashboard", href: "#dashboard", description: "Workspace overview"),
      Destination.new(label: "Projects", href: "#projects", description: "Active and archived work"),
      Destination.new(label: "Billing", href: "#billing", description: "Plans, invoices, and payment methods"),
      Destination.new(label: "Team members", href: "#team-members", description: nil),
      Destination.new(
        label: "Buttons",
        href: "/gallery/components/button",
        description: "Component reference"
      )
    ].freeze

    module_function

    def search(query)
      normalized_query = query.to_s.strip.downcase
      return DESTINATIONS if normalized_query.blank?

      DESTINATIONS.select do |destination|
        [ destination.label, destination.description ].compact.join(" ").downcase.include?(normalized_query)
      end
    end
  end
end
