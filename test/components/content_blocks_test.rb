require "test_helper"

load File.expand_path("../../lib/tasks/nitro_kit_tasks.rake", __dir__) unless defined?(NitroKit::CssBundle)

class ContentBlocksTest < ActiveSupport::TestCase
  class CompleteFormProbe < Phlex::HTML
    def view_template
      render NitroKit::FormSection.new(
        title: "Profile",
        description: "Update the public details shown to teammates.",
        id: "profile-section"
      ) do |section|
        section.status(NitroKit::Alert.new(variant: :success)) do |alert|
          alert.title("Profile is current")
          alert.description("No unsaved server changes remain.")
        end
        section.form do
          form(action: "/profile", method: :post, id: "profile-form") do
            render NitroKit::FieldGroup.new do
              render NitroKit::Field.new(nil, :name, label: "Name", value: "Ada")
            end
            render NitroKit::Button.new("Save profile", type: :submit, variant: :primary)
          end
        end
      end
    end
  end

  class DangerZoneProbe < Phlex::HTML
    def view_template
      render NitroKit::DangerZone.new(
        title: "Delete workspace",
        description: "Every project and API credential will be permanently removed.",
        id: "delete-workspace"
      ) do |zone|
        zone.confirmation do
          form(action: "/workspace", method: :post, id: "delete-form") do
            input(type: :hidden, name: "_method", value: "delete")
            render NitroKit::Button.new("Delete workspace", type: :submit, variant: :destructive)
          end
        end
        zone.escape NitroKit::Button.new("Keep workspace", href: "/settings", variant: :ghost)
      end
    end
  end

  test "page header owns semantic ordering and an optional typed action group" do
    node = render_node(
      NitroKit::PageHeader.new(
        title: "Workspace members",
        eyebrow: "Administration",
        description: "Manage roles and invitations.",
        id: "members-header"
      )
    ) do |header|
      header.actions(button_group("Invite teammate", variant: :primary))
    end

    assert_equal "header", node.name
    assert_equal "page-header", node["data-nk"]
    assert_equal %w[p h1 p div], node.element_children.map(&:name)
    assert_equal "Administration", node.at_css("[data-slot='page-header-eyebrow']").text
    assert_equal "Workspace members", node.at_css("h1[data-slot='page-header-title']").text
    assert_equal "Manage roles and invitations.", node.at_css("[data-slot='page-header-description']").text
    assert_equal "button-group", node.at_css("[data-slot='page-header-actions']")["data-nk"]
    assert_empty node.css("[class], [style], [data-nk-escape]")
  end

  test "page header accepts the minimal title-only cardinality and rejects invalid slots" do
    node = render_node(NitroKit::PageHeader.new(title: "Audit log"))

    assert_equal [ "h1" ], node.element_children.map(&:name)
    assert_raises(ArgumentError) { NitroKit::PageHeader.new(title: "") }
    assert_raises(ArgumentError) { NitroKit::PageHeader.new(title: "Title", description: " ") }
    assert_raises(ArgumentError) do
      render_node(NitroKit::PageHeader.new(title: "Title")) { |header| header.actions(NitroKit::Button.new("No")) }
    end
    assert_raises(ArgumentError) do
      render_node(NitroKit::PageHeader.new(title: "Title")) do |header|
        header.actions(button_group("One"))
        header.actions(button_group("Two"))
      end
    end
  end

  test "stat grid renders ordered keyed semantic records through the proven grid" do
    node = render_node(NitroKit::StatGrid.new(id: "workspace-stats")) do |stats|
      stats.stat(key: :active_projects, label: "Active projects", value: "12", detail: "Across 4 teams")
      stats.stat(key: "members", label: "Members", value: "87")
      stats.stat(key: :uptime, label: "Uptime", value: "99.99%", detail: "Past 30 days")
    end

    grid = node.element_children.find do |child|
      child["data-nk"] == "grid" &&
        child["data-slot"] == "stat-grid-grid" &&
        child["data-cols"] == "3"
    end
    assert grid
    assert_equal %w[active-projects members uptime], grid.element_children.map { |child| child["data-key"] }
    assert_equal %w[dl dl dl], grid.element_children.map(&:name)
    assert_equal %w[Active\ projects Members Uptime], grid.css("[data-slot='stat-grid-label']").map(&:text)
    assert_equal %w[12 87 99.99%], grid.css("[data-slot='stat-grid-value']").map(&:text)
    assert_equal 2, grid.css("[data-slot='stat-grid-detail']").count
    assert_empty node.css("[class], [style], [data-nk-escape]")
  end

  test "stat grid requires records unique normalized keys and non-blank copy" do
    assert_raises(ArgumentError) { render_node(NitroKit::StatGrid.new) }
    assert_raises(ArgumentError) do
      render_node(NitroKit::StatGrid.new) do |stats|
        stats.stat(key: :active_users, label: "Users", value: "10")
        stats.stat(key: "active-users", label: "Members", value: "11")
      end
    end
    assert_raises(ArgumentError) do
      NitroKit::StatGrid.new.call { |stats| stats.stat(key: :users, label: "", value: "10") }
    end
    assert_raises(ArgumentError) do
      NitroKit::StatGrid.new.call { |stats| stats.stat(key: :users, label: "Users", value: 10) }
    end
  end

  test "empty state renders zero one and two action cardinalities" do
    minimal = render_node(NitroKit::EmptyState.new(title: "Nothing here"))
    assert_equal [ "h2" ], minimal.element_children.map(&:name)

    complete = render_node(
      NitroKit::EmptyState.new(
        title: "No teammates yet",
        description: "Invite collaborators when you are ready.",
        level: 4,
        id: "empty-team"
      )
    ) do |empty|
      empty.icon NitroKit::Icon.new(:users)
      empty.action NitroKit::Button.new("Invite teammate", href: "/invite", variant: :primary)
      empty.action NitroKit::Button.new("Read access guide", href: "/guide", variant: :ghost)
    end

    assert_equal "icon", complete.at_css("[data-slot='empty-state-icon']")["data-nk"]
    assert complete.at_css("h4[data-slot='empty-state-title']")
    assert_equal 2, complete.css("[data-slot='empty-state-actions'] > [data-slot='empty-state-action'][data-nk='button']").count
    assert_empty complete.css("[class], [style], [data-nk-escape]")
  end

  test "empty state enforces typed unique bounded children" do
    assert_raises(ArgumentError) do
      render_node(NitroKit::EmptyState.new(title: "Empty")) { |empty| empty.icon NitroKit::Button.new("No") }
    end
    assert_raises(ArgumentError) do
      render_node(NitroKit::EmptyState.new(title: "Empty")) do |empty|
        empty.icon NitroKit::Icon.new(:users)
        empty.icon NitroKit::Icon.new(:circle_user)
      end
    end
    assert_raises(ArgumentError) do
      render_node(NitroKit::EmptyState.new(title: "Empty")) do |empty|
        3.times { |index| empty.action NitroKit::Button.new("Action #{index}") }
      end
    end

    repeated = NitroKit::Button.new("Repeated")
    assert_raises(ArgumentError) do
      render_node(NitroKit::EmptyState.new(title: "Empty")) do |empty|
        empty.action repeated
        empty.action repeated
      end
    end

    [ 1, 7, :three, "3" ].each do |level|
      assert_raises(ArgumentError) { NitroKit::EmptyState.new(title: "Empty", level:) }
    end
  end

  test "data section renders one typed table after its owned header and actions" do
    node = render_node(
      NitroKit::DataSection.new(
        title: "Recent invoices",
        description: "The three newest billing records.",
        id: "invoices"
      )
    ) do |section|
      section.actions(button_group("Download CSV", variant: :ghost))
      section.table(NitroKit::Table.new(id: "invoice-table")) do |table|
        table.caption("Invoices")
        table.tbody do
          table.tr do
            table.th("INV-001", scope: :row)
            table.td("$49.00", align: :right)
          end
        end
      end
    end

    assert_equal "section", node.name
    assert_equal %w[header div], node.element_children.map(&:name)
    assert_equal "button-group", node.at_css("[data-slot='data-section-actions']")["data-nk"]
    assert_equal "table", node.at_css("[data-slot='data-section-table']")["data-nk"]
    assert_equal "Invoices", node.at_css("[data-slot='table-caption']").text
    assert_empty node.css("[class], [style], [data-nk-escape]")
  end

  test "data section renders an empty state alternative and rejects ambiguous content" do
    node = render_node(NitroKit::DataSection.new(title: "Projects")) do |section|
      section.empty_state(NitroKit::EmptyState.new(title: "No projects", level: 3, id: "no-projects")) do |empty|
        empty.action NitroKit::Button.new("Create project", href: "/projects/new", variant: :primary)
      end
    end

    assert_equal "empty-state", node.at_css("[data-slot='data-section-empty-state']")["data-nk"]
    assert_raises(ArgumentError) { render_node(NitroKit::DataSection.new(title: "Missing")) }
    assert_raises(ArgumentError) do
      render_node(NitroKit::DataSection.new(title: "Wrong")) { |section| section.table(NitroKit::Alert.new) }
    end
    assert_raises(ArgumentError) do
      render_node(NitroKit::DataSection.new(title: "Ambiguous")) do |section|
        section.table(NitroKit::Table.new) { |table| table.caption("Records") }
        section.empty_state(NitroKit::EmptyState.new(title: "Empty", level: 3))
      end
    end
    assert_raises(ArgumentError) do
      render_node(NitroKit::DataSection.new(title: "Actions")) do |section|
        section.actions(button_group("One"))
        section.actions(button_group("Two"))
      end
    end
  end

  test "form section frames exactly one complete caller-owned form" do
    node = Nokogiri::HTML.fragment(CompleteFormProbe.new.call).first_element_child

    assert_equal "form-section", node["data-nk"]
    assert_equal "Profile", node.at_css("h2[data-slot='form-section-title']").text
    assert_equal "alert", node.at_css("[data-slot='form-section-status']")["data-nk"]
    assert_equal 1, node.css("[data-slot='form-section-form'] > form#profile-form").count
    assert_equal "field-group", node.at_css("#profile-form [data-nk='field-group']")["data-nk"]
    assert_equal "submit", node.at_css("#profile-form [data-nk='button']")["type"]
    assert_empty node.css("[class], [style], [data-nk-escape]")
  end

  test "form section rejects missing duplicate and blockless forms" do
    assert_raises(ArgumentError) { render_node(NitroKit::FormSection.new(title: "Profile")) }
    assert_raises(ArgumentError) do
      render_node(NitroKit::FormSection.new(title: "Profile")) { |section| section.form }
    end
    assert_raises(ArgumentError) do
      render_node(NitroKit::FormSection.new(title: "Profile")) do |section|
        section.form { "First" }
        section.form { "Second" }
      end
    end
    assert_raises(ArgumentError) do
      render_node(NitroKit::FormSection.new(title: "Profile")) do |section|
        section.status NitroKit::Button.new("Wrong")
        section.form { "Form" }
      end
    end
    assert_raises(ArgumentError) do
      render_node(NitroKit::FormSection.new(title: "Profile")) do |section|
        section.status NitroKit::Alert.new
        section.status NitroKit::Alert.new(variant: :success)
        section.form { "Form" }
      end
    end
  end

  test "danger zone separates caller confirmation from the typed safe escape" do
    node = Nokogiri::HTML.fragment(DangerZoneProbe.new.call).first_element_child

    assert_equal "danger-zone", node["data-nk"]
    assert_equal "Delete workspace", node.at_css("h2[data-slot='danger-zone-title']").text
    assert_equal 1, node.css("[data-slot='danger-zone-confirmation'] > form#delete-form").count
    assert_equal "destructive", node.at_css("#delete-form [data-nk='button']")["data-variant"]
    assert_equal "ghost", node.at_css("[data-slot='danger-zone-escape']")["data-variant"]
    assert_empty node.css("[class], [style], [data-nk-escape]")
  end

  test "danger zone requires one confirmation and one non-destructive Button escape" do
    assert_raises(ArgumentError) do
      render_node(NitroKit::DangerZone.new(title: "Delete", description: "Permanent"))
    end
    assert_raises(ArgumentError) do
      render_node(NitroKit::DangerZone.new(title: "Delete", description: "Permanent")) do |zone|
        zone.confirmation { "Confirm" }
      end
    end
    assert_raises(ArgumentError) do
      render_node(NitroKit::DangerZone.new(title: "Delete", description: "Permanent")) do |zone|
        zone.confirmation { "Confirm" }
        zone.escape NitroKit::Alert.new
      end
    end
    assert_raises(ArgumentError) do
      render_node(NitroKit::DangerZone.new(title: "Delete", description: "Permanent")) do |zone|
        zone.confirmation { "Confirm" }
        zone.escape NitroKit::Button.new("Wrong", variant: :destructive)
      end
    end
  end

  test "every block preserves shared attributes and the deliberate class escape" do
    block_factories.each_with_index do |factory, index|
      node = factory.call(
        id: "block-#{index}",
        html: { title: "Block #{index}" },
        aria: { label: "Block #{index}" },
        data: { application_state: "ready" }
      )

      assert_equal "block-#{index}", node["id"]
      assert_equal "Block #{index}", node["title"]
      assert_equal "Block #{index}", node["aria-label"]
      assert_equal "ready", node["data-application-state"]
      assert_nil node["class"]
      assert_nil node["style"]

      escaped = escaped_block(index)
      assert_equal "external-block", escaped["class"]
      assert_equal "class", escaped["data-nk-escape"]

      assert_raises(ArgumentError) { invalid_attribute_block(index, html: { class: "utility" }) }
      assert_raises(ArgumentError) { invalid_attribute_block(index, html: { style: "display: grid" }) }
      assert_raises(ArgumentError) { invalid_attribute_block(index, data: { nk: "replacement" }) }
    end
  end

  test "static owned CSS covers every block and packaging includes sources" do
    css = NitroKit::CssBundle.compile
    files = Gem::Specification.load(NitroKit::Engine.root.join("nitro_kit.gemspec").to_s).files

    block_names.each do |name|
      assert_includes css, %([data-nk="#{name}"])
      ruby_name = name.tr("-", "_")
      assert_includes files, "app/components/nitro_kit/#{ruby_name}.rb"
      assert_includes files, "src/stylesheets/nitro_kit/components/#{ruby_name}.css"
    end

    assert_includes css, "font-variant-numeric: tabular-nums"
    assert_includes css, "@media (max-width: 48rem)"
    refute_includes css, "transition: all"
  end

  private

  def button_group(text, variant: :default)
    NitroKit::ButtonGroup.new(
      buttons: [ NitroKit::Button.new(text, variant:) ],
      label: "Page actions"
    )
  end

  def render_node(component, &block)
    Nokogiri::HTML.fragment(component.call(&block)).first_element_child
  end

  def block_names
    %w[page-header stat-grid data-section form-section danger-zone empty-state]
  end

  def block_factories
    [
      ->(**attrs) { render_node(NitroKit::PageHeader.new(title: "Title", **attrs)) },
      ->(**attrs) { render_node(NitroKit::StatGrid.new(**attrs)) { |grid| grid.stat(key: :one, label: "One", value: "1") } },
      lambda do |**attrs|
        render_node(NitroKit::DataSection.new(title: "Data", **attrs)) do |section|
          section.empty_state(NitroKit::EmptyState.new(title: "Empty", level: 3))
        end
      end,
      ->(**attrs) { render_node(NitroKit::FormSection.new(title: "Form", **attrs)) { |section| section.form { "Form" } } },
      lambda do |**attrs|
        render_node(NitroKit::DangerZone.new(title: "Danger", description: "Permanent", **attrs)) do |zone|
          zone.confirmation { "Confirm" }
          zone.escape NitroKit::Button.new("Leave", variant: :ghost)
        end
      end,
      ->(**attrs) { render_node(NitroKit::EmptyState.new(title: "Empty", **attrs)) }
    ]
  end

  def escaped_block(index)
    block_factories.fetch(index).call(desperately_need_a_class: "external-block")
  end

  def invalid_attribute_block(index, **attrs)
    block_factories.fetch(index).call(**attrs)
  end
end
