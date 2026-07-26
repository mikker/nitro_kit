require "test_helper"

class DetailsTableTest < ActiveSupport::TestCase
  Profile = Data.define(:name, :nickname, :active, :joined_on, :score, :website, :roles)
  MediaRecord = Data.define(:photo)

  class ImageBlob
    def metadata = { "width" => 1_200, "height" => 800 }
    def analyzed? = true
    def image? = true
    def variable? = true
  end

  class ImageAttachment
    def blob = @blob ||= ImageBlob.new
    def filename = "workspace.jpg"

    def variant(resize_to_limit:)
      "/workspace-#{resize_to_limit.join('x')}.jpg"
    end
  end

  class AttachmentRecord
    def attachment_changes = {}
    def photo_attachment = @photo_attachment ||= ImageAttachment.new
  end

  def setup
    @profile = Profile.new(
      name: "Ada Lovelace",
      nickname: nil,
      active: true,
      joined_on: Date.new(2026, 7, 13),
      score: 42,
      website: "https://example.test/ada",
      roles: [ "Owner", "Reviewer" ]
    )
  end

  test "composes Table with resolved fields and qualified value slots" do
    node = render_node(NitroKit::DetailsTable.new(@profile, id: "profile")) do |details|
      details.fields(:name, :nickname, :active, :joined_on, :score, :website, :roles)
    end

    assert_equal "profile", node["id"]
    assert_equal "details-table", node["data-nk"]
    assert node.at_css("[data-nk='table'][data-slot='details-table-table']")
    assert_equal 7, node.css("[data-slot='table-row']").size
    assert_equal "Not provided", node.at_css("[data-slot='details-table-empty']").text
    assert_equal "42", node.at_css("[data-slot='details-table-number']").text
    assert_equal "2026-07-13", node.at_css("[data-slot='details-table-time']")["datetime"]
    assert_equal "Yes", node.at_css("[data-slot='details-table-boolean']").text.strip
    assert_equal "Owner, Reviewer", node.at_css("[data-slot='details-table-list']").text

    link = node.at_css("[data-slot='details-table-link']")
    assert_equal "https://example.test/ada", link["href"]
    assert_equal "_blank", link["target"]
    assert_equal "noopener noreferrer", link["rel"]
    assert_empty node.css("[class], [style]")
  end

  test "distinguishes omitted values from explicit nil and lets blocks own output" do
    node = render_node(NitroKit::DetailsTable.new(@profile)) do |details|
      details.field(:name, label: "Display name") { |value| value.upcase }
      details.field(:score, label: "Override", value: nil) do |value|
        value.nil? ? "Intentionally empty" : "Unexpected"
      end
    end

    rows = node.css("[data-slot='table-row']")
    assert_equal "Display name", rows.first.at_css("th").text
    assert_equal "ADA LOVELACE", rows.first.at_css("td").text
    assert_equal "Intentionally empty", rows.last.at_css("td").text
    assert_nil rows.last.at_css("[data-slot='details-table-empty']")
  end

  test "escapes automatic and explicit field content" do
    hostile = Profile.new(
      name: "<script>alert('automatic')</script>",
      nickname: nil,
      active: false,
      joined_on: Date.new(2026, 7, 13),
      score: 0,
      website: "plain text",
      roles: []
    )

    node = render_node(NitroKit::DetailsTable.new(hostile)) do |details|
      details.field(:name)
      details.field(:nickname, value: ActiveSupport::SafeBuffer.new("<strong>explicit</strong>"))
    end

    assert_empty node.css("script, strong")
    assert_includes node.text, "<script>alert('automatic')</script>"
    assert_includes node.text, "<strong>explicit</strong>"
  end

  test "keeps shared root attributes explicit" do
    node = render_node(
      NitroKit::DetailsTable.new(
        @profile,
        id: "details",
        html: { title: "Profile details" },
        aria: { label: "Account facts" },
        data: { tracking_id: "details-1" },
        desperately_need_a_class: "external-details"
      )
    ) { |details| details.field(:name) }

    assert_equal "details", node["id"]
    assert_equal "Profile details", node["title"]
    assert_equal "Account facts", node["aria-label"]
    assert_equal "details-1", node["data-tracking-id"]
    assert_equal "external-details", node["class"]
    assert_equal "class", node["data-nk-escape"]
    assert_empty node.css("[style]")
  end

  test "renders an Active Storage image value through ProgressiveImage" do
    photo = ActiveStorage::Attached::One.new("photo", AttachmentRecord.new)
    record = MediaRecord.new(photo:)
    node = render_node(NitroKit::DetailsTable.new(record)) do |details|
      details.field(:photo)
    end

    image = node.at_css("[data-nk='progressive-image'][data-slot='details-table-attachment']")
    assert image
    assert_equal "workspace.jpg", image.at_css("[data-slot='progressive-image-image']")["alt"]
    assert_equal "/workspace-320x320.jpg", image.at_css("[data-slot='progressive-image-image']")["src"]
  end

  test "names the table with a caption or an ARIA label" do
    captioned = render_node(NitroKit::DetailsTable.new(@profile, caption: "Profile")) do |details|
      details.field(:name)
    end
    labelled = render_node(NitroKit::DetailsTable.new(@profile, label: "Profile facts")) do |details|
      details.field(:name)
    end

    assert_equal "Profile", captioned.at_css("[data-slot='table-caption']").text
    assert_equal "Profile facts", labelled.at_css("[data-slot='table-element']")["aria-label"]
    assert_raises(ArgumentError) { NitroKit::DetailsTable.new(@profile, caption: " ") }
    assert_raises(ArgumentError) { NitroKit::DetailsTable.new(@profile, label: " ") }
  end

  test "puts empty and boolean copy behind keywords" do
    node = render_node(
      NitroKit::DetailsTable.new(
        @profile,
        empty_text: "Ikke oplyst",
        boolean_labels: { true => "Ja", false => "Nej" }
      )
    ) { |details| details.fields(:nickname, :active) }

    assert_equal "Ikke oplyst", node.at_css("[data-slot='details-table-empty']").text
    assert_equal "Ja", node.at_css("[data-slot='details-table-boolean']").text.strip
    assert_raises(ArgumentError) { NitroKit::DetailsTable.new(@profile, empty_text: " ") }
    assert_raises(ArgumentError) { NitroKit::DetailsTable.new(@profile, boolean_labels: { true => "Ja" }) }
    assert_raises(ArgumentError) do
      NitroKit::DetailsTable.new(@profile, boolean_labels: { true => "Ja", false => "" })
    end
  end

  test "rejects duplicate field keys" do
    assert_raises(ArgumentError) do
      NitroKit::DetailsTable.new(@profile).call do |details|
        details.field(:name)
        details.field("name", label: "Again")
      end
    end
    assert_raises(ArgumentError) do
      NitroKit::DetailsTable.new(@profile).call { |details| details.fields(:name, :name) }
    end
  end

  test "keeps UNSET private" do
    assert_raises(NameError) { NitroKit::DetailsTable::UNSET }
  end

  test "validates cardinality fields labels and missing attributes" do
    assert_raises(ArgumentError) { NitroKit::DetailsTable.new(@profile).call }
    assert_raises(ArgumentError) do
      NitroKit::DetailsTable.new(@profile).call { |details| details.fields }
    end
    assert_raises(ArgumentError) do
      NitroKit::DetailsTable.new(@profile).call { |details| details.field("") }
    end
    assert_raises(ArgumentError) do
      NitroKit::DetailsTable.new(@profile).call { |details| details.field(:name, label: " ") }
    end
    assert_raises(ArgumentError) do
      NitroKit::DetailsTable.new(@profile).call { |details| details.field(:missing) }
    end
    assert_raises(ArgumentError) do
      NitroKit::DetailsTable.new(@profile, class: "utility")
    end
  end

  private

  def render_node(component, &block)
    Nokogiri::HTML.fragment(component.call(&block)).first_element_child
  end
end
