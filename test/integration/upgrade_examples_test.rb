require "test_helper"

class UpgradeExamplesTest < ActionDispatch::IntegrationTest
  test "compound migration examples keep collections and slots in executable Phlex" do
    {
      "app-navigation" => [ "app-navigation-minimal", /destinations =/, /navigation\.body/, /destinations\.each/ ],
      "dialog" => [ "dialog-narrow-action-cluster", /wrap: :nowrap/, /Dialog\.new/, /dialog\.panel/ ],
      "sheet" => [ "sheet-constructions", /prompts =/, /sheet\.panel/, /prompts\.each_with_index/ ],
      "settings-layout" => [ "settings-layout-cardinality-states", /destinations =/, /layout\.navigation/, /layout\.content/ ]
    }.each do |component, (example, *patterns)|
      get gallery_component_path(component)
      assert_response :success

      source = css_select("#example-#{example}-code [data-gallery='code-source']").sole.text
      patterns.each { |pattern| assert_match pattern, source }
    end
  end

  test "canonical dialog action cluster owns every trigger in one no-wrap parent" do
    get gallery_component_path("dialog")

    assert_response :success
    assert_select "#gallery-dialog-transcript-actions[data-nk='flex'][data-wrap='nowrap']" do
      assert_select "> [data-nk='button']", text: "Redact", count: 1
      assert_select "> a[data-nk='button']", text: "Permalink", count: 1
      assert_select "> #gallery-dialog-transcript-details[data-nk='dialog']", count: 1 do
        assert_select "> [data-slot='dialog-trigger']", text: "Details", count: 1
        assert_select "> [data-slot='dialog-panel']", count: 1 do
          assert_select "p", text: /yielded application-content slot/
        end
      end
    end
  end

  test "migration guide pairs ERB inputs with Phlex destinations for all four compounds" do
    guide = NitroKit::Engine.root.join("docs/migration_1_to_2.md").read

    %w[AppNavigation Dialog Sheet SettingsLayout].each do |component|
      section = guide[/^### #{component}\n(?<body>.*?)(?=^### |^## |\z)/m, :body]

      assert section, "missing #{component} migration section"
      assert_includes section, "```erb"
      assert_includes section, "```ruby"
    end

    assert_includes guide, "Redact"
    assert_includes guide, "Permalink"
    assert_includes guide, "wrap: :nowrap"
  end

  test "customization guide documents application composition boundaries" do
    guide = NitroKit::Engine.root.join("docs/customization.md").read

    assert_includes guide, "Composition is the default extension mechanism"
    assert_includes guide, "Do not override Nitro rendering methods"
    assert_includes guide, "application-owned"
  end
end
