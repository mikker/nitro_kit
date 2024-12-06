require "tailwind_merge"
require "phlex/rails"

require "nitro_kit/variants"
require "nitro_kit/railtie"
require "nitro_kit/schema_builder"

module NitroKit
  extend SchemaBuilder

  SCHEMA = build_schema do |s|
    s.add(:accordion, js: [:accordion])
    s.add(:alert)
    s.add(:avatar)
    s.add(:badge)
    s.add(:button, components: [:button, :button_group], helpers: [:button])
    s.add(:card)
    s.add(:checkbox, components: [:checkbox, :checkbox_group])
    s.add(:combobox, js: [:combobox])
    s.add(:dialog, js: [:dialog])
    s.add(:dropdown, js: [:dropdown], modules: ["@floating-ui/core", "@floating-ui/dom"])
    s.add(:icon, gems: ["lucide-rails"])
    s.add(:pagination)
    s.add(:radio_button, components: [:radio_button, :radio_group])
    s.add(:select)
    s.add(:switch, js: [:switch])
    s.add(:table)
    s.add(:tabs, js: [:tabs])
    s.add(:textarea)
    s.add(:toast, js: [:toast])
    s.add(:tooltip, js: [:tooltip])

    # bit more advanced. Bundle into just "form" ?
    s.add(
      :form,
      components: [
        :field,
        :field_group,
        :fieldset,
        :input,
        :label,
        :form_builder
      ]
    )
  end
end
