module Gallery
  class Sample < Primitive
    def initialize(slug:, label:, description: nil)
      @slug = normalize_slug(slug)
      @label = validate_text!(:label, label)
      @description = validate_text!(:description, description, optional: true)
    end

    attr_reader :slug, :label, :description

    def view_template(&block)
      figure(data: { gallery: "sample", gallery_sample: slug }) do
        figcaption do
          strong { label }
          small { description } if description
        end

        div(data: { gallery: "sample-content" }) do
          yield if block
        end
      end
    end
  end
end
