module Gallery
  # The system rules every Nitro Kit component obeys, rendered identically on
  # every component page and served as text from /llms.txt. This is the only
  # copy of the text, and the reserved attribute lists are read from
  # NitroKit::Component at render time so they cannot drift from the
  # implementation.
  class AgentRules < Primitive
    SOURCE = "test/dummy/app/components/gallery/agent_rules.rb".freeze
    DESCRIPTION = "Instructions for coding agents, repeated on every component page so one fetched " \
      "page has enough context. Humans can usually skip this section.".freeze

    class << self
      def rules
        [
          "Nitro Kit 2.0 is a gem-owned, Phlex-only UI system for Rails. Render components directly: " \
            "`render NitroKit::Button.new(\"Save\", variant: :primary)`.",
          "Compose Nitro components inside application-owned Phlex classes. Public initializers and declared " \
            "slots are the component API; private methods are not.",
          "Public options are explicit keywords, and enumerated options are closed vocabularies. Invalid names " \
            "or values raise `ArgumentError`; this component's accepted options are in the contract above.",
          "Pass native attributes through their typed boundary: `html:` for HTML, `aria:` for ARIA, and `data:` " \
            "for application data. `class` and `style` are forbidden, including inside `html:`.",
          "Nitro owns `NitroKit::Component::RESERVED_DATA_ATTRIBUTES`: " \
            "#{list(NitroKit::Component::RESERVED_DATA_ATTRIBUTES)}. Do not pass them through `data:`. " \
            "#{list(NitroKit::Component::ADDITIVE_DATA_ATTRIBUTES)} are additive and compose with Nitro behavior.",
          "If an integration truly requires a class, use `desperately_need_a_class:`. It requires a non-blank " \
            "String and marks the exception with `data-nk-escape=\"class\"`.",
          "Every root emits `data-nk`; owned parts emit component-qualified `data-slot` values such as " \
            "`field-control` or `card-title`. Select on those attributes, never on classes.",
          "Customize components with documented `--nk-*` custom properties in an application stylesheet. " \
            "Variables beginning with `--_nk-*` are private component mechanics.",
          "Use `NitroKit::Flex` and `NitroKit::Grid` for layout. Parents own external placement and available " \
            "width; components own their intrinsic geometry.",
          "Preserve native elements and accessibility semantics. State is exposed through native semantics and " \
            "ARIA first, and through `data-state` when styling or behavior also needs it."
        ]
      end

      private

      def list(names)
        names.map { |name| "`data-#{name}`" }.join(", ")
      end
    end

    def view_template
      render Reference.new(
        slug: "system-rules",
        title: "System rules for coding agents",
        description: DESCRIPTION,
        source: SOURCE,
        collapsible: true
      ) do
        ul(data: { gallery: "reference-rules" }) do
          rules.each { |rule| li { render MarkdownText.new(rule) } }
        end
      end
    end

    private

    def rules
      self.class.rules
    end
  end
end
