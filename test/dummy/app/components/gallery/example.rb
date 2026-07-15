module Gallery
  class Example < Primitive
    MODES = %i[constrained full_width].freeze
    LAYOUTS = %i[stack row matrix].freeze
    DENSITIES = %i[comfortable compact].freeze
    MINIMUM_PREVIEW_WIDTH = 320
    CONSTRAINED_PREVIEW_WIDTH = 640
    PREVIEW_STEP = 16
    BREAKPOINTS = NitroKit::ResponsiveValue::BREAKPOINTS.transform_values do |width|
      (width.delete_suffix("rem").to_f * 16).to_i
    end.freeze

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
      code:,
      preview_path: nil
    )
      @slug = normalize_slug(slug)
      @title = validate_text!(:title, title)
      @description = validate_text!(:description, description, optional: true)
      @mode = validate_choice!(:mode, mode, MODES)
      @layout = validate_choice!(:layout, layout, LAYOUTS)
      @density = validate_choice!(:density, density, DENSITIES)
      @scroll = validate_boolean!(:scroll, scroll)
      @notes = Notes.new(source:, api:)
      @preview_path = validate_text!(:preview_path, preview_path, optional: true)
      unless code.is_a?(SourceCode)
        raise ArgumentError, "Gallery::Example code must be a Gallery::SourceCode"
      end
      @code = code
    end

    attr_reader :slug, :title, :description, :mode, :layout, :density, :scroll, :notes, :code, :preview_path

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

          tabs.tab(:responsive, "Responsive") { responsive_preview } if preview_path

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

    def responsive_preview
      div(
        data: {
          controller: "gallery--preview",
          gallery: "responsive-preview",
          gallery_preview_mode: data_value(mode),
          gallery__preview_min_value: MINIMUM_PREVIEW_WIDTH,
          gallery__preview_constrained_value: CONSTRAINED_PREVIEW_WIDTH,
          gallery__preview_step_value: PREVIEW_STEP,
          gallery__preview_sm_value: BREAKPOINTS.fetch("sm"),
          gallery__preview_md_value: BREAKPOINTS.fetch("md"),
          gallery__preview_lg_value: BREAKPOINTS.fetch("lg"),
          gallery__preview_xl_value: BREAKPOINTS.fetch("xl"),
          gallery__preview_xxl_value: BREAKPOINTS.fetch("2xl")
        }
      ) do
        responsive_toolbar

        div(
          data: {
            gallery: "preview-track",
            gallery__preview_target: "track"
          }
        ) do
          div(
            data: {
              gallery: "preview-frame",
              gallery__preview_target: "frame"
            }
          ) do
            iframe(
              src: preview_path,
              title: "#{title} responsive preview",
              loading: "lazy",
              data: {
                gallery: "preview-iframe",
                gallery__preview_target: "iframe",
                action: "load->gallery--preview#loaded"
              }
            )
          end

          div(
            role: "separator",
            tabindex: "0",
            aria: {
              label: "Resize #{title} preview",
              orientation: "vertical",
              valuemin: MINIMUM_PREVIEW_WIDTH,
              valuenow: mode == :constrained ? CONSTRAINED_PREVIEW_WIDTH : nil,
              valuetext: mode == :constrained ? "#{CONSTRAINED_PREVIEW_WIDTH} pixels, sm breakpoint" : "Full width"
            }.compact,
            data: {
              gallery: "preview-handle",
              gallery__preview_target: "handle",
              action: [
                "pointerdown->gallery--preview#startDrag",
                "pointermove->gallery--preview#drag",
                "pointerup->gallery--preview#stopDrag",
                "pointercancel->gallery--preview#stopDrag",
                "lostpointercapture->gallery--preview#stopDrag",
                "keydown->gallery--preview#resizeWithKeyboard"
              ].join(" ")
            }
          )
        end
      end
    end

    def responsive_toolbar
      div(data: { gallery: "preview-toolbar" }) do
        div(data: { gallery: "preview-measurement" }) do
          strong { "Viewport" }
          output(
            id: preview_output_id,
            for: preview_range_id,
            data: { gallery__preview_target: "output" }
          ) { mode == :constrained ? "#{CONSTRAINED_PREVIEW_WIDTH} px · sm" : "Full width" }
        end

        div(data: { gallery: "preview-controls" }) do
          label(for: preview_range_id) do
            span { "Width" }
            input(
              id: preview_range_id,
              type: "range",
              min: MINIMUM_PREVIEW_WIDTH,
              max: CONSTRAINED_PREVIEW_WIDTH,
              step: 1,
              value: mode == :constrained ? CONSTRAINED_PREVIEW_WIDTH : CONSTRAINED_PREVIEW_WIDTH,
              aria: { describedby: preview_output_id },
              data: {
                gallery__preview_target: "range",
                action: "input->gallery--preview#resizeFromRange"
              }
            )
          end

          label(for: preview_preset_id) do
            span { "Preset" }
            select(
              id: preview_preset_id,
              data: {
                gallery__preview_target: "preset",
                action: "change->gallery--preview#choosePreset"
              }
            ) do
              option(value: "") { "Choose a breakpoint" }
              BREAKPOINTS.each do |name, width|
                option(value: width - 1) { "Below #{name} · #{width - 1} px" }
                option(value: width) { "#{name} · #{width} px" }
              end
            end
          end

          button(
            type: "button",
            data: {
              gallery__preview_target: "reset",
              action: "gallery--preview#reset"
            }
          ) { "Reset" }
          button(
            type: "button",
            data: {
              gallery__preview_target: "full",
              action: "gallery--preview#full"
            }
          ) { "Full width" }
        end
      end
    end

    def preview_range_id
      "#{example_id}-preview-width"
    end

    def preview_preset_id
      "#{example_id}-preview-preset"
    end

    def preview_output_id
      "#{example_id}-preview-output"
    end
  end
end
