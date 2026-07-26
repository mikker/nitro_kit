# frozen_string_literal: true

require "json"

module Gallery
  class CustomizePage < Phlex::HTML
    include Phlex::Rails::Helpers::Routes

    PreviewRecord = ::Data.define(:workspace, :owner, :plan, :members)
    PREVIEW_RECORD = PreviewRecord.new(
      workspace: "Northstar Studio",
      owner: "Ada Lovelace",
      plan: :team,
      members: 18
    )
    CONTROL_COPY = {
      accent: [ "Accent", "Primary actions, focus rings, and selected states." ],
      neutral: [ "Neutral", "Canvas, surfaces, borders, and text." ],
      radius: [ "Radius", "Corner treatment across controls and surfaces." ],
      density: [ "Density", "Base spacing and control heights." ],
      font: [ "Typography", "The application-wide sans-serif stack." ],
      shell: [ "Application shell", "Sidebar, topbar, or combined chrome." ]
    }.freeze

    def initialize(preset:, errors: [], nonce: nil)
      unless preset.is_a?(ThemePreset)
        raise ArgumentError, "Gallery::CustomizePage requires a Gallery::ThemePreset"
      end

      @preset = preset
      @errors = Array(errors).map(&:to_s).freeze
      @nonce = nonce
    end

    attr_reader :preset, :errors

    def view_template
      div(
        data: {
          gallery: "page",
          gallery_page: "customize",
          controller: "gallery--customizer",
          action: "popstate@window->gallery--customizer#restore",
          gallery__customizer_schema_value: JSON.generate(ThemePreset.schema)
        }
      ) do
        preview_style
        page_header
        validation_message
        preview
        controls
        exports
        copy_status
      end
    end

    private

    def preview_style
      style(
        nonce: @nonce,
        data: { gallery__customizer_target: "previewStyle" }
      ) { raw safe(preset.preview_css) }
    end

    def page_header
      header(data: { gallery: "page-header", gallery_customizer: "header" }) do
        p(data: { gallery: "eyebrow" }) { "Theme studio · preset v#{ThemePreset::VERSION}" }
        h1 { "Customize Nitro Kit" }
        p do
          "Tune documented public tokens, pressure-test them in a real application shell, then copy the deterministic CSS and Phlex composition."
        end

        render NitroKit::ButtonGroup.new(label: "Preset actions") do |group|
          group.button(
            "Reset",
            type: :button,
            icon: :rotate_ccw,
            data: { action: "gallery--customizer#reset" }
          )
          group.button(
            "Copy share link",
            type: :button,
            icon: :link,
            data: {
              action: "gallery--customizer#copy",
              copy_kind: "url"
            }
          )
        end
      end
    end

    def validation_message
      p(
        role: "alert",
        hidden: errors.empty?,
        data: {
          gallery: "customizer-errors",
          gallery__customizer_target: "errors"
        }
      ) { plain(errors.join(" ")) }
    end

    def preview
      section(
        aria: { labelledby: "customizer-preview-title" },
        data: { gallery: "customizer-preview-section" }
      ) do
        header(data: { gallery: "customizer-section-header" }) do
          div do
            p(data: { gallery: "eyebrow" }) { "Live preview" }
            h2(id: "customizer-preview-title") { "A complete workspace" }
          end
          p { "Preview appearance is isolated from the gallery's saved appearance." }
        end

        div(
          data: {
            gallery: "theme-preview",
            theme: "light",
            preview_appearance: "system",
            gallery__customizer_target: "preview"
          }
        ) do
          render_preview_shell
        end
      end
    end

    def render_preview_shell
      render NitroKit::AppShell.new(
        id: "customizer-workspace",
        layout: preset.shell,
        data: {
          gallery_customizer_shell: true,
          gallery__customizer_target: "shell"
        }
      ) do |shell|
        shell.brand do
          div(data: { gallery: "customizer-brand" }) do
            strong { "Northstar" }
            small { "Operations" }
          end
        end

        shell.navigation { render_preview_navigation }

        shell.topbar do
          render NitroKit::ButtonGroup.new(label: "Workspace utilities") do |group|
            group.button("Search", type: :button, variant: :ghost, size: :sm, icon: :search)
            group.button("Account", type: :button, variant: :ghost, size: :sm, icon: :circle_user_round)
          end
        end

        shell.main { render_preview_main }
      end
    end

    def render_preview_navigation
      render NitroKit::AppNavigation.new(label: "Primary workspace", id: "customizer-navigation") do |navigation|
        navigation.header do
          render NitroKit::Badge.new("Team plan", variant: :outline, size: :sm)
        end
        navigation.body do
          navigation.section(label: "Workspace") do
            navigation.item("Overview", href: "#customizer-overview", icon: :house, current: true)
            navigation.item("Projects", href: "#customizer-projects", icon: :folder, badge: 12)
            navigation.item("People", href: "#customizer-people", icon: :users)
          end
          navigation.section(label: "Operations") do
            navigation.item("Deployments", href: "#customizer-deployments", icon: :rocket, badge: 4)
            navigation.item("Audit log", href: "#customizer-audit", icon: :scroll_text)
          end
          navigation.spacer
          navigation.divider
          navigation.item("Settings", href: "#customizer-settings", icon: :settings)
        end
        navigation.footer do
          render NitroKit::Button.new("Help", href: "#customizer-help", variant: :ghost, size: :sm, icon: :circle_help)
        end
      end
    end

    def render_preview_main
      div(data: { gallery: "customizer-application" }) do
        render NitroKit::Container.new(size: :xl) do
          render NitroKit::Flex.new(dir: :col, gap: 6, align: :stretch) do
            render_preview_heading
            render_preview_stats
            render_preview_workspace
            render_former_pro_components
          end
        end
      end
    end

    def render_preview_heading
      render NitroKit::PageHeader.new(
        title: "Workspace overview",
        eyebrow: "Monday, July 13",
        description: "Review activity, invite a teammate, and keep production moving."
      ) do |header|
        header.actions NitroKit::ButtonGroup.new(label: "Workspace actions") do |group|
          group.button("Invite", type: :button)
          group.button("New project", type: :button, variant: :primary, icon: :plus)
        end
      end
    end

    def render_preview_stats
      render NitroKit::StatGrid.new(id: "customizer-stats") do |stats|
        stats.stat(key: :projects, label: "Active projects", value: "12", detail: "+3 this month")
        stats.stat(key: :deployments, label: "Deployments", value: "48", detail: "99.98% healthy")
        stats.stat(key: :incidents, label: "Open incidents", value: "2", detail: "Both assigned")
      end
    end

    def render_preview_workspace
      div(data: { gallery: "customizer-preview-grid" }) do
        render_invitation_card
        render_activity_card
      end
    end

    def render_invitation_card
      render NitroKit::Card.new(id: "customizer-invitation") do |card|
        card.title("Invite a teammate", level: 3)
        card.body do
          render NitroKit::Flex.new(dir: :col, gap: 4, align: :stretch) do
            render NitroKit::Alert.new(variant: :success) do |alert|
              alert.title("Production is healthy")
              alert.description("Every regional check passed five minutes ago.")
            end
            render NitroKit::Field.new(
              as: :email,
              id: "customizer-email",
              name: "preview[email]",
              label: "Email address",
              description: "They can join your Team workspace.",
              placeholder: "teammate@example.com"
            )
            render NitroKit::Field.new(
              as: :select,
              id: "customizer-role",
              name: "preview[role]",
              label: "Role",
              value: "member",
              options: [ [ "Member", "member" ], [ "Administrator", "administrator" ] ]
            )
            render NitroKit::Checkbox.new(
              label: "Send a welcome email",
              id: "customizer-welcome",
              name: "preview[welcome]",
              checked: true
            )
          end
        end
        card.footer do
          render NitroKit::ButtonGroup.new(label: "Invitation actions") do |group|
            group.button("Cancel", type: :button)
            group.button("Send invitation", type: :button, variant: :primary)
          end
        end
      end
    end

    def render_activity_card
      render NitroKit::Card.new(id: "customizer-activity") do |card|
        card.title("Recent projects", level: 3)
        card.body { render_project_table }
        card.footer do
          render NitroKit::Flex.new(dir: :row, align: :center, gap: 2, wrap: :wrap) do
            render_preview_dropdown
            render_preview_dialog
          end
        end
      end
    end

    def render_project_table
      render NitroKit::Table.new(sort: :project, direction: :asc) do |table|
        table.caption("Projects ordered by name")
        table.thead do
          table.tr do
            table.th(sort: :project, href: "#customizer-sort-project")
            table.th(sort: :status, href: "#customizer-sort-status")
            table.th(sort: :members, href: "#customizer-sort-members", align: :right)
          end
        end
        table.tbody do
          preview_projects.each do |project|
            table.tr do
              table.th(project.fetch(:name), scope: :row)
              table.td { render NitroKit::Badge.new(project.fetch(:status), color: project.fetch(:color), size: :sm) }
              table.td(project.fetch(:members).to_s, align: :right)
            end
          end
        end
      end
    end

    def preview_projects
      [
        { name: "Atlas", status: "Active", color: :success, members: 8 },
        { name: "Beacon", status: "Review", color: :warning, members: 5 },
        { name: "Cedar", status: "Draft", color: :neutral, members: 3 }
      ]
    end

    def render_preview_dropdown
      render NitroKit::Dropdown.new(id: "customizer-actions", placement: :top_start) do |dropdown|
        dropdown.trigger("Project actions", size: :sm)
        dropdown.title("Manage project")
        dropdown.item("Duplicate")
        dropdown.item("Archive", variant: :destructive)
      end
    end

    def render_preview_dialog
      render NitroKit::Dialog.new(id: "customizer-dialog") do |dialog|
        dialog.trigger("Open dialog", size: :sm)
        dialog.dialog(
          title: "Create project",
          description: "Choose a clear name. You can change it later."
        ) do
          render NitroKit::Field.new(
            id: "customizer-project-name",
            name: "preview[project_name]",
            label: "Project name",
            placeholder: "Analytical Engine"
          )
          dialog.close_button
        end
      end
    end

    def render_former_pro_components
      section(
        aria: { labelledby: "customizer-pro-title" },
        data: { gallery: "customizer-pro" }
      ) do
        header do
          h2(id: "customizer-pro-title") { "Operational details" }
          p { "Former Pro capabilities use the same public theme contract." }
        end

        div(data: { gallery: "customizer-pro-grid" }) do
          render_details_card
          render_upload_card
        end
      end
    end

    def render_details_card
      render NitroKit::Card.new do |card|
        card.title("Workspace record", level: 3)
        card.full do
          render NitroKit::ProgressiveImage.new(
            attachment: nil,
            alt: "",
            size: :sm,
            id: "customizer-progressive-image"
          )
        end
        card.body do
          render NitroKit::DetailsTable.new(PREVIEW_RECORD, id: "customizer-details") do |details|
            details.fields(:workspace, :owner, :plan, :members)
          end
        end
      end
    end

    def render_upload_card
      render NitroKit::Card.new do |card|
        card.title("Release evidence", level: 3)
        card.body do
          render NitroKit::Dropzone.new(
            id: "customizer-dropzone",
            name: "preview[evidence][]",
            title: "Upload release evidence",
            description: "PDF or image · up to two files",
            direct_upload: false,
            multiple: true,
            accept: "image/*,.pdf",
            max_files: 2
          )
        end
      end
    end

    def controls
      section(
        aria: { labelledby: "customizer-controls-title" },
        data: { gallery: "customizer-controls-section" }
      ) do
        header(data: { gallery: "customizer-section-header" }) do
          div do
            p(data: { gallery: "eyebrow" }) { "Preset controls" }
            h2(id: "customizer-controls-title") { "Shape the system" }
          end
          p { "Every choice maps to a closed set of documented Nitro variables." }
        end

        form(
          data: {
            gallery: "customizer-controls",
            action: "change->gallery--customizer#change",
            gallery__customizer_target: "form"
          }
        ) do
          ThemePreset::ATTRIBUTES.each { |attribute| control_group(attribute) }
          appearance_control
        end
      end
    end

    def control_group(attribute)
      label, description = CONTROL_COPY.fetch(attribute)

      fieldset(
        data: {
          gallery: "customizer-control",
          gallery_control: attribute
        }
      ) do
        legend { label }
        p(id: "customizer-#{attribute}-description") { description }
        div(data: { gallery: "customizer-options" }) do
          ThemePreset::CHOICES.fetch(attribute).each do |choice|
            control_option(attribute, choice, selected: preset.public_send(attribute) == choice)
          end
        end
      end
    end

    def control_option(attribute, choice, selected:)
      render NitroKit::RadioButton.new(
        id: "customizer-#{attribute}-#{choice}",
        name: attribute,
        value: choice,
        checked: selected,
        required: true,
        size: :lg,
        data: {
          gallery: "customizer-option",
          gallery_option_kind: attribute,
          gallery_option: choice
        },
        control_aria: { describedby: "customizer-#{attribute}-description" }
      ) do
        span(
          aria: { hidden: "true" },
          data: {
            gallery: "customizer-swatch",
            gallery_swatch_kind: attribute,
            gallery_swatch: choice
          }
        ) { plain(swatch_text(attribute)) }
        span { choice.to_s.humanize }
      end
    end

    def swatch_text(attribute)
      attribute == :font ? "Aa" : ""
    end

    def appearance_control
      fieldset(
        data: {
          gallery: "customizer-control",
          gallery_control: "appearance"
        }
      ) do
        legend { "Preview appearance" }
        p(id: "customizer-appearance-description") do
          "Light, dark, or live system—preview only, never saved or shared."
        end
        div(data: { gallery: "customizer-options" }) do
          %i[light dark system].each do |appearance|
            render NitroKit::RadioButton.new(
              id: "customizer-appearance-#{appearance}",
              name: "appearance",
              value: appearance,
              checked: appearance == :system,
              required: true,
              size: :lg,
              data: {
                gallery: "customizer-option",
                gallery_option_kind: "appearance",
                gallery_option: appearance
              },
              control_aria: { describedby: "customizer-appearance-description" }
            ) do
              span(
                aria: { hidden: "true" },
                data: {
                  gallery: "customizer-swatch",
                  gallery_swatch_kind: "appearance",
                  gallery_swatch: appearance
                }
              )
              span { appearance.to_s.humanize }
            end
          end
        end
      end
    end

    def exports
      section(
        aria: { labelledby: "customizer-exports-title" },
        data: { gallery: "customizer-exports" }
      ) do
        header(data: { gallery: "customizer-section-header" }) do
          div do
            p(data: { gallery: "eyebrow" }) { "Install" }
            h2(id: "customizer-exports-title") { "Copy application-owned code" }
          end
          p { "CSS contains changed public tokens only. Ruby composes Nitro-owned components." }
        end

        render NitroKit::Tabs.new(
          id: "customizer-export-tabs",
          label: "Customization exports",
          default: :css
        ) do |tabs|
          tabs.tab(:css, "CSS") { export_panel(:css, preset.css) }
          tabs.tab(:ruby, "AppShell Ruby") { export_panel(:ruby, preset.app_shell_ruby) }
        end
      end
    end

    def export_panel(kind, source)
      language = kind == :css ? "CSS" : "Ruby"

      div(data: { gallery: "customizer-export", gallery_export: kind }) do
        header do
          div do
            strong { language }
            small do
              kind == :css ? "app/assets/stylesheets/nitro_theme.css" : "app/components/workspace/layout.rb"
            end
          end
          render NitroKit::Button.new(
            "Copy #{language}",
            type: :button,
            size: :sm,
            variant: :ghost,
            icon: :copy,
            data: {
              action: "gallery--customizer#copy",
              copy_kind: kind
            }
          )
        end
        pre(tabindex: 0, aria: { label: "Generated #{language}" }) do
          code(data: { gallery__customizer_target: "#{kind}Output" }) { plain(source) }
        end
      end
    end

    def copy_status
      p(
        role: "status",
        aria: { live: "polite", atomic: "true" },
        data: {
          gallery: "customizer-status",
          gallery__customizer_target: "status"
        }
      )
    end
  end
end
