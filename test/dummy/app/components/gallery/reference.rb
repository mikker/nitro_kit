module Gallery
  # Page chrome for the agent-facing reference sections that follow the
  # examples. It deliberately renders outside every example canvas, so the
  # canvas assertions and extracted example source stay untouched.
  class Reference < Primitive
    def initialize(slug:, title:, source:, description: nil)
      @slug = normalize_slug(slug)
      @title = validate_text!(:title, title)
      @source = validate_text!(:source, source)
      @description = validate_text!(:description, description, optional: true)
    end

    attr_reader :slug, :title, :source, :description

    def view_template(&block)
      section(
        id: section_id,
        aria: { labelledby: heading_id },
        data: {
          gallery: "reference",
          gallery_reference: slug
        }
      ) do
        header(data: { gallery: "reference-header" }) do
          h2(id: heading_id) { title }
          p { description } if description
          p(data: { gallery: "reference-source" }) { code { source } }
        end

        yield if block
      end
    end

    private

    def section_id
      "reference-#{slug}"
    end

    def heading_id
      "#{section_id}-title"
    end
  end
end
