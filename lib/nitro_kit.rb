require "tailwind_merge"
require "phlex/rails"

require "nitro_kit/variants"
require "nitro_kit/railtie"
require "nitro_kit/schema_builder"

module NitroKit
  extend SchemaBuilder

  SCHEMA = build_schema do |s|
    s.add(:accordion, js: [:accordion])
    s.add(:badge)
    s.add(:button, components: [:button, :button_group], helpers: [:button, :button_group])
    s.add(:card)
    s.add(:checkbox)
    s.add(:dropdown, js: [:dropdown], modules: ["@floating-ui/core", "@floating-ui/dom"])
    s.add(:icon, gems: ["lucide-rails"])
    s.add(:input)
    s.add(:label)
    s.add(:radio_button, components: [:radio_button, :radio_group])
    s.add(:switch, js: [:switch])

    # bit more advanced. Bundle into just "form" ?
    s.add(
      :field,
      components: [
        :field,
        :field_group,
        :fieldset,
        :input,
        :label
      ]
    )
  end
end
