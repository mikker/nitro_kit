require "test_helper"

class KitTest < ActiveSupport::TestCase
  class IncludedProbe < Phlex::HTML
    include NitroKit

    def view_template
      Flex(dir: :row, gap: 2) do
        Button("Save", variant: :primary)
        Badge("Ready", color: :success)
      end
    end
  end

  class ScopedProbe < Phlex::HTML
    def view_template
      NitroKit::Button("Save")
    end
  end

  test "renders components through an included kit" do
    fragment = Nokogiri::HTML.fragment(IncludedProbe.new.call)

    assert_equal "flex", fragment.at_css("[data-nk='flex']")["data-nk"]
    assert_equal "Save", fragment.at_css("[data-nk='button']").text
    assert_equal "Ready", fragment.at_css("[data-nk='badge']").text
  end

  test "renders components through the scoped kit" do
    node = Nokogiri::HTML.fragment(ScopedProbe.new.call).first_element_child

    assert_equal "button", node["data-nk"]
    assert_equal "Save", node.text
  end
end
