require "test_helper"

load File.expand_path("../../lib/tasks/nitro_kit_tasks.rake", __dir__) unless defined?(NitroKit::CssBundle)

class DropzoneTest < ActiveSupport::TestCase
  class MissingRoutesDropzone < NitroKit::Dropzone
    private

    def direct_upload_routes = Object.new
  end

  class BuilderProbe < Phlex::HTML
    include Phlex::Rails::Helpers::FormWith

    def view_template
      form_with(scope: :upload, url: "/uploads", builder: NitroKit::FormBuilder) do |form|
        form.dropzone(
          :files,
          id: "builder-dropzone",
          direct_upload: false,
          multiple: true,
          accept: "text/plain",
          max_files: 3,
          required: true
        )
        form.submit("Upload")
      end
    end
  end

  test "renders an accessible native input with direct upload metadata and preview anatomy" do
    node = render_dropzone(
      id: "evidence-upload",
      name: "evidence[file]",
      label: "Upload evidence",
      description: "Text files up to 1 MB.",
      accept: "text/plain",
      max_bytes: 1_048_576,
      required: true
    )

    assert_equal "dropzone", node["data-nk"]
    assert_equal "idle", node["data-state"]
    assert_equal "nk--dropzone", node["data-controller"]
    assert_equal "1", node["data-nk--dropzone-max-files-value"]
    assert_equal "1048576", node["data-nk--dropzone-max-bytes-value"]
    assert_equal "text/plain", node["data-nk--dropzone-accept-value"]
    assert_includes node["data-action"], "drop->nk--dropzone#drop"
    assert_includes node["data-action"], "submit@document->nk--dropzone#submit"
    assert_includes node["data-action"], "turbo:before-cache@document->nk--dropzone#teardown"

    message = node.at_css("label[data-slot='dropzone-message']")
    input = node.at_css("input[data-slot='dropzone-input']")
    assert_equal "evidence-upload-input", message["for"]
    assert_equal "Upload evidence", node.at_css("#evidence-upload-title").text
    assert_equal "evidence-upload-input", input["id"]
    assert_equal "evidence[file]", input["name"]
    assert_equal "text/plain", input["accept"]
    assert input.key?("required")
    assert_equal "/rails/active_storage/direct_uploads", input["data-direct-upload-url"]
    assert_nil input["aria-labelledby"]
    assert_equal "evidence-upload-status evidence-upload-error", input["aria-describedby"]
    assert_equal "evidence-upload-error", input["aria-errormessage"]

    assert_equal "status", node.at_css("[data-slot='dropzone-status']")["role"]
    assert_equal "alert", node.at_css("[data-slot='dropzone-error']")["role"]
    assert node.at_css("[data-slot='dropzone-error']").key?("hidden")
    assert node.at_css("[data-slot='dropzone-preview-list']").key?("hidden")
    assert node.at_css("template [data-slot='dropzone-progress']")
    assert_equal "button", node.at_css("template [data-slot='dropzone-remove-control']").name
    assert_empty node.css("[class], [style], [data-nk-escape]")
  end

  test "translates its own copy and hands the controller every runtime string" do
    node = render_dropzone(id: "evidence-upload", name: "evidence[file]")

    assert_equal I18n.t("nitro_kit.dropzone.label"), node.at_css("#evidence-upload-title").text
    assert_equal(
      I18n.t("nitro_kit.dropzone.prompt"),
      node.at_css("[data-slot='dropzone-instruction']").text
    )
    assert_equal(
      I18n.t("nitro_kit.dropzone.compact_prompt"),
      node.at_css("[data-slot='dropzone-compact-instruction']").text
    )
    assert_equal(
      I18n.t("nitro_kit.dropzone.status.empty"),
      node.at_css("[data-slot='dropzone-status']").text
    )
    assert_equal(
      I18n.t("nitro_kit.dropzone.preview_list"),
      node.at_css("[data-slot='dropzone-preview-list']")["aria-label"]
    )
    assert_equal(
      I18n.t("nitro_kit.dropzone.progress"),
      node.at_css("template [data-slot='dropzone-progress']")["aria-label"]
    )
    assert_equal(
      I18n.t("nitro_kit.dropzone.queued"),
      node.at_css("template [data-slot='dropzone-file-status']").text
    )
    assert_equal(
      I18n.t("nitro_kit.dropzone.remove"),
      node.at_css("template [data-slot='dropzone-remove-control']").text
    )

    NitroKit::Dropzone::CONTROLLER_MESSAGE_KEYS.each do |key|
      attribute = "data-nk--dropzone-#{key.tr('._', '--')}-value"

      assert_equal I18n.t("nitro_kit.dropzone.#{key}"), node[attribute], attribute
    end
  end

  test "renders ordinary multiple submission and disabled states without JavaScript requirements" do
    multiple = render_dropzone(
      id: "source-files",
      name: "upload[files][]",
      direct_upload: false,
      multiple: true,
      max_files: 4
    )
    input = multiple.at_css("input[type='file']")

    assert input.key?("multiple")
    assert_nil input["data-direct-upload-url"]
    assert_nil multiple["data-nk--dropzone-direct-upload-value"]
    assert_equal "4", multiple["data-nk--dropzone-max-files-value"]

    disabled = render_dropzone(id: "archived", name: "archive[file]", disabled: true)
    assert_equal "disabled", disabled["data-state"]
    assert_equal "true", disabled["aria-disabled"]
    assert_nil disabled["data-controller"]
    assert_nil disabled["data-action"]
    assert disabled.at_css("input[type='file']").key?("disabled")
    assert_equal(
      I18n.t("nitro_kit.dropzone.status.disabled"),
      disabled.at_css("[data-slot='dropzone-status']").text
    )
    assert_nil disabled["data-nk--dropzone-status-empty-value"]
  end

  test "validates every public option and single-file consistency" do
    invalid_options = {
      id: [ nil, "", "two words", :upload ],
      name: [ nil, "", :files ],
      label: [ nil, "", :upload ],
      description: [ "", :description ],
      accept: [ "", :text ],
      direct_upload: [ nil, :yes ],
      multiple: [ nil, :yes ],
      disabled: [ nil, :yes ],
      required: [ nil, :yes ],
      max_files: [ nil, 0, -1, 1.5 ],
      max_bytes: [ 0, -1, 1.5 ],
      presentation: [ nil, :hidden, "minimal" ]
    }

    invalid_options.each do |option, values|
      values.each do |value|
        assert_raises(ArgumentError, "Expected #{option}: #{value.inspect} to fail") do
          render_dropzone(**{ option => value })
        end
      end
    end

    assert_raises(ArgumentError) { render_dropzone(max_files: 2) }
    assert render_dropzone(max_bytes: nil)
  end

  test "raises a clear integration error when Active Storage routes are unavailable" do
    component = MissingRoutesDropzone.new(id: "upload", name: "upload[file]")
    error = assert_raises(ArgumentError) { component.call }
    assert_equal "direct_upload: true requires Active Storage routes", error.message

    assert render_dropzone(direct_upload: false)
  end

  test "composes explicit shared attributes and rejects classless boundary violations" do
    node = render_dropzone(
      html: { title: "Evidence upload" },
      aria: { label: "Upload evidence" },
      data: { controller: "analytics", action: "focusin->analytics#track" },
      desperately_need_a_class: "application-hook"
    )

    assert_equal "Evidence upload", node["title"]
    assert_equal "Upload evidence", node["aria-label"]
    assert_equal "nk--dropzone analytics", node["data-controller"]
    assert_includes node["data-action"], "focusin->analytics#track"
    assert_equal "application-hook", node["class"]
    assert_equal "class", node["data-nk-escape"]

    assert_raises(ArgumentError) { render_dropzone(html: { class: "utility" }) }
    assert_raises(ArgumentError) { render_dropzone(html: { style: "width: 1px" }) }
    assert_raises(ArgumentError) { render_dropzone(data: { state: "uploading" }) }
  end

  test "FormBuilder derives Rails names and multipart semantics" do
    html = ApplicationController.render(BuilderProbe.new, layout: false)
    form = Nokogiri::HTML.fragment(html).at_css("form")
    input = form.at_css("#builder-dropzone-input")

    assert_equal "multipart/form-data", form["enctype"]
    assert_equal "upload[files][]", input["name"]
    assert input.key?("multiple")
    assert input.key?("required")
    assert_equal "text/plain", input["accept"]
    assert_nil input["data-direct-upload-url"]
    assert_equal "submit", form.at_css("button[data-nk='button']")["type"]
    assert_empty form.css("[class], [style]")
  end

  # The minimal presentation is a purely visual choice: the native input keeps
  # its name, its label, and its place in the tab order, and only the drop
  # target is visible.
  test "the minimal presentation hides the input visually and keeps it operable" do
    node = render_dropzone(id: "avatar", name: "avatar[file]", presentation: :minimal, direct_upload: false)
    input = node.at_css("input[type='file']")

    assert_equal "minimal", node["data-presentation"]
    assert_equal "avatar-input", input["id"]
    assert_equal "avatar[file]", input["name"]
    assert_nil input["hidden"]
    assert_nil input["tabindex"]
    assert_equal "avatar-input", node.at_css("label[data-slot='dropzone-message']")["for"]

    assert_equal "minimal", render_dropzone["data-presentation"]
    assert_equal "input", render_dropzone(presentation: :input)["data-presentation"]
  end

  test "ships owner-scoped static CSS" do
    source = NitroKit::Engine.root.join("src/stylesheets/nitro_kit/components/dropzone.css").read
    css = NitroKit::CssBundle.compile
    minimal_input = ':where( [data-nk="dropzone"][data-presentation="minimal"] > [data-slot="dropzone-input"] )'

    assert_includes css, "Source: src/stylesheets/nitro_kit/components/dropzone.css"
    assert_includes source, ':where([data-nk="dropzone"])'
    assert_includes source.gsub(/\s+/, " "), minimal_input
    assert_match(/#{Regexp.escape(minimal_input)} \{ position: absolute;/, css.gsub(/\s+/, " "))
    assert_includes source, '[data-slot="dropzone-input"]:focus-visible'
    refute_match(/(?:\:where\(\s*|,\s*)\[data-slot=/m, source)
    refute_includes source, "transition: all"
  end

  private

  def render_dropzone(**attributes)
    defaults = { id: "upload", name: "upload[file]" }
    Nokogiri::HTML.fragment(NitroKit::Dropzone.new(**defaults.merge(attributes)).call).first_element_child
  end
end
