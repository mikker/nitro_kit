module Gallery
  class Example < Primitive
    MODES = %i[constrained full_width].freeze
    LAYOUTS = %i[stack row matrix].freeze
    DENSITIES = %i[comfortable compact].freeze

    def initialize(
      slug:,
      title:,
      description: nil,
      mode: :constrained,
      layout: :stack,
      density: :comfortable,
      scroll: false,
      source: nil,
      api: nil,
      code:
    )
      @slug = normalize_slug(slug)
      @title = validate_text!(:title, title)
      @description = validate_text!(:description, description, optional: true)
      @mode = validate_choice!(:mode, mode, MODES)
      @layout = validate_choice!(:layout, layout, LAYOUTS)
      @density = validate_choice!(:density, density, DENSITIES)
      @scroll = validate_boolean!(:scroll, scroll)
      @notes = Notes.new(source:, api:)
      unless code.is_a?(SourceCode)
        raise ArgumentError, "Gallery::Example code must be a Gallery::SourceCode"
      end
      @code = code
    end

    attr_reader :slug, :title, :description, :mode, :layout, :density, :scroll, :notes, :code

    def view_template(&block)
      raise ArgumentError, "Gallery::Example requires a preview block" unless block

      section(
        id: example_id,
        aria: {
          labelledby: heading_id,
          describedby: description_id
        }.compact,
        data: {
          gallery: "example",
          gallery_example: slug,
          gallery_mode: data_value(mode),
          gallery_layout: data_value(layout),
          gallery_density: data_value(density),
          gallery_scroll: scroll ? "true" : nil
        }.compact
      ) do
        header(data: { gallery: "example-header" }) do
          h3(id: heading_id) { title }
          p(id: description_id) { description } if description
          render(notes) if notes.any?
        end

        render NitroKit::Tabs.new(
          id: presentation_id,
          label: "#{title} example",
          default: :preview,
          data: { gallery: "example-tabs" }
        ) do |tabs|
          tabs.tab(:preview, "Preview") do
            div(data: { gallery: "example-canvas" }) { yield }
          end

          tabs.tab(:code, "Code") do
            render CodeSample.new(id: code_sample_id, source: code)
          end
        end
      end
    end

    private

    def example_id
      "example-#{slug}"
    end

    def heading_id
      "#{example_id}-title"
    end

    def description_id
      "#{example_id}-description" if description
    end

    def presentation_id
      "#{example_id}-presentation"
    end

    def code_sample_id
      "#{example_id}-code"
    end
  end
end
