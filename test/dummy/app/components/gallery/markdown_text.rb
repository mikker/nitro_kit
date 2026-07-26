module Gallery
  # Renders the inline Markdown the shipped documents actually use: backticked
  # code spans and relative document links. Prose comes from the documents, so
  # the gallery never restates it.
  class MarkdownText < Primitive
    TOKEN = /(`[^`]+`|\[[^\]]+\]\([^)]+\))/
    CODE = /\A`(.+)`\z/m
    LINK = /\A\[([^\]]+)\]\(([^)]+)\)\z/

    def initialize(text)
      @text = validate_text!(:text, text)
    end

    attr_reader :text

    def view_template
      text.split(TOKEN).each do |token|
        next if token.empty?

        case token
        when CODE then code { Regexp.last_match(1) }
        when LINK then plain "#{Regexp.last_match(1)} (docs/#{Regexp.last_match(2)})"
        else plain token
        end
      end
    end
  end
end
