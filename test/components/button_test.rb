require "test_helper"

class ButtonTest < ActiveSupport::TestCase
  LabelObject = Data.define(:value) do
    def to_s = value
  end

  class AvatarButtons < Phlex::HTML
    def view_template
      render NitroKit::Button.new(size: :xs) do
        render NitroKit::Avatar.new(alt: "", fallback: "XS", size: :xs)
        plain "Extra small"
      end
      render NitroKit::Button.new(size: :md) do
        render NitroKit::Avatar.new(alt: "", fallback: "MD", size: :md)
        plain "Medium"
      end
      render NitroKit::Button.new(size: :md) do
        render NitroKit::Avatar.new(alt: "", fallback: "XS", size: :xs)
        plain "Smaller avatar"
      end
    end
  end

  test "renders every variant and size without classes" do
    assert_predicate NitroKit::Button::VARIANTS, :frozen?
    assert_predicate NitroKit::Button::SIZES, :frozen?

    NitroKit::Button::VARIANTS.product(NitroKit::Button::SIZES).each do |variant, size|
      node = render_node(NitroKit::Button.new("Save", variant:, size:))

      assert_equal "button", node["data-nk"]
      assert_equal variant.to_s, node["data-variant"]
      assert_equal size.to_s, node["data-size"]
      assert_equal "Save", node.at_css("[data-slot='button-label']").text
      assert_empty node.css("[class], [style]")
    end
  end

  test "uses the default treatment when the ordinary action omits variant" do
    node = render_node(NitroKit::Button.new("Save changes"))

    assert_equal "default", node["data-variant"]
  end

  test "keeps label and icon structure stable for text and block content" do
    text_node = render_node(NitroKit::Button.new(LabelObject.new("Object label"), icon: :save))
    block_node = render_node(NitroKit::Button.new(icon_end: :arrow_right)) { "Block label" }

    assert_equal "Object label", text_node.at_css("[data-slot='button-label']").text
    assert_equal "icon", text_node.at_css("[data-slot='button-icon-start'] svg")["data-nk"]
    assert_equal "Block label", block_node.at_css("[data-slot='button-label']").text
    assert_equal "icon", block_node.at_css("[data-slot='button-icon-end'] svg")["data-nk"]
  end

  test "composes xs and md avatars with labels while preserving declared avatar sizes" do
    nodes = Nokogiri::HTML.fragment(AvatarButtons.new.call).css("[data-nk='button']")

    assert_equal %w[xs md md], nodes.map { |node| node["data-size"] }
    assert_equal %w[xs md xs], nodes.map { |node| node.at_css("[data-nk='avatar']")["data-size"] }
    assert_equal [ "Extra small", "Medium", "Smaller avatar" ], nodes.map { |node|
      node.at_css("[data-slot='button-label']").xpath("text()").text
    }
  end

  test "renders native links and accessible disabled links" do
    enabled = render_node(NitroKit::Button.new("Read", href: "/docs"))
    disabled = render_node(NitroKit::Button.new("Read", href: "/docs", disabled: true))

    assert_equal "a", enabled.name
    assert_equal "/docs", enabled["href"]
    assert_nil disabled["href"]
    assert_equal "true", disabled["aria-disabled"]
    assert_equal "-1", disabled["tabindex"]
  end

  test "keeps link-only and button-only native options apart" do
    link = render_node(
      NitroKit::Button.new("Handbook", href: "/handbook", target: "_blank", rel: "noopener", download: "handbook.pdf")
    )
    submit = render_node(
      NitroKit::Button.new("Save", type: :submit, name: "commit", value: "save", form: "profile-form")
    )

    assert_equal "_blank", link["target"]
    assert_equal "noopener", link["rel"]
    assert_equal "handbook.pdf", link["download"]
    assert_equal "commit", submit["name"]
    assert_equal "save", submit["value"]
    assert_equal "profile-form", submit["form"]

    assert_match(/do not accept name, value, or form/, assert_raises(ArgumentError) do
      NitroKit::Button.new("Link", href: "/", name: "action")
    end.message)
    assert_match(/do not accept target, rel, or download/, assert_raises(ArgumentError) do
      NitroKit::Button.new("Button", target: "_blank")
    end.message)
  end

  test "does not allow disabled link semantics to be overridden" do
    aria_error = assert_raises(ArgumentError) do
      NitroKit::Button.new("Read", href: "/docs", disabled: true, aria: { disabled: false })
    end
    href_error = assert_raises(ArgumentError) do
      NitroKit::Button.new("Read", href: "/docs", disabled: true, html: { href: "/bypass" })
    end

    assert_match(/Duplicate ARIA attribute disabled/, aria_error.message)
    assert_match(/Duplicate HTML attribute href/, href_error.message)
  end

  test "requires accessible names for icon-only buttons" do
    error = assert_raises(ArgumentError) { NitroKit::Button.new(icon: :x).call }
    assert_match(/label/, error.message)

    aria_labelled = render_node(NitroKit::Button.new(icon: :x, aria: { label: "Close" }))
    keyword_labelled = render_node(NitroKit::Button.new(icon: :x, label: "Close"))
    referenced = render_node(NitroKit::Button.new(icon: :x, aria: { labelledby: "close-help" }))

    assert_equal "Close", aria_labelled["aria-label"]
    assert_equal "Close", keyword_labelled["aria-label"]
    assert_equal "close-help", referenced["aria-labelledby"]
    assert_nil aria_labelled.at_css("[data-slot='button-label']")
    assert_raises(ArgumentError) { NitroKit::Button.new(icon: :x, label: " ") }
    assert_raises(ArgumentError) { NitroKit::Button.new(icon: :x, label: :close) }
    assert_raises(ArgumentError) { NitroKit::Button.new(icon: :x, label: "Close", aria: { label: "Close" }) }
  end

  test "loading buttons are busy disabled and own a spinner slot" do
    node = render_node(NitroKit::Button.new("Save", icon: :save, loading: true))
    link = render_node(NitroKit::Button.new("Read", href: "/docs", loading: true))

    assert_equal "true", node["aria-busy"]
    assert node.key?("disabled")
    assert_equal "icon", node.at_css("[data-slot='button-spinner'] svg")["data-nk"]
    assert_equal "true", node.at_css("[data-slot='button-spinner']")["aria-hidden"]
    assert_nil node.at_css("[data-slot='button-icon-start']")
    assert_equal "Save", node.at_css("[data-slot='button-label']").text
    assert_predicate NitroKit::Button.new("Save", loading: true), :loading?
    refute_predicate NitroKit::Button.new("Save"), :loading?

    assert_equal "true", link["aria-busy"]
    assert_equal "true", link["aria-disabled"]
    assert_nil link["href"]

    assert_raises(ArgumentError) { NitroKit::Button.new("Save", loading: "yes") }
    assert_raises(ArgumentError) { NitroKit::Button.new("Save", loading: nil) }
  end

  test "owns Turbo submission feedback without changing the rendered label" do
    node = render_node(
      NitroKit::Button.new("Save workspace changes", type: :submit, data: { turbo_submits_with: "Saving…" })
    )
    spinner = render_node(
      NitroKit::Button.new("Save workspace changes", type: :submit, submission_indicator: :spinner)
    )

    assert_equal "nk--button", node["data-controller"]
    assert_includes node["data-action"], "submit@document->nk--button#submit"
    assert_includes node["data-action"], "turbo:submit-end@document->nk--button#reset"
    assert_equal "Saving…", node["data-turbo-submits-with"]
    assert_equal "Save workspace changes", node.at_css("[data-slot='button-label']").text
    assert_nil node.at_css("[data-slot='button-submission-spinner']")

    assert_equal "nk--button", spinner["data-controller"]
    assert_equal "true", spinner.at_css("[data-slot='button-submission-spinner']")["aria-hidden"]
    assert_equal "icon", spinner.at_css("[data-slot='button-submission-spinner'] svg")["data-nk"]
    assert_predicate NitroKit::Button::SUBMISSION_INDICATORS, :frozen?

    assert_raises(ArgumentError) do
      NitroKit::Button.new("Save", data: { turbo_submits_with: " " })
    end
    assert_raises(ArgumentError) { NitroKit::Button.new("Save", submission_indicator: :spinner) }
    assert_raises(ArgumentError) do
      NitroKit::Button.new("Save", type: :submit, submission_indicator: :dots)
    end
    assert_raises(ArgumentError) do
      NitroKit::Button.new("Save", type: :submit, submission_indicator: :spinner, loading: true)
    end
  end

  test "rejects type on link Buttons and keeps the native default otherwise" do
    assert_equal "button", render_node(NitroKit::Button.new("Save"))["type"]
    assert_equal "submit", render_node(NitroKit::Button.new("Save", type: :submit))["type"]
    assert_equal "reset", render_node(NitroKit::Button.new("Clear", type: "reset"))["type"]

    error = assert_raises(ArgumentError) { NitroKit::Button.new("Read", href: "/docs", type: :button) }
    assert_match(/do not accept type/, error.message)
  end

  test "uses Flux icon geometry for labelled and square buttons" do
    labelled = render_node(NitroKit::Button.new("Export", icon: :download))
    square = render_node(NitroKit::Button.new(icon: :ellipsis, aria: { label: "More" }))

    assert_equal "sm", labelled.at_css("[data-nk='icon']")["data-size"]
    assert_equal "md", square.at_css("[data-nk='icon']")["data-size"]
  end

  test "validates closed vocabularies and native button type" do
    assert_raises(ArgumentError) { NitroKit::Button.new("Save", variant: :loud) }
    assert_raises(ArgumentError) { NitroKit::Button.new("Save", size: :huge) }
    assert_raises(ArgumentError) { NitroKit::Button.new("Save", type: :link) }
    assert_raises(ArgumentError) { NitroKit::Button.new("Save", type: nil) }
    assert_raises(ArgumentError) { NitroKit::Button.new("Save", disabled: "false") }
    assert_raises(ArgumentError) { NitroKit::Button.new("Save", class: "utility") }
    assert_raises(ArgumentError) { NitroKit::Button.new("").call }
    assert_raises(ArgumentError) { NitroKit::Button.new("   ").call }
    assert_raises(ArgumentError) { NitroKit::Button.new("Text").call { "Block" } }
    assert_raises(ArgumentError) { NitroKit::Button.new.call }
    assert_raises(ArgumentError) { NitroKit::Button.new("Link", href: "") }
    assert_raises(ArgumentError) { NitroKit::Button.new("Link", href: :docs) }
  end

  test "composes application attributes and rejects reserved Nitro data" do
    node = render_node(
      NitroKit::Button.new(
        "Save",
        id: "save-profile",
        html: { title: "Save the profile" },
        aria: { describedby: "save-help" },
        data: {
          controller: "analytics",
          action: "click->analytics#track",
          tracking_id: "save"
        }
      )
    )

    assert_equal "save-profile", node["id"]
    assert_equal "Save the profile", node["title"]
    assert_equal "save-help", node["aria-describedby"]
    assert_equal "analytics", node["data-controller"]
    assert_equal "click->analytics#track", node["data-action"]
    assert_equal "save", node["data-tracking-id"]

    %i[nk slot variant size state].each do |reserved|
      assert_match(/reserved by Nitro Kit/, assert_raises(ArgumentError) do
        NitroKit::Button.new("Save", data: { reserved => "replacement" })
      end.message)
    end
    assert_raises(ArgumentError) { NitroKit::Button.new("Save", data: { "data-nk" => "replacement" }) }
    assert_raises(ArgumentError) { NitroKit::Button.new("Save", data: { nk_escape: "class" }) }
    assert_raises(ArgumentError) { NitroKit::Button.new("Save", html: { class: "utility" }) }
    assert_raises(ArgumentError) { NitroKit::Button.new("Save", html: { style: "display: none" }) }
    assert_raises(ArgumentError) { NitroKit::Button.new("Save", html: { data: { nk: "no" } }) }
  end

  test "emits the deliberate class escape and rejects blank values" do
    node = render_node(NitroKit::Button.new("Save", desperately_need_a_class: "external-button-hook"))

    assert_equal "external-button-hook", node["class"]
    assert_equal "class", node["data-nk-escape"]
    assert_raises(ArgumentError) { NitroKit::Button.new("Save", desperately_need_a_class: "") }
    assert_raises(ArgumentError) { NitroKit::Button.new("Save", desperately_need_a_class: "  ") }
    assert_raises(ArgumentError) { NitroKit::Button.new("Save", desperately_need_a_class: :hook) }
  end

  test "is reachable through the gallery catalog" do
    entry = Gallery::Catalog.fetch!(kind: :component, slug: "button")

    assert_equal Gallery::Components::ButtonPage, entry.page
    assert_includes entry.expected_roots, "button"
  end

  private

  def render_node(component, &block)
    Nokogiri::HTML.fragment(component.call(&block)).first_element_child
  end
end
