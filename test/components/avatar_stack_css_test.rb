require "test_helper"

class AvatarStackCssTest < ActiveSupport::TestCase
  test "stacked items paint their fill over an opaque surface underlay" do
    rule = <<~CSS.strip
      :where(
            [data-nk="avatar-stack"] > [data-slot="avatar-stack-avatar"],
            [data-nk="avatar-stack"] > [data-slot="avatar-stack-overflow"]
          ) {
          --_nk-avatar-stack-fill: var(--nk-color-muted);

          flex: none;
          margin-inline-start: var(--_nk-avatar-stack-overlap);
          background-color: var(--nk-color-surface);
          background-image: linear-gradient(
            var(--_nk-avatar-stack-fill),
            var(--_nk-avatar-stack-fill)
          );
    CSS

    assert_includes source_css, rule
  end

  test "the overflow indicator declares a fill instead of its own background" do
    rule = ':where([data-nk="avatar-stack"] > [data-slot="avatar-stack-overflow"])'

    assert_match(
      /#{Regexp.escape(rule)}\s*\{[^}]*--_nk-avatar-stack-fill: var\(--nk-color-elevated\);/,
      source_css
    )
    refute_match(/#{Regexp.escape(rule)}\s*\{[^}]*background-color:/, source_css)
  end

  private

  def source_css
    @source_css ||= Rails.root.join(
      "../../src/stylesheets/nitro_kit/components/avatar_stack.css"
    ).read
  end
end
