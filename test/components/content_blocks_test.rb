require "test_helper"

load File.expand_path("../../lib/tasks/nitro_kit_tasks.rake", __dir__) unless defined?(NitroKit::CssBundle)

class ContentBlocksTest < ActiveSupport::TestCase
  class CompleteFormProbe < Phlex::HTML
    def view_template
      render NitroKit::SettingsSection.new(
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
        zone.escape NitroKit::Button.new("Keep workspace", href: "/settings")
      end
    end
  end

  class DeferredContentProbe < Phlex::HTML
    def view_template
      div do
        render NitroKit::PageHeader.new(id: "deferred-page-header") do |header|
          header.description { plain "Manage "; strong { "every" }; plain " invitation." }
          header.title { plain "Workspace "; em { "members" } }
          header.eyebrow("Administration")
        end

        render NitroKit::DataSection.new(id: "deferred-data-section") do |section|
          section.description { plain "The "; strong { "newest" }; plain " records." }
          section.title("Recent invoices")
          section.empty_state NitroKit::EmptyState.new(title: "No invoices", level: 3)
        end

        render NitroKit::SettingsSection.new(id: "deferred-settings-section") do |section|
          section.description { plain "Update the "; em { "public" }; plain " details." }
          section.title("Profile")
          section.form { form(action: "/profile") }
        end

        render NitroKit::DangerZone.new(id: "deferred-danger-zone") do |zone|
          zone.description { plain "Every "; strong { "project" }; plain " will be removed." }
          zone.title("Delete workspace")
          zone.confirmation { plain "Confirmation" }
          zone.escape NitroKit::Button.new("Keep workspace")
        end
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

  test "page header titles follow the caller heading level" do
    default_level = render_node(NitroKit::PageHeader.new(title: "Audit log"))
    nested = render_node(NitroKit::PageHeader.new(title: "Audit log", level: 3, id: "nested-header"))

    assert_equal 1, NitroKit::PageHeader.new(title: "Audit log").level
    assert_equal "h1", default_level.at_css("[data-slot='page-header-title']").name
    assert_equal "h3", nested.at_css("[data-slot='page-header-title']").name
    assert_equal (1..6), NitroKit::PageHeader::TITLE_LEVELS

    [ 0, 7, :three, "3", nil ].each do |level|
      assert_raises(ArgumentError) { NitroKit::PageHeader.new(title: "Audit log", level:) }
    end
  end

  test "fixed-order blocks accept deferred text and rich Phlex content" do
    root = Nokogiri::HTML.fragment(DeferredContentProbe.new.call).first_element_child

    page_header = root.at_css("#deferred-page-header")
    assert_equal %w[p h1 p], page_header.element_children.map(&:name)
    assert_equal "members", page_header.at_css("[data-slot='page-header-title'] em").text
    assert_equal "every", page_header.at_css("[data-slot='page-header-description'] strong").text

    data_section = root.at_css("#deferred-data-section")
    assert_equal "newest", data_section.at_css("[data-slot='data-section-description'] strong").text

    settings_section = root.at_css("#deferred-settings-section")
    assert_equal "public", settings_section.at_css("[data-slot='settings-section-description'] em").text

    danger_zone = root.at_css("#deferred-danger-zone")
    assert_equal "project", danger_zone.at_css("[data-slot='danger-zone-description'] strong").text
  end

  test "deferred content rejects missing mixed and repeated declarations" do
    assert_raises(ArgumentError) { render_node(NitroKit::PageHeader.new) }
    assert_raises(ArgumentError) do
      render_node(NitroKit::PageHeader.new(title: "Keyword title")) { |header| header.title("Nested title") }
    end
    assert_raises(ArgumentError) do
      render_node(NitroKit::DataSection.new) do |section|
        section.title("First")
        section.title("Second")
      end
    end
    assert_raises(ArgumentError) do
      render_node(NitroKit::DataSection.new) { |section| section.title("Text") { "Block" } }
    end
    assert_raises(ArgumentError) do
      render_node(NitroKit::SettingsSection.new) { |section| section.title("") }
    end
    assert_raises(ArgumentError) do
      render_node(NitroKit::DangerZone.new) do |zone|
        zone.title("Delete")
        zone.confirmation { "Confirm" }
        zone.escape NitroKit::Button.new("Leave")
      end
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
      section.actions(button_group("Download CSV"))
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

  test "data section accepts the table family and a single Button action" do
    record = Data.define(:name).new(name: "Ada Lovelace")
    node = render_node(NitroKit::DataSection.new(title: "Profile")) do |section|
      section.actions(NitroKit::Button.new("Edit", href: "/profile/edit"))
      section.table(NitroKit::DetailsTable.new(record, id: "profile-details")) do |details|
        details.field(:name)
      end
    end

    assert_equal "button", node.at_css("[data-slot='data-section-actions']")["data-nk"]
    assert_equal "details-table", node.at_css("[data-slot='data-section-table']")["data-nk"]
    assert_equal "Ada Lovelace", node.at_css("[data-slot='table-cell']").text
    assert_raises(ArgumentError) do
      render_node(NitroKit::DataSection.new(title: "Wrong")) { |section| section.actions(NitroKit::Alert.new) }
    end
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

    assert_equal "settings-section", node["data-nk"]
    assert_equal "Profile", node.at_css("h2[data-slot='settings-section-title']").text
    assert_equal "profile-section-title", node.at_css("h2[data-slot='settings-section-title']")["id"]
    assert_equal "profile-section-title", node["aria-labelledby"]
    assert_equal "alert", node.at_css("[data-slot='settings-section-status']")["data-nk"]
    assert_equal 1, node.css("[data-slot='settings-section-form'] > form#profile-form").count
    assert_equal "field-group", node.at_css("#profile-form [data-nk='field-group']")["data-nk"]
    assert_equal "submit", node.at_css("#profile-form [data-nk='button']")["type"]
    assert_empty node.css("[class], [style], [data-nk-escape]")
  end

  test "form section rejects missing duplicate and blockless forms" do
    assert_raises(ArgumentError) { render_node(NitroKit::SettingsSection.new(title: "Profile")) }
    assert_raises(ArgumentError) do
      render_node(NitroKit::SettingsSection.new(title: "Profile")) { |section| section.form }
    end
    assert_raises(ArgumentError) do
      render_node(NitroKit::SettingsSection.new(title: "Profile")) do |section|
        section.form { "First" }
        section.form { "Second" }
      end
    end
    assert_raises(ArgumentError) do
      render_node(NitroKit::SettingsSection.new(title: "Profile")) do |section|
        section.status NitroKit::Button.new("Wrong")
        section.form { "Form" }
      end
    end
    assert_raises(ArgumentError) do
      render_node(NitroKit::SettingsSection.new(title: "Profile")) do |section|
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
    assert_equal "default", node.at_css("[data-slot='danger-zone-escape']")["data-variant"]
    assert_empty node.css("[class], [style], [data-nk-escape]")
  end

  test "danger zone requires one confirmation and an optional non-destructive Button escape" do
    assert_raises(ArgumentError) do
      render_node(NitroKit::DangerZone.new(title: "Delete", description: "Permanent"))
    end

    without_escape = render_node(NitroKit::DangerZone.new(title: "Delete", description: "Permanent")) do |zone|
      zone.confirmation { "Confirm" }
    end

    assert_equal %w[danger-zone-header danger-zone-confirmation],
      without_escape.element_children.map { |child| child["data-slot"] }
    assert_empty without_escape.css("[data-slot='danger-zone-escape']")
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
    assert_match(/at most one safe escape action/, assert_raises(ArgumentError) do
      render_node(NitroKit::DangerZone.new(title: "Delete", description: "Permanent")) do |zone|
        zone.confirmation { "Confirm" }
        zone.escape NitroKit::Button.new("Keep")
        zone.escape NitroKit::Button.new("Also keep")
      end
    end.message)
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
    assert_includes css, "@media (width < 48rem)"
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
    %w[page-header stat-grid data-section settings-section danger-zone empty-state]
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
      ->(**attrs) { render_node(NitroKit::SettingsSection.new(title: "Form", **attrs)) { |section| section.form { "Form" } } },
      lambda do |**attrs|
        render_node(NitroKit::DangerZone.new(title: "Danger", description: "Permanent", **attrs)) do |zone|
          zone.confirmation { "Confirm" }
        end
      end
    ]
  end

  def escaped_block(index)
    block_factories.fetch(index).call(desperately_need_a_class: "external-block")
  end

  def invalid_attribute_block(index, **attrs)
    block_factories.fetch(index).call(**attrs)
  end
end
