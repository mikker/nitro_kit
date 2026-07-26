module Gallery
  # The application conventions that apply to this component, summarized inline
  # rather than linked. Every summary is the "Summary" section of its own
  # pattern document; the catalog declares which patterns a page carries.
  class PatternNotes < Primitive
    DESCRIPTION = "Application conventions this component belongs to. Each summary is the leading section of " \
      "its pattern document.".freeze

    def initialize(patterns)
      @patterns = patterns
    end

    attr_reader :patterns

    def view_template
      return if patterns.empty?

      render Reference.new(
        slug: "patterns",
        title: "Relevant patterns",
        description: DESCRIPTION,
        source: patterns.map(&:path).join(" · ")
      ) do
        patterns.each { |pattern| pattern_summary(pattern) }
      end
    end

    private

    def pattern_summary(pattern)
      article(
        data: {
          gallery: "reference-pattern",
          gallery_pattern: pattern.slug
        }
      ) do
        h3 { pattern.title }
        ul do
          pattern.points.each { |point| li { render MarkdownText.new(point) } }
        end
      end
    end
  end
end
