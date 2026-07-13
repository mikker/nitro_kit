module Gallery
  class Notes < Primitive
    def initialize(source: nil, api: nil)
      @source = validate_text!(:source, source, optional: true)
      @api = validate_text!(:api, api, optional: true)
    end

    attr_reader :source, :api

    def any?
      source.present? || api.present?
    end

    def view_template
      return unless any?

      dl(data: { gallery: "notes" }) do
        note("Source", source) if source
        note("API", api) if api
      end
    end

    private

    def note(label, value)
      div do
        dt { label }
        dd { code { value } }
      end
    end
  end
end
