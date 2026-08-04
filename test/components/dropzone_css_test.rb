require "test_helper"

class DropzoneCssTest < ActiveSupport::TestCase
  STYLESHEET = NitroKit::Engine.root.join("src/stylesheets/nitro_kit/components/dropzone.css")

  test "keeps preview removal intrinsic and adapts to its container" do
    css = STYLESHEET.read

    assert_match(/dropzone-remove-control[^}]*grid-column: -2 \/ -1;[^}]*justify-self: end;/m, css)
    assert_match(/dropzone-remove-control[^}]*min-block-size: var\(--nk-control-height-md\);/m, css)
    assert_match(/data-presentation="minimal"\]\[data-state="idle"\][^}]*dropzone-status[^}]*text-align: center;/m, css)
    assert_includes css, "container: nk-dropzone / inline-size"
    assert_includes css, "@container nk-dropzone (max-width: 24rem)"
    assert_match(/dropzone-compact-instruction[^}]*display: inline;/m, css)
    assert_match(/data-state="idle"[^}]*dropzone-status[^}]*clip-path: inset\(50%\);/m, css)
  end
end
