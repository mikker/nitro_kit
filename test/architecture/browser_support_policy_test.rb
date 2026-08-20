require "test_helper"

class BrowserSupportPolicyTest < ActiveSupport::TestCase
  ROOT = NitroKit::Engine.root
  POLICY = ROOT.join("docs/browser_support.md")
  ROUTED_DOCUMENTS = %w[
    README.md
    docs/agent_guide.md
    docs/agent_native_spec.md
    docs/component_contracts.md
    docs/customization.md
    docs/hotwire.md
    docs/rails_integration.md
    plugins/nitro-kit/skills/nitro-kit-hotwire/SKILL.md
    plugins/nitro-kit/skills/nitro-kit-rails/SKILL.md
    plugins/nitro-kit/skills/nitro-kit-ui/SKILL.md
  ].freeze
  INTERACTIVE_FAMILIES = %w[
    Accordion
    AppShell
    Appearance
    Avatar
    Combobox
    CommandPalette
    Dialog
    Dropdown
    Dropzone
    ProgressiveImage
    RichTextArea
    Sheet
    Tabs
    Toast
    Tooltip
  ].freeze

  test "publishes one dated no-JavaScript classification policy" do
    policy = POLICY.read

    %w[Full Reduced Unavailable].each { |classification| assert_includes policy, "**#{classification}**" }
    INTERACTIVE_FAMILIES.each { |family| assert_includes policy, family }
    assert_match(/server-rendered HTML response is not automatically a JavaScript-free\s+interaction/, policy)
    assert_includes policy, "Turbo transport"
    assert_includes policy, "Do not publish planned or simulated versions as verified coverage"
  end

  test "routes public and agent guidance to the canonical policy" do
    ROUTED_DOCUMENTS.each do |document|
      assert_includes ROOT.join(document).read, "browser_support.md", document
    end
  end

  test "keeps implemented compatibility claims and removes stale gaps" do
    policy = POLICY.read

    assert_includes policy, "falls back to `showModal()` or `close()`"
    assert_includes policy, "outside-pointer"
    assert_includes policy, "low-specificity fallback"
    assert_includes policy, "YYYY-Www"
    refute_match(/missing imperative fallback|controller-free Dialog/i, policy)
  end
end
