require "test_helper"

class CardCssTest < ActiveSupport::TestCase
  test "the bleeding region clips instead of the card itself" do
    root = ':where([data-nk="card"])'
    full = ':where([data-nk="card"] > [data-slot="card-full"])'

    refute_match(/#{Regexp.escape(root)}\s*\{[^}]*overflow:/, source_css)
    assert_match(/#{Regexp.escape(full)}\s*\{[^}]*overflow: hidden;/, source_css)
  end

  test "a leading full-width region takes the card's own corner radius" do
    rule = <<~CSS.strip
      :where([data-nk="card"] > [data-slot="card-full"]:first-child) {
          margin-block-start: calc(var(--_nk-card-padding) * -1);
          border-start-start-radius: calc(
            var(--nk-radius-lg) - var(--nk-border-width)
          );
          border-start-end-radius: calc(var(--nk-radius-lg) - var(--nk-border-width));
        }
    CSS

    assert_includes source_css, rule
  end

  test "full-width media drops its own corner radius" do
    rule = <<~CSS.strip
      :where(
          [data-nk="card"]
            > [data-slot="card-full"]
            :is(img, [data-nk="progressive-image"])
        ) {
          border-radius: 0;
        }
    CSS

    assert_includes source_css, rule
  end

  private

  def source_css
    @source_css ||= Rails.root.join(
      "../../src/stylesheets/nitro_kit/components/card.css"
    ).read
  end
end
