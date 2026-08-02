require "test_helper"

class DropzoneCssTest < ActiveSupport::TestCase
  STYLESHEET = NitroKit::Engine.root.join("src/stylesheets/nitro_kit/components/dropzone.css")

  test "keeps preview removal intrinsic and aligns the empty minimal status" do
    css = STYLESHEET.read

    assert_match(/dropzone-remove-control[^}]*grid-column: -2 \/ -1;[^}]*justify-self: end;/m, css)
    assert_match(/dropzone-remove-control[^}]*min-block-size: var\(--nk-control-height-md\);/m, css)
    assert_match(/data-presentation="minimal"\]\[data-state="idle"\][^}]*dropzone-status[^}]*text-align: center;/m, css)
  end
end
