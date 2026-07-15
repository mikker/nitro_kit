module Gallery
  class RansackSort
    def initialize(search, path:, filters: {})
      unless search.is_a?(Ransack::Search)
        raise ArgumentError, "Gallery::RansackSort requires a Ransack::Search"
      end
      unless path.is_a?(String) && path.present?
        raise ArgumentError, "Gallery::RansackSort path must be a non-blank String"
      end

      @search = search
      @path = path
      @filters = filters.to_h.stringify_keys
    end

    def current
      current_sort&.name
    end

    def direction
      current_sort&.dir&.to_sym
    end

    def parameters
      sort = "#{current} #{direction}" if current && direction
      @filters.merge("s" => sort).compact
    end

    def href_for(key)
      key = normalize_key(key)
      query = parameters.merge("s" => "#{key} #{next_direction(key)}")

      "#{@path}?#{Rack::Utils.build_nested_query(q: query)}"
    end

    private

    def current_sort
      @current_sort ||= @search.sorts.first
    end

    def next_direction(key)
      current == key && direction == :asc ? :desc : :asc
    end

    def normalize_key(key)
      normalized = key.to_s.strip if key.is_a?(Symbol) || key.is_a?(String)
      return normalized if normalized.present?

      raise ArgumentError, "Gallery::RansackSort key must be a Symbol or non-blank String"
    end
  end
end
