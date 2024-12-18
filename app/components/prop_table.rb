# frozen_string_literal: true

class PropTable < Phlex::HTML
  def initialize(title)
    @title = title
    @t = NitroKit::Table.new

    @lexer = Rouge::Lexer.find(:ruby)
    @formatter = Rouge::Formatters::HTML.new
  end

  attr_reader :t, :title

  def view_template
    render(t) do
      header_rows

      yield
    end
  end

  def prop(name, default = nil, &block)
    t.tr do
      t.td do
        code { plain(name) }
      end

      t.td do
        code { plain(default) } if default
      end

      t.td do
        safe(capture { yield })
      end
    end
  end

  def size_prop(list = [], default: :md)
    prop("size", default.inspect) do
      safe("One of <em><code>#{list.map(&:inspect).join("</code> / <code>")}</code></em>")
    end
  end

  def variant_prop(list = [], default: :default)
    prop("variant", default.inspect) do
      safe("One of <em><code>#{list.map(&:inspect).join("</code> / <code>")}</code></em>")
    end
  end

  def attrs_prop(tag_name)
    prop("**attrs") do
      case tag_name
      when String, Symbol
        safe("HTML attributes for <code>&lt;#{tag_name}&gt;</code> element.")
      when Class
        safe("Arguments for <code>#{tag_name.name}.new()</code>.")
      end
    end
  end

  def text_prop
    prop("text", "nil") do
      plain("Plain text content.")
    end
  end

  private

  def header_rows
    t.thead do
      t.tr do
        t.th(colspan: 3) do
          pre(
            class: "highlight"
          ) do
            code do
              @formatter.format(@lexer.lex(title.strip_heredoc.strip)).html_safe
            end
          end
        end
      end

      t.tr(class: "text-muted-foreground/80 bg-muted/50") do
        t.th("Property", class: "w-1/6")
        t.th("Default", class: "w-1/6")
        t.th("Description")
      end
    end
  end
end
