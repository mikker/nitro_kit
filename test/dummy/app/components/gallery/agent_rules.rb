module Gallery
  # The system rules every Nitro Kit component obeys, rendered identically on
  # every component page and served as text from /llms.txt. This is the only
  # copy of the text, and the reserved attribute lists are read from
  # NitroKit::Component at render time so they cannot drift from the
  # implementation.
  class AgentRules < Primitive
    SOURCE = "test/dummy/app/components/gallery/agent_rules.rb".freeze
    DESCRIPTION = "These hold for every Nitro Kit component. They are rendered from one source on " \
      "every page, so a single fetched page is enough to compose correctly.".freeze

    class << self
      def rules
        [
          "Composition is the whole API: `render NitroKit::Button.new(\"Save\", variant: :primary)`. " \
            "There are no `nk_*` helpers, no ERB bridge, and no generator that copies component source " \
            "into an application.",
          "Every public option is an explicit keyword. No component accepts a catch-all `**options`, so a " \
            "misspelled keyword raises `ArgumentError` instead of leaking into the HTML.",
          "Every enumerated option is a closed vocabulary. An unknown value raises `ArgumentError` naming " \
            "the accepted set; this component's vocabularies are in the contract above.",
          "Native attributes cross one boundary: `html:` carries HTML attributes, `aria:` carries ARIA, and " \
            "`data:` carries application data attributes. Nothing else is forwarded.",
          "`NitroKit::Component::RESERVED_DATA_ATTRIBUTES` is #{list(NitroKit::Component::RESERVED_DATA_ATTRIBUTES)}. " \
            "Passing any of them through `data:` raises \"reserved by Nitro Kit\".",
          "`NitroKit::Component::COMPONENT_OWNED_DATA_ATTRIBUTES` — " \
            "#{list(NitroKit::Component::COMPONENT_OWNED_DATA_ATTRIBUTES)} — " \
            "is the subset a component sets for itself while rendering.",
          "`NitroKit::Component::ADDITIVE_DATA_ATTRIBUTES` — " \
            "#{list(NitroKit::Component::ADDITIVE_DATA_ATTRIBUTES)} — compose " \
            "additively with Nitro behavior instead of raising.",
          "`NitroKit::Component::FORBIDDEN_ATTRIBUTES` — " \
            "#{list(NitroKit::Component::FORBIDDEN_ATTRIBUTES, prefix: "")} — are " \
            "rejected everywhere, including inside `html:`.",
          "The single styling escape is `desperately_need_a_class:`. It requires a non-blank String and emits " \
            "both the class and `data-nk-escape=\"class\"`. There is no untyped structural bypass.",
          "`variant:` and `size:` on a root are the component's identity axes and are emitted only by the base " \
            "component. A slot carries its own `data-variant` only when it has variant identity of its own — " \
            "`Toast::Item` and Dropdown items — and caller `data: { variant: }` stays reserved in both cases.",
          "Every root emits `data-nk`; owned parts emit component-qualified `data-slot` values such as " \
            "`field-control` or `card-title`. Select on those attributes, never on classes.",
          "State is exposed through native semantics and ARIA first and through `data-state` second. Nitro " \
            "components never emit or depend on classes."
        ]
      end

      private

      def list(names, prefix: "data-")
        names.map { |name| "`#{prefix}#{name}`" }.join(", ")
      end
    end

    def view_template
      render Reference.new(
        slug: "system-rules",
        title: "System rules",
        description: DESCRIPTION,
        source: SOURCE
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
