require "ripper"

module Gallery
  class CodeSample < Primitive
    TOKEN_GROUPS = {
      on_comment: "comment",
      on_embdoc: "comment",
      on_embdoc_beg: "comment",
      on_embdoc_end: "comment",
      on_kw: "keyword",
      on_const: "constant",
      on_label: "symbol",
      on_symbeg: "symbol",
      on_tstring_beg: "string",
      on_tstring_content: "string",
      on_tstring_end: "string",
      on_regexp_beg: "string",
      on_regexp_end: "string",
      on_int: "number",
      on_float: "number",
      on_rational: "number",
      on_imaginary: "number",
      on_ivar: "variable",
      on_cvar: "variable",
      on_gvar: "variable"
    }.freeze

    def initialize(id:, source:)
      @identifier = normalize_slug(id)
      unless source.is_a?(SourceCode)
        raise ArgumentError, "Gallery::CodeSample source must be a Gallery::SourceCode"
      end

      @source = source
    end

    attr_reader :identifier, :source

    def view_template
      div(
        id: identifier,
        data: {
          gallery: "code-sample",
          controller: "gallery--code-sample"
        }
      ) do
        header(data: { gallery: "code-toolbar" }) do
          render NitroKit::Toolbar.new do |toolbar|
            toolbar.leading do
              strong { "Ruby" }
              code(data: { gallery: "code-path" }) { source.path }
            end

            toolbar.trailing do
              span(
                id: status_id,
                role: "status",
                aria: { live: "polite" },
                data: { gallery_code_status: true, gallery__code_sample_target: "status" }
              )
              render NitroKit::Button.new(
                "Copy",
                id: copy_button_id,
                type: :button,
                size: :md,
                variant: :ghost,
                icon: :copy,
                aria: { describedby: status_id },
                data: { action: "gallery--code-sample#copy" }
              )
            end
          end
        end

        pre(
          tabindex: 0,
          aria: { label: "Ruby source from #{source.path}" },
          data: { gallery: "code-source", gallery__code_sample_target: "source" }
        ) do
          code { highlighted_source }
        end
      end
    end

    private

    def highlighted_source
      Ripper.lex(source.content).each do |(_position, event, text, _state)|
        token = TOKEN_GROUPS[event]

        if token
          span(data: { gallery_token: token }) { plain(text) }
        else
          plain(text)
        end
      end
    end

    def copy_button_id
      "#{identifier}-copy"
    end

    def status_id
      "#{identifier}-copy-status"
    end
  end
end
