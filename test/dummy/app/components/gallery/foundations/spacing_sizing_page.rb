module Gallery
  module Foundations
    class SpacingSizingPage < FoundationPage
      SPACING_STEPS = NitroKit::LayoutOptions::GAPS
      CONTROL_HEIGHTS = {
        xs: [ "1.5rem", "24px" ],
        sm: [ "1.75rem", "28px" ],
        md: [ "2.5rem", "40px" ],
        lg: [ "2.75rem", "44px" ],
        xl: [ "3.5rem", "56px" ]
      }.freeze
      CONTENT_WIDTHS = {
        sm: [ "24rem", "384px" ],
        md: [ "32rem", "512px" ],
        lg: [ "48rem", "768px" ],
        xl: [ "64rem", "1024px" ]
      }.freeze
      BREAKPOINTS = NitroKit::ResponsiveValue::BREAKPOINTS.freeze

      private

      def source_note
        "src/stylesheets/nitro_kit/tokens.css + app/components/nitro_kit/layout_options.rb"
      end

      def api_note
        "var(--nk-space), gap: 0 | 1 | 2 | 3 | 4 | 5 | 6 | 8 | 10 | 12 | 16"
      end

      def foundation_template
        render NitroKit::Alert.new(
          id: "gallery-spacing-alignment",
          variant: :info,
          title: "Tailwind alignment",
          description: "Nitro’s --nk-space is 0.25rem, matching Tailwind CSS v4’s --spacing, and the optional adapter aliases the two. A Flex or Grid gap of N therefore matches Tailwind’s gap-N. Nitro intentionally accepts only the subset shown below. Its default responsive breakpoints also match Tailwind; control heights and content widths are Nitro-specific."
        )

        example_section(
          "Spacing",
          slug: "spacing-scale",
          description: "The closed Flex and Grid gap scale multiplies the shared 0.25rem (4px) base unit."
        ) do
          example("Every gap", slug: "spacing-every-gap", mode: :full_width, scroll: true) do
            div(role: "list", data: { gallery: "measure-list" }) do
              SPACING_STEPS.each do |step|
                rem = step / 4.0
                measurement(
                  key: "space-#{step}",
                  label: "gap: #{step}",
                  value: "#{format_number(rem)}rem · #{step * 4}px",
                  css_value: "calc(var(--nk-space) * #{step})"
                )
              end
            end
          end
        end

        example_section(
          "Control heights",
          slug: "control-heights",
          description: "Five Nitro-specific tokens keep interactive controls aligned across component families."
        ) do
          example("Every control height", slug: "control-height-scale", mode: :full_width) do
            div(role: "list", data: { gallery: "measure-list" }) do
              CONTROL_HEIGHTS.each do |size, (rem, pixels)|
                measurement(
                  key: "control-#{size}",
                  label: "--nk-control-height-#{size}",
                  value: "#{rem} · #{pixels}",
                  css_value: "var(--nk-control-height-#{size})",
                  axis: :height
                )
              end
            end
          end
        end

        example_section(
          "Content widths",
          slug: "content-widths",
          description: "Container uses four Nitro-specific readable maximum widths; these are not Tailwind container breakpoints. Bars are normalized to xl so their proportions remain visible."
        ) do
          example("Every content width", slug: "content-width-scale", mode: :full_width) do
            div(role: "list", data: { gallery: "measure-list" }) do
              CONTENT_WIDTHS.each do |size, (rem, pixels)|
                measurement(
                  key: "content-#{size}",
                  label: "--nk-content-#{size}",
                  value: "#{rem} · #{pixels}",
                  css_value: percentage(rem, maximum: CONTENT_WIDTHS.fetch(:xl).first)
                )
              end
            end
          end
        end

        example_section(
          "Responsive breakpoints",
          slug: "responsive-breakpoints",
          description: "Responsive Flex and Grid values use Tailwind’s default mobile-first sm, md, lg, xl, and 2xl boundaries. Bars are normalized to 2xl so every boundary remains comparable."
        ) do
          example("Every breakpoint", slug: "responsive-breakpoint-scale", mode: :full_width) do
            div(role: "list", data: { gallery: "measure-list" }) do
              BREAKPOINTS.each do |name, rem|
                pixels = rem.delete_suffix("rem").to_f * 16
                measurement(
                  key: "breakpoint-#{name}",
                  label: name,
                  value: "#{rem} · #{format_number(pixels)}px",
                  css_value: percentage(rem, maximum: BREAKPOINTS.fetch("2xl"))
                )
              end
            end
          end
        end
      end

      def measurement(key:, label:, value:, css_value:, axis: :width)
        div(
          role: "listitem",
          data: { gallery: "measure", gallery_measure: key, gallery_measure_axis: axis }
        ) do
          div(data: { gallery: "measure-label" }) do
            code { label }
            render NitroKit::Badge.new(value, id: "gallery-measure-#{key}", size: :sm)
          end
          div(aria: { hidden: true }, data: { gallery: "measure-track" }) do
            span(style: "--gallery-measure: #{css_value}", data: { gallery: "measure-bar" })
          end
        end
      end

      def format_number(value)
        value.to_i == value ? value.to_i : value
      end

      def percentage(value, maximum:)
        "#{format_number(value.to_f / maximum.to_f * 100)}%"
      end
    end
  end
end
