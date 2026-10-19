require "test_helper"

class ComboboxCssTest < ActiveSupport::TestCase
  test "active and selected option descriptions keep readable contrast" do
    selector = <<~CSS.strip
      [data-nk="combobox"]
              > [data-slot="combobox-listbox"]
              > [data-slot="combobox-option"]:is(
                [data-active="true"],
                [aria-selected="true"]
              )
              > [data-slot="combobox-option-description"]
    CSS

    assert_includes source_css, selector
  end

  test "remote chips truncate inside the field and empty lists collapse" do
    css = compact(source_css)

    assert_includes css, ':where([data-nk="combobox"] > [data-slot="combobox-selections"]:empty) { display: none; }'
    assert_match(
      /\[data-slot="combobox-selection"\] > \[data-slot="combobox-selection-label"\] \) \{ min-inline-size: 0; overflow: hidden; white-space: nowrap; text-overflow: ellipsis; \}/,
      css
    )
    assert_match(/\[data-slot="combobox-selection"\] \) \{[^}]*max-inline-size: 100%;/, css)
  end

  test "remote feedback and actions are styled through owned state" do
    css = compact(source_css)

    assert_includes css, '> [data-slot="combobox-message"][data-state="error"] ) { color: var(--nk-color-destructive); }'
    assert_includes css, '> [data-slot="combobox-action"][aria-busy="true"] ) { cursor: progress;'
    refute_match(/transition:\s*all/, css)
  end

  private

  def compact(css)
    css.gsub(/\s+/, " ").gsub("( ", "(")
  end

  def source_css
    @source_css ||= Rails.root.join(
      "../../src/stylesheets/nitro_kit/components/combobox.css"
    ).read
  end
end
