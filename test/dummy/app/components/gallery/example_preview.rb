module Gallery
  class ExamplePreview < Primitive
    def initialize(slug:, title:, mode:, layout:, density:, scroll:)
      @slug = normalize_slug(slug)
      @title = validate_text!(:title, title)
      @mode = validate_choice!(:mode, mode, Example::MODES)
      @layout = validate_choice!(:layout, layout, Example::LAYOUTS)
      @density = validate_choice!(:density, density, Example::DENSITIES)
      @scroll = validate_boolean!(:scroll, scroll)
    end

    attr_reader :slug, :title, :mode, :layout, :density, :scroll

    def view_template(&block)
      raise ArgumentError, "Gallery::ExamplePreview requires a preview block" unless block

      main(
        aria: { label: "#{title} responsive preview" },
        data: {
          gallery: "example",
          gallery_example: slug,
          gallery_mode: data_value(mode),
          gallery_layout: data_value(layout),
          gallery_density: data_value(density),
          gallery_scroll: scroll ? "true" : nil,
          gallery_responsive_preview: "true"
        }.compact
      ) do
        div(data: { gallery: "example-canvas" }) { yield }
      end
    end
  end
end
