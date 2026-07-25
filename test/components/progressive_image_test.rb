require "test_helper"

class ProgressiveImageTest < ActiveSupport::TestCase
  class Blob
    def initialize(metadata:, analyzed: true, image: true)
      @metadata = metadata
      @analyzed = analyzed
      @image = image
    end

    attr_reader :metadata

    def analyzed? = @analyzed
    def image? = @image
    def variable? = @image
  end

  class Attachment
    def initialize(attached: true, base_url: "https://example.test/image", blob: nil)
      @attached = attached
      @base_url = base_url
      @blob = blob || Blob.new(metadata: { "width" => 1_200, "height" => 800 })
      @variants = []
    end

    attr_reader :blob, :variants

    def attached? = @attached
    def filename = "workspace.jpg"

    def variant(transformations)
      variants << transformations
      width, height = transformations.fetch(:resize_to_limit)
      "#{@base_url}-#{width}x#{height}.jpg"
    end
  end

  test "renders progressive variants with exactly one accessible image" do
    attachment = Attachment.new
    node = render_node(
      NitroKit::ProgressiveImage.new(
        attachment:,
        alt: "Ada at the controls",
        id: "portrait"
      )
    )

    assert_equal "portrait", node["id"]
    assert_equal "progressive-image", node["data-nk"]
    assert_equal "md", node["data-size"]
    assert_equal "loading", node["data-state"]
    assert_equal "true", node["aria-busy"]
    assert_equal "nk--progressive-image", node["data-controller"]

    placeholder = node.at_css("[data-slot='progressive-image-placeholder']")
    image = node.at_css("[data-slot='progressive-image-image']")
    fallback = node.at_css("[data-slot='progressive-image-fallback']")

    assert_equal "", placeholder["alt"]
    assert_equal "true", placeholder["aria-hidden"]
    assert_equal "https://example.test/image-48x48.jpg", placeholder["src"]
    assert_equal "Ada at the controls", image["alt"]
    assert_equal "https://example.test/image-720x720.jpg", image["src"]
    assert_equal "https://example.test/image-720x720.jpg 1x, https://example.test/image-1440x1440.jpg 2x", image["srcset"]
    assert_equal "1200", image["width"]
    assert_equal "800", image["height"]
    assert_equal "image", image["data-nk--progressive-image-target"]
    assert fallback.key?("hidden")
    assert_equal "status", fallback["role"]
    assert_nil fallback["aria-label"]
    assert_equal 1, node.css("img:not([alt=''])").size
    assert_empty node.css("[class], [style]")
  end

  test "uses strict sizes to request one and two density variants" do
    NitroKit::ProgressiveImage::PIXELS.each do |size, pixels|
      attachment = Attachment.new
      node = render_node(NitroKit::ProgressiveImage.new(attachment:, alt: "Landscape", size:))

      assert_equal size.to_s, node["data-size"]
      assert_equal [
        { resize_to_limit: [ 48, 48 ] },
        { resize_to_limit: [ pixels, pixels ] },
        { resize_to_limit: [ pixels * 2, pixels * 2 ] }
      ], attachment.variants
    end
  end

  test "renders a semantic empty state without Stimulus or image markup" do
    node = render_node(
      NitroKit::ProgressiveImage.new(attachment: nil, alt: "Workspace cover", size: :sm)
    )

    assert_equal "empty", node["data-state"]
    assert_nil node["data-controller"]
    assert_nil node["aria-busy"]
    assert_empty node.css("img")

    fallback = node.at_css("[data-slot='progressive-image-fallback']")
    refute fallback.key?("hidden")
    assert_equal "status", fallback["role"]
    assert_nil fallback["aria-label"]
    assert_equal "Image unavailable", fallback.text
  end

  test "forces decorative images and fallback content out of the accessibility tree" do
    node = render_node(
      NitroKit::ProgressiveImage.new(
        attachment: Attachment.new,
        alt: "This text is intentionally ignored",
        decorative: true
      )
    )

    assert_equal "", node.at_css("[data-slot='progressive-image-placeholder']")["alt"]
    assert_equal "true", node.at_css("[data-slot='progressive-image-placeholder']")["aria-hidden"]
    assert_equal "", node.at_css("[data-slot='progressive-image-image']")["alt"]

    fallback = node.at_css("[data-slot='progressive-image-fallback']")
    assert_equal "true", fallback["aria-hidden"]
    assert_nil fallback["role"]
    assert_nil fallback["aria-label"]
  end

  test "omits untrusted dimensions until metadata is analyzed" do
    attachment = Attachment.new(
      blob: Blob.new(metadata: { width: 1_200, height: 800 }, analyzed: false)
    )
    node = render_node(NitroKit::ProgressiveImage.new(attachment:, alt: "Landscape"))

    assert_nil node.at_css("[data-slot='progressive-image-image']")["width"]
    assert_nil node.at_css("[data-slot='progressive-image-image']")["height"]
  end

  test "keeps shared root attributes explicit" do
    node = render_node(
      NitroKit::ProgressiveImage.new(
        attachment: nil,
        alt: "Workspace cover",
        id: "cover",
        html: { title: "Workspace artwork" },
        aria: { describedby: "cover-description" },
        data: { tracking_id: "cover-1" },
        desperately_need_a_class: "external-cover"
      )
    )

    assert_equal "cover", node["id"]
    assert_equal "Workspace artwork", node["title"]
    assert_equal "cover-description", node["aria-describedby"]
    assert_equal "cover-1", node["data-tracking-id"]
    assert_equal "external-cover", node["class"]
    assert_equal "class", node["data-nk-escape"]
    assert_empty node.css("[style]")
  end

  test "validates the attachment contract sizes booleans and attached alt text" do
    assert_predicate NitroKit::ProgressiveImage::SIZES, :frozen?
    assert_predicate NitroKit::ProgressiveImage::PIXELS, :frozen?

    assert_raises(ArgumentError) do
      NitroKit::ProgressiveImage.new(attachment: Object.new, alt: "Image")
    end
    assert_raises(ArgumentError) do
      NitroKit::ProgressiveImage.new(attachment: Attachment.new, alt: "")
    end
    assert_raises(ArgumentError) do
      NitroKit::ProgressiveImage.new(
        attachment: Attachment.new(blob: Blob.new(metadata: {}, image: false)),
        alt: "Document preview"
      )
    end
    assert_raises(ArgumentError) do
      NitroKit::ProgressiveImage.new(attachment: Attachment.new, alt: 42)
    end
    assert_raises(ArgumentError) do
      NitroKit::ProgressiveImage.new(attachment: nil, alt: "Image", size: :xl)
    end
    assert_raises(ArgumentError) do
      NitroKit::ProgressiveImage.new(attachment: nil, alt: "Image", decorative: nil)
    end
    assert_raises(ArgumentError) do
      NitroKit::ProgressiveImage.new(attachment: nil, alt: "Image", class: "utility")
    end
  end

  private

  def render_node(component)
    Nokogiri::HTML.fragment(component.call).first_element_child
  end
end
