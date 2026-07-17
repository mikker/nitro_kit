require "test_helper"

class DatepickerTest < ActiveSupport::TestCase
  test "normalizes Safari's internal date field alignment" do
    reset = NitroKit::Engine.root.join(
      "src/stylesheets/nitro_kit/reset.css"
    ).read

    assert_includes reset, "::-webkit-datetime-edit-fields-wrapper"
    assert_includes reset, "::-webkit-datetime-edit-day-field"
    assert_includes reset, "::-webkit-calendar-picker-indicator"
  end

  test "renders a native date field with form semantics and no JavaScript dependency" do
    node = render_datepicker(
      id: "birthday",
      name: "user[birthday]",
      value: "2000-01-02",
      min: "1900-01-01",
      max: "2020-12-31",
      step: 1,
      required: true,
      autocomplete: "bday",
      aria: { describedby: "birthday-help" }
    )

    assert_equal "input", node.name
    assert_equal "datepicker", node["data-nk"]
    assert_equal "date", node["type"]
    assert_equal "birthday", node["id"]
    assert_equal "user[birthday]", node["name"]
    assert_equal "2000-01-02", node["value"]
    assert_equal "1900-01-01", node["min"]
    assert_equal "2020-12-31", node["max"]
    assert_equal "1", node["step"]
    assert node.key?("required")
    assert_equal "bday", node["autocomplete"]
    assert_equal "birthday-help", node["aria-describedby"]
    assert_nil node["data-controller"]
    assert_empty node.css("[class], [style]")
  end

  test "validates booleans and attribute ownership" do
    %i[disabled readonly required].each do |option|
      assert_raises(ArgumentError) { render_datepicker(**{ option => :yes }) }
    end

    assert_raises(ArgumentError) { render_datepicker(html: { class: "utility" }) }
    assert_raises(ArgumentError) { render_datepicker(html: { style: "width: 1px" }) }
    assert_raises(ArgumentError) { render_datepicker(data: { nk: "input" }) }

    node = render_datepicker(
      html: { title: "Choose a date" },
      data: { controller: "application" },
      desperately_need_a_class: "native-picker"
    )
    assert_equal "Choose a date", node["title"]
    assert_equal "application", node["data-controller"]
    assert_equal "native-picker", node["class"]
    assert_equal "class", node["data-nk-escape"]
  end

  private

  def render_datepicker(**attributes)
    Nokogiri::HTML.fragment(NitroKit::Datepicker.new(**attributes).call).first_element_child
  end
end
