require "test_helper"
require "tmpdir"
require "nitro_kit/installation"

class InstallationTest < ActiveSupport::TestCase
  test "installs version-routed skills and preserves existing agent guidance" do
    Dir.mktmpdir do |directory|
      root = Pathname.new(directory)
      root.join("AGENTS.md").write("# Existing application guidance\n")
      installation = NitroKit::Installation.new(root)

      first = installation.install
      second = installation.install

      assert_equal :written, first.fetch("AGENTS.md")
      assert second.values.all? { _1 == :unchanged }
      assert_includes root.join("AGENTS.md").read, "# Existing application guidance"
      assert_equal 1, root.join("AGENTS.md").read.scan(NitroKit::Installation::AGENTS_START).size

      NitroKit::Installation::SKILL_ROOTS.product(NitroKit::Installation::SKILLS).each do |skill_root, skill|
        installed = root.join(skill_root, skill, "SKILL.md")
        source = NitroKit::Installation::ROOT.join("plugins/nitro-kit/skills", skill, "SKILL.md")

        assert_equal source.read, installed.read
      end
    end
  end

  test "refreshes only the managed agents block" do
    Dir.mktmpdir do |directory|
      root = Pathname.new(directory)
      root.join("AGENTS.md").write(<<~MARKDOWN)
        Before

        #{NitroKit::Installation::AGENTS_START}
        stale
        #{NitroKit::Installation::AGENTS_END}

        After
      MARKDOWN

      NitroKit::Installation.new(root).install
      contents = root.join("AGENTS.md").read

      assert_includes contents, "Before"
      assert_includes contents, "After"
      assert_includes contents, "This application uses Nitro Kit 2.x"
      refute_includes contents, "stale"
      assert_equal 1, contents.scan(NitroKit::Installation::AGENTS_START).size
    end
  end

  test "doctor separates required integration from application next steps" do
    Dir.mktmpdir do |directory|
      installation = NitroKit::Installation.new(directory)
      installation.install
      checks = installation.checks.index_by(&:label)

      assert_equal :pass, checks.fetch("Nitro Kit version").status
      assert_equal :pass, checks.fetch("AGENTS.md guidance").status
      assert_equal :pass, checks.fetch("Project-local skills").status
      assert_equal :pass, checks.fetch("Hotwire dependencies").status
      assert_equal :warn, checks.fetch("Nitro Kit stylesheet").status
      assert_equal :warn, checks.fetch("Phlex Kit base").status
      assert installation.healthy?
    end
  end

  test "doctor warns about copied Nitro Kit 1 surfaces" do
    Dir.mktmpdir do |directory|
      root = Pathname.new(directory)
      FileUtils.mkdir_p(root.join("app/javascript/controllers/nk"))
      installation = NitroKit::Installation.new(root)
      installation.install
      legacy = installation.checks.find { _1.label == "Nitro Kit 1.x shadows" }

      assert_equal :warn, legacy.status
      assert_includes legacy.detail, "app/javascript/controllers/nk"
    end
  end

  test "ships a version-specific initialization prompt" do
    prompt = NitroKit::Installation.new(Dir.pwd).prompt

    assert_includes prompt, "Nitro Kit 2"
    assert_includes prompt, "bundle show nitro_kit"
    assert_includes prompt, "nitro_kit:doctor"
    refute_includes prompt, "launch"
  end

  test "copies the initialization prompt through an available clipboard command" do
    Dir.mktmpdir do |directory|
      root = Pathname.new(directory)
      clipboard = root.join("clipboard")
      command = root.join("pbcopy")
      command.write("#!/bin/sh\ncat > #{clipboard}\n")
      command.chmod(0o755)

      previous_path = ENV["PATH"]
      ENV["PATH"] = [ directory, previous_path ].compact.join(File::PATH_SEPARATOR)
      used = NitroKit::Installation.new(root).copy_prompt

      assert_equal "pbcopy", used
      assert_equal NitroKit::Installation.new(root).prompt, clipboard.read
    ensure
      ENV["PATH"] = previous_path
    end
  end
end
