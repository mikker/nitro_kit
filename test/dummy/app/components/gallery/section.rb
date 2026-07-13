module Gallery
  class Section < Primitive
    def initialize(slug:, title:, description: nil)
      @slug = normalize_slug(slug)
      @title = validate_text!(:title, title)
      @description = validate_text!(:description, description, optional: true)
    end

    attr_reader :slug, :title, :description

    def view_template(&block)
      section(
        id: section_id,
        aria: {
          labelledby: heading_id,
          describedby: description_id
        }.compact,
        data: {
          gallery: "section",
          gallery_section: slug
        }
      ) do
        header(data: { gallery: "section-header" }) do
          h2(id: heading_id) { title }
          p(id: description_id) { description } if description
        end

        yield if block
      end
    end

    private

    def section_id
      "section-#{slug}"
    end

    def heading_id
      "#{section_id}-title"
    end

    def description_id
      "#{section_id}-description" if description
    end
  end
end
