require "test_helper"

class ToastTest < ActiveSupport::TestCase
  test "renders explicit notifications with visible state and inspectable timer actions" do
    node = render_toast do |toast|
      toast.item(title: "Saved", description: "Your changes are live", variant: :success)
      toast.item(description: "Read this carefully", variant: :warning, dismissible: false)
      toast.item(variant: :error) { "The request failed" }
    end
    items = node.css("[data-slot='toast-item']")

    assert_equal "toast", node["data-nk"]
    assert_equal "region", node["role"]
    assert_equal "Notifications", node["aria-label"]
    assert_equal "polite", node["aria-live"]
    assert_equal "nk--toast", node["data-controller"]
    assert_includes node["data-action"], "turbo:before-cache@document->nk--toast#teardown"
    assert_equal "5000", node["data-nk--toast-duration-value"]
    assert_equal "ol", node.at_css("[data-slot='toast-list']").name

    assert_equal 3, items.size
    assert_equal %w[success warning error], items.map { |item| item["data-variant"] }
    assert items.all? { |item| item["data-nk"] == "toast-item" }
    assert items.all? { |item| item["data-state"] == "open" }
    assert items.all? { |item| item["role"].nil? }
    assert items.all? { |item| item["tabindex"].nil? }
    assert_includes items.first["data-action"], "focusin->nk--toast#pause"
    assert_includes items.first["data-action"], "focusout->nk--toast#resume"
    assert_equal "Saved", items.first.at_css("[data-slot='toast-item-title']").text
    assert_equal "p", items.first.at_css("[data-slot='toast-item-title']").name
    assert_equal "Your changes are live", items.first.at_css("[data-slot='toast-item-description']").text
    dismiss = items.first.at_css("[data-slot='toast-item-dismiss']")
    assert_equal "Dismiss notification", dismiss["aria-label"]
    assert_equal "ghost", dismiss["data-variant"]
    assert_equal "sm", dismiss["data-size"]
    assert_nil items.first["data-nk--toast-permanent"]
    assert items.first.key?("data-turbo-temporary")
    assert_nil items[1].at_css("[data-slot='toast-item-dismiss']")
    assert_equal "true", items[1]["data-nk--toast-permanent"]
    assert_nil items[1]["data-turbo-temporary"]
    assert_equal "The request failed", items[2].at_css("[data-slot='toast-item-description']").text
    assert_nil node.at_css("template")
    assert_nil node.at_css("#nk--toast-sink")
    assert_empty node.css("[class], [style]")
  end

  test "renders flash messages only from explicit flash data" do
    node = Nokogiri::HTML.fragment(
      NitroKit::Toast::FlashMessages.new(
        flash: { notice: "Welcome", alert: "Session expired", success: "Saved" },
        duration: 8_000
      ).call
    ).first_element_child

    items = node.css("[data-nk='toast-item']")
    assert_equal 3, items.size
    assert_equal %w[default error success], items.map { |item| item["data-variant"] }
    assert_equal [ "Welcome", "Session expired", "Saved" ], items.map(&:text).map(&:strip)
    assert_equal "8000", node["data-nk--toast-duration-value"]
  end

  test "supports every variant and bounded application attributes" do
    node = render_toast(
      NitroKit::Toast.new(
        label: "Updates",
        html: { title: "Recent updates" },
        data: { controller: "application" },
        desperately_need_a_class: "toast-host"
      )
    ) do |toast|
      NitroKit::Toast::Item::VARIANTS.each do |variant|
        toast.item(description: variant.to_s, variant:)
      end
    end

    assert_equal "Updates", node["aria-label"]
    assert_equal "Recent updates", node["title"]
    assert_equal "nk--toast application", node["data-controller"]
    assert_equal "toast-host", node["class"]
    assert_equal "class", node["data-nk-escape"]
    assert_equal NitroKit::Toast::Item::VARIANTS.map(&:to_s), node.css("[data-nk='toast-item']").map { |item| item["data-variant"] }
  end

  test "validates duration labels item vocabulary and declaration context" do
    [ 0, -1, 1.5, "5000", nil ].each do |duration|
      assert_raises(ArgumentError) { NitroKit::Toast.new(duration:) }
    end
    [ nil, "", :updates ].each do |label|
      assert_raises(ArgumentError) { NitroKit::Toast.new(label:) }
    end
    assert_raises(ArgumentError) { NitroKit::Toast.new(html: { class: "utility" }) }
    assert_raises(ArgumentError) { NitroKit::Toast::FlashMessages.new(flash: nil) }

    component = NitroKit::Toast.new
    assert_match(/inside the render block/, assert_raises(ArgumentError) { component.item(description: "No") }.message)

    assert_raises(ArgumentError) do
      render_toast { |toast| toast.item(description: "No", variant: :urgent) }
    end
    assert_raises(ArgumentError) do
      render_toast { |toast| toast.item(description: "No", dismissible: :yes) }
    end
    assert_raises(ArgumentError) do
      render_toast { |toast| toast.item }
    end
  end

  private

  def render_toast(component = NitroKit::Toast.new, &block)
    Nokogiri::HTML.fragment(component.call(&block)).first_element_child
  end
end
