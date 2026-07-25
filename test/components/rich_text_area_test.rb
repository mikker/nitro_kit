require "test_helper"

class RichTextAreaTest < ActiveSupport::TestCase
  test "wraps trusted editor markup in the Nitro contract" do
    content = ActiveSupport::SafeBuffer.new("<lexxy-editor input=\"project_brief\"></lexxy-editor>")
    node = Nokogiri::HTML.fragment(NitroKit::RichTextArea.new(content).call).first_element_child

    assert_equal "rich-text-area", node["data-nk"]
    assert_equal "project_brief", node.at_css("lexxy-editor")["input"]
    assert_empty node.css("[class], [style]")
  end

  test "requires captured editor content" do
    assert_raises(ArgumentError) { NitroKit::RichTextArea.new(nil) }
  end
end
