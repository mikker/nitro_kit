# frozen_string_literal: true

class PropTable < Phlex::HTML
  def initialize(title)
    @title = title
    @t = NitroKit::Table.new
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
      safe("HTML attributes for <code>&lt;#{tag_name}&gt;</code> element.")
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
          pre(class: "whitespace-pre-wrap") do
            code(class: "font-bold") { title.strip_heredoc.strip }
          end
        end
      end

      t.tr(class: "bg-muted") do
        t.th("Property", class: "w-1/6")
        t.th("Default", class: "w-1/6")
        t.th("Description")
      end
    end
  end
end
