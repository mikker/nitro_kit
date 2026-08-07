require "test_helper"

class ComboboxTest < ActiveSupport::TestCase
  test "renders a native named fallback and a progressively enhanced search control" do
    options = [
      NitroKit::Choice.new(label: "Denmark", value: "dk"),
      { label: "Sweden", value: "se", disabled: true },
      [ "Norway", "no" ]
    ]
    node = render_combobox(options:, value: "dk")
    label = node.at_css("[data-slot='combobox-label']")
    input = node.at_css("[data-slot='combobox-input']")
    control = node.at_css("[data-slot='combobox-control']")
    native = node.at_css("[data-slot='combobox-native']")
    select = native.at_css("select")
    listbox = node.at_css("[data-slot='combobox-listbox']")
    status = node.at_css("[data-slot='combobox-status']")
    choices = node.css("[data-slot='combobox-option']")

    assert_equal "country", node["id"]
    assert_equal "combobox", node["data-nk"]
    assert_nil node["role"]
    assert_nil node["aria-label"]
    assert_equal "closed", node["data-state"]
    assert_equal "bottom-start", node["data-placement"]
    assert_equal "nk--combobox", node["data-controller"]
    assert_nil node["data-action"]

    assert_equal(
      I18n.t("nitro_kit.combobox.invalid_selection"),
      node["data-nk--combobox-invalid-selection-value"]
    )
    assert_equal I18n.t("nitro_kit.combobox.no_results"), node["data-nk--combobox-no-results-value"]
    assert_equal I18n.t("nitro_kit.combobox.results.one"), node["data-nk--combobox-results-one-value"]
    assert_equal(
      I18n.t("nitro_kit.combobox.results.other"),
      node["data-nk--combobox-results-other-value"]
    )

    assert_equal "country-label", label["id"]
    assert_equal "country-input", label["for"]
    assert_equal "Country", label.text
    assert_equal "label", label["data-nk"]
    assert_equal "combobox-label", label["data-slot"]

    assert_equal "country-input", input["id"]
    assert_equal "combobox", input["role"]
    assert_equal "Denmark", input["value"]
    assert_nil input["name"]
    assert control.key?("hidden")
    assert_equal "country-listbox", input["aria-controls"]
    assert_equal "false", input["aria-expanded"]
    assert_equal "list", input["aria-autocomplete"]

    assert_equal "select", native["data-nk"]
    assert_equal "native", native["data-nk--combobox-target"]
    assert_equal "country-value", select["id"]
    assert_equal "registration[country]", select["name"]
    assert_equal "dk", select.at_css("option[selected]")["value"]
    assert_equal "value", select["data-nk--combobox-target"]
    refute select.key?("disabled")
    assert_empty node.css("input[type='hidden'][name]")

    assert_nil input["aria-label"]
    assert_equal "country-listbox", listbox["id"]
    assert_equal "listbox", listbox["role"]
    assert_equal "country-label", listbox["aria-labelledby"]
    assert_equal "country-label", select["aria-labelledby"]
    assert listbox.key?("hidden")
    assert_equal 3, choices.size
    assert_equal %w[dk se no], choices.map { |choice| choice["data-value"] }
    assert_equal "true", choices[0]["aria-selected"]
    assert_equal "true", choices[1]["aria-disabled"]
    assert_equal "option", choices[1]["role"]
    assert_equal "status", status["role"]
    assert_equal "polite", status["aria-live"]
    assert_equal "true", status["aria-atomic"]
    assert_equal "status", status["data-nk--combobox-target"]
    assert_empty status.text
    assert_empty node.css("[class], [style]")
  end

  test "disabled state disables both visible and submitted controls" do
    node = render_combobox(disabled: true)

    assert node.at_css("[data-slot='combobox-input']").key?("disabled")
    assert node.at_css("[data-slot='combobox-native'] select").key?("disabled")
  end

  test "renders numeric choice labels in both native and enhanced options" do
    node = render_combobox(options: [ [ 1, "one" ], { label: 2, value: "two" } ], value: "two")

    assert_equal %w[1 2], node.css("[data-slot='combobox-native'] option:not([value=''])").map(&:text)
    assert_equal %w[1 2], node.css("[data-slot='combobox-option']").map(&:text)
    assert_equal "2", node.at_css("[data-slot='combobox-input']")["value"]
  end

  test "supports every placement and root application attributes" do
    NitroKit::Combobox::PLACEMENTS.each do |placement|
      node = render_combobox(
        placement:,
        html: { title: "Choose" },
        data: { controller: "application", tracking_id: "country" },
        desperately_need_a_class: "external-combobox"
      )

      assert_equal placement.to_s.tr("_", "-"), node["data-placement"]
      assert_equal "Choose", node["title"]
      assert_equal "nk--combobox application", node["data-controller"]
      assert_equal "country", node["data-tracking-id"]
      assert_equal "external-combobox", node["class"]
      assert_equal "class", node["data-nk-escape"]
    end
  end

  test "strictly coerces choices and rejects invalid option data" do
    assert_raises(ArgumentError) { render_combobox(options: []) }
    assert_raises(ArgumentError) { render_combobox(options: [ "Denmark" ]) }
    assert_raises(ArgumentError) { render_combobox(options: [ { label: "Denmark", value: "dk", extra: true } ]) }
    assert_raises(ArgumentError) { render_combobox(options: [ [ "Denmark", "dk" ], [ "Duplicate", "dk" ] ]) }
    assert_raises(ArgumentError) { render_combobox(options: [ { label: "", value: "dk" } ]) }
    assert_raises(ArgumentError) { render_combobox(options: [ { label: "Denmark", value: nil } ]) }
  end

  test "validates identity form semantics state and selection" do
    assert_raises(ArgumentError) { NitroKit::Combobox.new }

    [ nil, "", "two words", :country ].each do |id|
      assert_raises(ArgumentError) { render_combobox(id:) }
    end
    [ nil, "", :name ].each do |name|
      assert_raises(ArgumentError) { render_combobox(name:) }
    end
    [ nil, "", :label ].each do |label|
      assert_raises(ArgumentError) { render_combobox(label:) }
    end
    assert_raises(ArgumentError) { render_combobox(value: "unknown") }
    assert_raises(ArgumentError) { render_combobox(placement: :center) }
    assert_raises(ArgumentError) { render_combobox(required: :yes) }
    assert_raises(ArgumentError) { render_combobox(disabled: :yes) }
    assert_raises(ArgumentError) { render_combobox(html: { class: "utility" }) }
    assert_raises(ArgumentError) { render_combobox(data: { state: "open" }) }
    assert_raises(ArgumentError) { render_combobox(label: false) }
    assert_raises(ArgumentError) { render_combobox(placeholder: " ") }
    assert_raises(ArgumentError) { render_combobox(include_blank: 1) }
  end

  test "an unlabelled combobox names every control through control_aria" do
    node = render_combobox(label: false, control_aria: { label: "Country" })

    assert_nil node.at_css("[data-slot='combobox-label']")
    assert_nil node["aria-label"]
    assert_equal "Country", node.at_css("[data-slot='combobox-input']")["aria-label"]
    assert_equal "Country", node.at_css("[data-slot='combobox-listbox']")["aria-label"]
    assert_equal "Country", node.at_css("[data-slot='combobox-native'] select")["aria-label"]
  end

  test "placeholder and blank option are separate intents" do
    placeholder = render_combobox(placeholder: "Search countries")
    named_blank = render_combobox(include_blank: "No country")
    without_blank = render_combobox(include_blank: false, value: "dk")

    assert_equal "Search countries", placeholder.at_css("[data-slot='combobox-input']")["placeholder"]
    assert_equal "", placeholder.at_css("[data-slot='combobox-native'] option[value='']").text
    assert_equal "No country", named_blank.at_css("[data-slot='combobox-native'] option[value='']").text
    assert_nil without_blank.at_css("[data-slot='combobox-native'] option[value='']")
  end

  test "listbox options render choice descriptions as a described secondary line" do
    node = render_combobox(
      options: [
        { label: "Denmark", value: "dk", description: "EU reverse-charge VAT" },
        [ "Sweden", "se" ]
      ]
    )
    described = node.at_css("[data-slot='combobox-option'][data-value='dk']")
    plain_option = node.at_css("[data-slot='combobox-option'][data-value='se']")

    assert_equal "Denmark", described.at_css("[data-slot='combobox-option-label']").text
    assert_equal(
      "EU reverse-charge VAT",
      described.at_css("[data-slot='combobox-option-description']").text
    )
    assert_equal "country-option-1-description", described["aria-describedby"]
    assert_equal "country-option-1-description", described.at_css("[data-slot='combobox-option-description']")["id"]
    assert_equal "Denmark", described["aria-label"]
    assert_nil plain_option.at_css("[data-slot='combobox-option-description']")
    assert_nil plain_option["aria-label"]
  end

  private

  def render_combobox(
    id: "country",
    name: "registration[country]",
    label: "Country",
    options: [ [ "Denmark", "dk" ], [ "Sweden", "se" ] ],
    **attributes
  )
    component = NitroKit::Combobox.new(id:, name:, label:, options:, **attributes)
    Nokogiri::HTML.fragment(component.call).first_element_child
  end
end
