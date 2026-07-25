module Gallery
  module Components
    class ButtonPage < ComponentPage
      private

      def source_note
        "app/components/nitro_kit/button.rb"
      end

      def api_note
        "NitroKit::Button.new(text, variant:, size:, icon:)"
      end

      def component_template
        example_section(
          "Variants",
          slug: "button-variants",
          description: "Every visual intent uses the same native button contract."
        ) do
          example(
            "Variant matrix",
            slug: "button-variant-matrix",
            mode: :full_width,
            layout: :matrix,
            density: :compact
          ) do
            Gallery::Data.button_variants.each do |button|
              sample(button.label, slug: button.slug) do
                render_button(button, id: "gallery-button-variant-#{button.slug}")
              end
            end
          end
        end

        example_section(
          "Sizes",
          slug: "button-sizes",
          description: "Five closed sizes cover compact controls through high-emphasis calls to action."
        ) do
          example(
            "Size scale",
            slug: "button-size-scale",
            mode: :full_width,
            layout: :matrix,
            density: :compact
          ) do
            Gallery::Data.button_sizes.each do |button|
              sample(button.label, slug: button.slug) do
                render_button(button, id: "gallery-button-size-#{button.slug}")
              end
            end
          end
        end

        example_section(
          "Content modes",
          slug: "button-content",
          description: "Text, leading and trailing icons, icon-only controls, links, and block labels stay explicit."
        ) do
          example("Content combinations", slug: "button-content-combinations", layout: :matrix) do
            sample("Leading icon", slug: "leading-icon") do
              render NitroKit::Button.new(
                "Save report",
                id: "gallery-button-leading-icon",
                icon: :save,
                variant: :primary
              )
            end
            sample("Trailing icon", slug: "trailing-icon") do
              render NitroKit::Button.new(
                "Continue",
                id: "gallery-button-trailing-icon",
                icon_right: :arrow_right
              )
            end
            sample("Icon only", slug: "icon-only") do
              render NitroKit::Button.new(
                id: "gallery-button-icon-only",
                icon: :x,
                variant: :ghost,
                aria: { label: "Close notification" }
              )
            end
            sample("Link", slug: "link") do
              render NitroKit::Button.new(
                "Read documentation",
                id: "gallery-button-link",
                href: "#button-documentation",
                icon_right: :arrow_right
              )
            end
            sample("Block label", slug: "block-label") do
              render NitroKit::Button.new(id: "gallery-button-block-label") do
                "Label supplied by a Phlex block"
              end
            end
            sample("Long label", slug: "long-label") do
              render NitroKit::Button.new(
                "Download the complete workspace activity archive",
                id: "gallery-button-long-label",
                icon: :download
              )
            end
          end
        end

        example_section(
          "Native states",
          slug: "button-states",
          description: "Disabled controls retain visible state while links lose navigation and expose ARIA disabled."
        ) do
          example("Enabled and disabled", slug: "button-enabled-disabled", layout: :row) do
            render NitroKit::Button.new(
              "Submit invoice",
              id: "gallery-button-submit",
              type: :submit,
              variant: :primary
            )
            render NitroKit::Button.new(
              "Delete workspace",
              id: "gallery-button-disabled",
              variant: :destructive,
              disabled: true
            )
            render NitroKit::Button.new(
              "Available link",
              id: "gallery-button-link-enabled",
              href: "#button-enabled"
            )
            render NitroKit::Button.new(
              "Unavailable link",
              id: "gallery-button-link-disabled",
              href: "#button-disabled",
              disabled: true
            )
          end
        end
      end

      def render_button(button, id:)
        render NitroKit::Button.new(
          button.label,
          id:,
          variant: button.variant,
          size: button.size,
          icon: button.icon,
          disabled: button.disabled
        )
      end
    end
  end
end
