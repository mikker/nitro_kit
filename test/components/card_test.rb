require "test_helper"

class CardTest < ActiveSupport::TestCase
  test "renders the complete compound structure" do
    node = render_node(NitroKit::Card.new(id: "summary")) do |card|
      card.title("Account", level: 3)
      card.body { "Current plan" }
      card.divider
      card.full_width { card.body("Full bleed") }
      card.footer { "Actions" }
    end

    assert_equal "article", node.name
    assert_equal "card", node["data-nk"]
    assert_equal "summary", node["id"]
    assert_equal "h3", node.at_css("[data-slot='card-title']").name
    assert_equal "Current plan", node.at_css("[data-slot='card-body']").text
    assert node.at_css("[data-slot='card-divider']")
    assert node.at_css("[data-slot='card-full']")
    assert_equal "Actions", node.at_css("[data-slot='card-footer']").text
    assert_empty node.css("[class], [style]")
  end

  test "validates title levels and attribute boundaries" do
    assert_raises(ArgumentError) do
      NitroKit::Card.new.call { |card| card.title("Invalid", level: 7) }
    end
    assert_raises(ArgumentError) { NitroKit::Card.new(class: "utility") }
  end

  private

  def render_node(component, &block)
    Nokogiri::HTML.fragment(component.call(&block)).first_element_child
  end
end
