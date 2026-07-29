module Gallery
  # This component's own row from the shipped contract table. The row is parsed
  # from `docs/component_contracts.md` at render time, so a page never restates
  # a contract that the document can move on from.
  class ComponentContract < Primitive
    DESCRIPTION = "Constructor options, rendered root, closed vocabularies, and compound boundary for this " \
      "component, exactly as shipped.".freeze

    def initialize(row)
      @row = row
    end

    attr_reader :row

    def view_template
      render Reference.new(
        slug: "contract",
        title: "Component contract",
        description: DESCRIPTION,
        source: "#{row.path} · NitroKit::#{row.component}"
      ) do
        dl(data: { gallery: "reference-fields" }) do
          row.fields.each do |field|
            div do
              dt { field.label }
              dd { render_field(field) }
            end
          end
        end
      end
    end

    private

    def render_field(field)
      if field.label == "Constructor-specific options"
        ul(data: { gallery: "contract-options" }) do
          field.value.split("; ").each do |option|
            li { render MarkdownText.new(option) }
          end
        end
      else
        render MarkdownText.new(field.value)
      end
    end
  end
end
