require "test_helper"
require "json"
require "yaml"

class AgentGuidanceTest < ActiveSupport::TestCase
  ROOT = NitroKit::Engine.root
  PLUGIN_ROOT = ROOT.join("plugins/nitro-kit")
  PATTERNS = %w[
    destructive_action
    flash_and_toast
    inline_edit
    queryable_collection
    resource_form
  ].freeze
  SKILLS = %w[nitro-kit-hotwire nitro-kit-rails nitro-kit-ui].freeze

  test "ships version-matched agent guidance and recipes in the gem" do
    specification = Gem::Specification.load(ROOT.join("nitro_kit.gemspec").to_s)

    assert_includes specification.files, "docs/agent_guide.md"
    assert_includes specification.files, "docs/hotwire.md"
    assert_includes specification.files, "docs/initialization_prompt.md"
    assert_includes specification.files, "docs/rails_conventions.md"
    assert_includes specification.files, ".agents/plugins/marketplace.json"
    assert_includes specification.files, "plugins/nitro-kit/.codex-plugin/plugin.json"
    PATTERNS.each do |pattern|
      assert_includes specification.files, "docs/patterns/#{pattern}.md"
    end
    SKILLS.each do |skill|
      assert_includes specification.files, "plugins/nitro-kit/skills/#{skill}/SKILL.md"
    end
  end

  test "publishes one consumer plugin with Rails UI and Hotwire skills" do
    manifest = JSON.parse(PLUGIN_ROOT.join(".codex-plugin/plugin.json").read)
    marketplace = JSON.parse(ROOT.join(".agents/plugins/marketplace.json").read)
    plugin = marketplace.fetch("plugins").sole

    assert_equal "nitro-kit", manifest.fetch("name")
    assert_equal "./skills/", manifest.fetch("skills")
    assert_equal SKILLS, PLUGIN_ROOT.join("skills").children.select(&:directory?).map(&:basename).map(&:to_s).sort
    refute SKILLS.any? { |skill| skill.include?("contribut") }
    assert_equal "nitro-kit", plugin.fetch("name")
    assert_equal "./plugins/nitro-kit", plugin.dig("source", "path")
  end

  test "skills resolve the installed gem before using its contract" do
    SKILLS.each do |skill|
      instructions = PLUGIN_ROOT.join("skills", skill, "SKILL.md").read

      assert_includes instructions, "bundle show nitro_kit"
      assert_includes instructions, "docs/agent_guide.md"
      assert_includes instructions, "installed"
      assert_includes instructions, "2"
      refute_includes instructions, "TODO"
    end
  end

  test "migration guidance preserves unsupported application controls" do
    guidance = [
      ROOT.join("docs/agent_guide.md"),
      ROOT.join("docs/initialization_prompt.md"),
      PLUGIN_ROOT.join("skills/nitro-kit-rails/SKILL.md"),
      PLUGIN_ROOT.join("skills/nitro-kit-ui/SKILL.md")
    ]

    guidance.each do |path|
      instructions = path.read

      assert_match(/genuine semantic\s+and behavioral equivalent/, instructions)
      assert_match(/application-owned\s+Rails and semantic HTML/, instructions)
      assert_match(/copied\s+Nitro Kit 1\.x source/, instructions)
    end
  end

  test "Hotwire recipes preserve the shared response grammar" do
    resource_form = ROOT.join("docs/patterns/resource_form.md").read
    destructive_action = ROOT.join("docs/patterns/destructive_action.md").read
    queryable_collection = ROOT.join("docs/patterns/queryable_collection.md").read
    flash_and_toast = ROOT.join("docs/patterns/flash_and_toast.md").read

    assert_includes resource_form, "status: :unprocessable_entity"
    assert_includes resource_form, "status: :see_other"
    assert_includes destructive_action, "NitroKit::Dialog"
    assert_includes destructive_action, "data: { turbo_confirm:"
    assert_includes queryable_collection, "NitroKit::SortableTable"
    assert_includes queryable_collection, "turbo_frame_tag"
    assert_includes flash_and_toast, "NitroKit::Toast::FlashMessages"
  end

  test "agent task corpus points only to shipped references and skills" do
    tasks = YAML.safe_load_file(ROOT.join("test/agent_tasks.yml"))

    assert_equal 4, tasks.size
    tasks.each do |task|
      assert task.fetch("prompt").present?
      assert task.fetch("expectations").many?
      task.fetch("skills").each { |skill| assert_includes SKILLS, skill }
      task.fetch("references").each { |path| assert ROOT.join(path).file?, path }
    end
  end
end
