module Gallery
  module Components
    class ProgressiveImagePage < ComponentPage
      class DemoBlob
        def initialize(width: 1_200, height: 800, analyzed: true)
          @metadata = { "width" => width, "height" => height }.freeze
          @analyzed = analyzed
        end

        attr_reader :metadata

        def analyzed? = @analyzed
        def image? = true
        def variable? = true
      end

      class DemoAttachment
        def initialize(path:, attached: true, blob: DemoBlob.new)
          @path = path
          @attached = attached
          @blob = blob
        end

        attr_reader :blob

        def attached? = @attached
        def filename = "workspace-illustration.svg"

        def variant(resize_to_limit:)
          width, height = resize_to_limit
          "#{@path}?variant=#{width}x#{height}"
        end
      end

      Summary = ::Data.define(:title, :owner, :status, :updated_on)
      SUMMARY = Summary.new(
        title: "Mothership workspace",
        owner: "Ada Lovelace",
        status: :active,
        updated_on: Date.new(2026, 7, 13)
      )

      private

      def source_note
        "app/components/nitro_kit/progressive_image.rb"
      end

      def api_note
        "NitroKit::ProgressiveImage.new(attachment:, alt:, size: :md, decorative: false)"
      end

      def component_template
        example_section(
          "Progressive loading",
          slug: "progressive-image-loading",
          description: "A decorative low-resolution variant covers the full image until browser decoding succeeds."
        ) do
          example("Workspace illustration", slug: "progressive-image-workspace", mode: :full_width) do
            render NitroKit::ProgressiveImage.new(
              attachment: image_attachment,
              alt: "Abstract indigo workspace illustration",
              size: :lg,
              id: "gallery-progressive-image-loaded"
            )
          end
        end

        example_section(
          "Resolution sizes",
          slug: "progressive-image-sizes",
          description: "Closed sizes request predictable one- and two-density Active Storage variants without accepting arbitrary processing options."
        ) do
          example("Variant scale", slug: "progressive-image-size-scale", layout: :matrix) do
            NitroKit::ProgressiveImage::SIZES.each do |size|
              sample(size.to_s.upcase, slug: size) do
                render NitroKit::ProgressiveImage.new(
                  attachment: image_attachment,
                  alt: "Abstract indigo workspace illustration",
                  size:,
                  id: "gallery-progressive-image-#{size}"
                )
              end
            end
          end
        end

        example_section(
          "Missing and broken media",
          slug: "progressive-image-fallbacks",
          description: "Empty markup is complete on the server; failed loads reveal the fallback while preserving informative alt text."
        ) do
          example("Fallback states", slug: "progressive-image-fallback-states", layout: :matrix) do
            sample("Empty attachment", slug: "empty") do
              render NitroKit::ProgressiveImage.new(
                attachment: nil,
                alt: "Workspace cover",
                size: :sm,
                id: "gallery-progressive-image-empty"
              )
            end
            sample("Failed variant", slug: "error") do
              render NitroKit::ProgressiveImage.new(
                attachment: broken_attachment,
                alt: "Unavailable workspace cover",
                size: :sm,
                id: "gallery-progressive-image-error"
              )
            end
          end
        end

        example_section(
          "Accessibility intent",
          slug: "progressive-image-accessibility",
          description: "The placeholder never enters the accessibility tree; decorative full images also use an empty alt."
        ) do
          example("Decorative media", slug: "progressive-image-decorative") do
            render NitroKit::ProgressiveImage.new(
              attachment: image_attachment,
              alt: nil,
              decorative: true,
              size: :md,
              id: "gallery-progressive-image-decorative"
            )
          end
        end

        example_section(
          "Record composition",
          slug: "progressive-image-composition",
          description: "Progressive media, a card, status, and record details compose without utility classes or helper registration."
        ) do
          example("Workspace overview", slug: "progressive-image-workspace-card", mode: :full_width) do
            render NitroKit::Card.new(id: "gallery-progressive-image-card") do |card|
              card.full do
                render NitroKit::ProgressiveImage.new(
                  attachment: image_attachment,
                  alt: "Abstract indigo workspace illustration",
                  size: :lg,
                  id: "gallery-progressive-image-card-media"
                )
              end
              card.title(SUMMARY.title, level: 3)
              card.body do
                render NitroKit::DetailsTable.new(SUMMARY, id: "gallery-progressive-image-card-details") do |details|
                  details.field(:owner)
                  details.field(:status) do |status|
                    render NitroKit::Badge.new(
                      status.to_s.humanize,
                      id: "gallery-progressive-image-card-status",
                      color: :success,
                      size: :sm
                    )
                  end
                  details.field(:updated_on)
                end
              end
            end
          end
        end
      end

      def image_attachment
        DemoAttachment.new(path: "/gallery/progressive-workspace.svg")
      end

      def broken_attachment
        DemoAttachment.new(path: "/gallery/not-an-image.txt")
      end
    end
  end
end
