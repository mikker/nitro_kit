require "test_helper"

class ComboboxRemoteTest < ActionDispatch::IntegrationTest
  test "the search endpoint renders Combobox::Results with a create action for unknown queries" do
    get gallery_combobox_labels_path(combobox: "picker", query: "perf")

    assert_response :success
    assert_select "ul#picker-results[data-nk='combobox-results']" do
      assert_select "> [data-slot='combobox-option']", count: 1
      assert_select "#picker-result-1[data-value='7']", text: /Performance/
      assert_select "> [data-slot='combobox-action']:last-child", text: "Create label “perf”"
    end

    get gallery_combobox_labels_path(combobox: "picker", query: "performance")
    assert_select "[data-slot='combobox-action']", count: 0

    get gallery_combobox_labels_path(combobox: "picker", query: "Unlisted label")
    assert_select "[data-slot='combobox-option']", count: 0
    assert_select "[data-slot='combobox-action'][data-request-url='#{gallery_combobox_labels_path(combobox: "picker")}']",
      text: "Create label “Unlisted label”"

    get gallery_combobox_labels_path(unavailable: 1)
    assert_response :service_unavailable
  end

  test "creating a label answers with the one option to select" do
    name = "Created #{SecureRandom.hex(3)}"
    post gallery_combobox_labels_path(combobox: "picker"), params: { label: { name: } }

    assert_response :created
    assert_select "[data-nk='combobox-results'] > [data-slot='combobox-option']", count: 1, text: name

    post gallery_combobox_labels_path, params: { label: { name: " " } }
    assert_response :unprocessable_entity
  end

  test "an invalid release re-renders every submitted selection and drops deleted ids" do
    post gallery_combobox_release_path, params: { release: { title: "", label_ids: [ "", "1", "999999", "7" ] } }

    assert_response :unprocessable_entity
    assert_select "turbo-frame#gallery-combobox-release-frame" do
      assert_select "#gallery-combobox-release-labels [data-slot='combobox-selections'] > [data-slot='combobox-selection']",
        count: 2
      assert_select "[data-slot='combobox-selections'] input[name='release[label_ids][]'][value='1']"
      assert_select "[data-slot='combobox-selections'] input[name='release[label_ids][]'][value='7']"
      assert_select "input[name='release[label_ids][]'][value='999999']", count: 0
      assert_select "[data-slot='field-error']", text: "Title can't be blank"
    end

    post gallery_combobox_release_path, params: { release: { title: "Spring", label_ids: [ "", "1" ] } }
    assert_response :success
    assert_select "[data-nk='alert']", text: /Labels: Bug/
  end
end
