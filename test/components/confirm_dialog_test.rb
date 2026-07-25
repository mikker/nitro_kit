require "test_helper"

class ConfirmDialogTest < ActiveSupport::TestCase
  test "renders the global Turbo confirmation interface" do
    node = Nokogiri::HTML.fragment(NitroKit::ConfirmDialog.new.call).first_element_child
    panel = node.at_css("dialog")
    buttons = panel.css("[data-nk='button']")

    assert_equal "confirm-dialog", node["id"]
    assert_equal "dialog", node["data-nk"]
    assert_includes node["data-controller"].split, "nk--dialog"
    assert_includes node["data-controller"].split, "nk--confirm-dialog"
    assert_includes node["data-action"].split, "nitro-kit:confirm@document->nk--confirm-dialog#open"
    assert_equal "none", panel["closedby"]
    assert_equal "confirm-dialog-message", panel["aria-describedby"]
    assert_equal "panel", panel["data-nk--confirm-dialog-target"]
    assert_equal "message", panel.at_css("p")["data-nk--confirm-dialog-target"]
    assert_equal %w[Cancel Confirm], buttons.map(&:text)
    assert_equal %w[default destructive], buttons.map { _1["data-variant"] }
    assert_empty node.css("[class], [style]")
  end

  test "supports application copy and additive root data" do
    node = Nokogiri::HTML.fragment(
      NitroKit::ConfirmDialog.new(
        id: "approval",
        title: "Approve request",
        cancel_label: "Not yet",
        confirm_label: "Approve",
        data: {
          controller: "analytics",
          action: "click->analytics#track"
        }
      ).call
    ).first_element_child

    assert_equal "approval", node["id"]
    assert_equal %w[nk--dialog nk--confirm-dialog analytics], node["data-controller"].split
    assert_equal(
      %w[nitro-kit:confirm@document->nk--confirm-dialog#open click->analytics#track],
      node["data-action"].split
    )
    assert_equal "Approve request", node.at_css("[data-slot='dialog-title']").text
    assert_equal [ "Not yet", "Approve" ], node.css("[data-nk='button']").map(&:text)
  end

  test "rejects blank interface copy" do
    %i[title cancel_label confirm_label].each do |attribute|
      error = assert_raises(ArgumentError) do
        NitroKit::ConfirmDialog.new(**{ attribute => " " })
      end

      assert_includes error.message, attribute.to_s
    end
  end

  test "packages its controller and styles" do
    root = NitroKit::Engine.root
    bootstrap = root.join("app/javascript/nitro_kit.js").read
    controller = root.join("app/javascript/controllers/nk/confirm_dialog_controller.js").read
    source = root.join("src/stylesheets/nitro_kit/components/confirm_dialog.css").read

    assert_includes bootstrap, "export const NitroKit"
    assert_includes bootstrap, "start()"
    assert_includes bootstrap, "Turbo.config.forms.confirm = confirm"
    assert_includes bootstrap, 'const confirmEvent = "nitro-kit:confirm"'
    assert_includes bootstrap, 'const confirmReadyEvent = "nitro-kit:confirm-ready"'
    assert_includes bootstrap, "document.querySelector(confirmDialogSelector)"
    assert_includes bootstrap, "window.setTimeout(handleReady, 1_000)"
    assert_includes controller, 'document.dispatchEvent(new CustomEvent("nitro-kit:confirm-ready"))'
    assert_includes controller, "event.preventDefault()"
    refute_includes controller, "Turbo.config.forms.confirm"
    assert_includes controller, "this.resolve(false)"
    assert_includes controller, "this.panelTarget.showModal()"
    assert_includes source, '[data-controller~="nk--confirm-dialog"]'
  end
end
