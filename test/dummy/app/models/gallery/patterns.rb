module Gallery
  # The application interaction conventions in `docs/patterns/*.md`. Each
  # document owns a leading "## Summary" section; the gallery renders that
  # section so a pattern summary has exactly one source.
  module Patterns
    DIRECTORY = NitroKit::Engine.root.join("docs/patterns")
    SUMMARY_HEADING = "## Summary".freeze
    HEADING = /\A#+ /

    Pattern = ::Data.define(:slug, :title, :path, :points)

    class PatternNotFound < KeyError
    end

    class SummaryMissing < StandardError
    end

    module_function

    def all
      @all ||= DIRECTORY.glob("*.md").sort.to_h do |path|
        [ path.basename(".md").to_s, parse(path) ]
      end.freeze
    end

    def slugs
      all.keys
    end

    def fetch!(slug)
      all[slug.to_s] || raise(PatternNotFound, "Unknown pattern #{slug.inspect} in docs/patterns")
    end

    def parse(path)
      lines = path.readlines(chomp: true)
      slug = path.basename(".md").to_s
      points = summary_points(lines)

      if points.empty?
        raise SummaryMissing, "docs/patterns/#{path.basename} needs a leading \"#{SUMMARY_HEADING}\" section"
      end

      Pattern.new(
        slug:,
        title: lines.find { |line| line.start_with?("# ") }.to_s.delete_prefix("# "),
        path: "docs/patterns/#{path.basename}",
        points:
      )
    end

    # Bullets may wrap across lines; an indented continuation belongs to the
    # bullet above it.
    def summary_points(lines)
      start = lines.index(SUMMARY_HEADING)
      return [] unless start

      points = []

      lines.drop(start + 1).each do |line|
        break if line.match?(HEADING)

        if line.start_with?("- ")
          points << line.delete_prefix("- ")
        elsif line.start_with?("  ") && points.any?
          points[-1] = "#{points.last} #{line.strip}"
        end
      end

      points.freeze
    end

    private_class_method :parse, :summary_points
  end
end
