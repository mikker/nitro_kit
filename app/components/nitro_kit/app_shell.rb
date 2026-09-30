# frozen_string_literal: true

module NitroKit
  class AppShell < Component
    alias_method :html_main, :main

    LAYOUTS = %i[sidebar topbar].freeze
    SIDEBAR_STATES = %i[expanded collapsed].freeze
    REGIONS = %i[brand navigation topbar main].freeze
    REQUIRED_REGIONS = %i[navigation main].freeze
    private_constant :REQUIRED_REGIONS

    def initialize(
      id:,
      layout: :sidebar,
      collapsible: false,
      sidebar: :expanded,
      sidebar_toggle_label: I18n.t("nitro_kit.app_shell.pin_sidebar"),
      skip_link_label: I18n.t("nitro_kit.app_shell.skip_link"),
      open_navigation_label: I18n.t("nitro_kit.app_shell.open_navigation"),
      close_navigation_label: I18n.t("nitro_kit.app_shell.close_navigation"),
      navigation_dialog_label: I18n.t("nitro_kit.app_shell.navigation_dialog"),
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil
    )
      @identifier = validate_id!("AppShell id", id)
      @layout = validate_choice!(:layout, layout, LAYOUTS)
      @collapsible = validate_boolean!(:collapsible, collapsible)
      @sidebar = validate_choice!(:sidebar, sidebar, SIDEBAR_STATES)
      if @sidebar == :collapsed && !@collapsible
        raise ArgumentError, "AppShell sidebar: :collapsed requires collapsible: true"
      end
      @sidebar_toggle_label = validate_label!(:sidebar_toggle_label, sidebar_toggle_label)
      @skip_link_label = validate_label!(:skip_link_label, skip_link_label)
      @open_navigation_label = validate_label!(:open_navigation_label, open_navigation_label)
      @close_navigation_label = validate_label!(:close_navigation_label, close_navigation_label)
      @navigation_dialog_label = validate_label!(:navigation_dialog_label, navigation_dialog_label)
      @regions = REGIONS.to_h { |name| [ name, nil ] }
      @collecting = false

      super(
        component: :app_shell,
        attributes: {
          id: @identifier,
          data: {
            controller: "nk--app-shell",
            layout: @layout,
            state: "closed",
            action: "turbo:before-visit@document->nk--app-shell#closeForNavigation " \
              "turbo:before-morph-attribute->nk--app-shell#preserveSidebarState " \
              "turbo:morph@document->nk--app-shell#syncViewport",
            nk__app_shell_open_label_value: @open_navigation_label,
            nk__app_shell_close_label_value: @close_navigation_label,
            nk__app_shell_collapsible_value: @collapsible.to_s,
            nk__app_shell_pinned_value: (@sidebar == :expanded).to_s
          }
        },
        html:,
        aria:,
        data:,
        desperately_need_a_class:
      )
    end

    attr_reader :identifier, :layout

    def view_template(&declarations)
      collect_regions(&declarations)

      div(**root_attributes) do
        render_skip_link
        render_header
        render_sidebar
        render_dialog
        render_main
      end
    end

    def brand(icon: nil, &content)
      add_region(:brand, content:)
      @brand_icon = Icon.new(icon, size: :sm) unless icon.nil?
    end

    def navigation(&content)
      add_region(:navigation, content:)
    end

    def topbar(&content)
      add_region(:topbar, content:)
    end

    def main(&content)
      add_region(:main, content:)
    end

    private

    def collect_regions
      raise ArgumentError, "AppShell requires a declaration block" unless block_given?

      @collecting = true
      output = capture(self) { |shell| yield shell }
      unless output.empty?
        raise ArgumentError, "AppShell render block accepts region declarations, not rendered content"
      end
      REQUIRED_REGIONS.each do |region|
        next if @regions.fetch(region)

        raise ArgumentError, "AppShell requires exactly one #{region} region"
      end
    ensure
      @collecting = false
    end

    def add_region(name, content:)
      unless @collecting
        raise ArgumentError, "AppShell #{name} must be declared directly inside the render block"
      end
      if @regions.fetch(name)
        limit = REQUIRED_REGIONS.include?(name) ? "exactly one" : "at most one"
        raise ArgumentError, "AppShell accepts #{limit} #{name} region"
      end
      raise ArgumentError, "AppShell #{name} requires a block" unless content

      @regions[name] = content
      nil
    end

    def region(name)
      @regions.fetch(name)
    end

    def render_skip_link
      a(**slot_attributes(:skip_link, attributes: { href: "##{main_id}" })) { @skip_link_label }
    end

    def render_header
      header(**slot_attributes(:header)) do
        if region(:brand)
          div(**slot_attributes(:brand, attributes: { data: { action: @collapsible ? "pointerleave->nk--app-shell#resumeHover" : nil } })) do
            render_in_slot(@brand_icon, :brand_icon) if @brand_icon
            div(**slot_attributes(:brand_content)) { render(region(:brand)) }
          end
        end
        render_mobile_trigger
        div(**slot_attributes(:topbar)) { render(region(:topbar)) } if region(:topbar)
      end
    end

    def render_mobile_trigger
      button(
        **slot_attributes(
          :mobile_trigger,
          attributes: {
            type: "button",
            aria: {
              controls: drawer_id,
              expanded: false,
              label: @open_navigation_label
            },
            data: {
              nk__app_shell_target: "trigger",
              action: "click->nk--app-shell#toggle"
            }
          }
        )
      ) { render(Icon.new(:menu, size: :sm)) }
    end

    def render_sidebar
      div(
        **slot_attributes(
          :sidebar,
          attributes: {
            data: {
              nk__app_shell_target: "sidebar",
              action: @collapsible ? "pointerleave->nk--app-shell#resumeHover" : nil
            }
          }
        )
      ) do
        div(
          **slot_attributes(
            :navigation,
            attributes: { id: navigation_region_id, data: { nk__app_shell_target: "navigation" } }
          )
        ) { render(region(:navigation)) }
        render_sidebar_toggle if layout == :sidebar && @collapsible
      end
    end

    def render_sidebar_toggle
      render_in_slot(Button.new(
        icon: :panel_left,
        label: @sidebar_toggle_label,
        aria: { controls: navigation_region_id, pressed: @sidebar == :expanded },
        data: { nk__app_shell_target: "pin", action: "click->nk--app-shell#togglePin" }
      ), :sidebar_toggle)
    end

    def render_dialog
      dialog(
        **slot_attributes(
          :dialog,
          attributes: {
            id: drawer_id,
            aria: { label: @navigation_dialog_label },
            data: {
              nk__app_shell_target: "dialog",
              action: [
                "close->nk--app-shell#dialogClosed",
                "click->nk--app-shell#closeFromBackdrop"
              ].join(" ")
            }
          }
        )
      ) { render_mobile_close }
    end

    def render_mobile_close
      button(
        **slot_attributes(
          :mobile_close,
          attributes: {
            type: "button",
            aria: { label: @close_navigation_label },
            data: { action: "click->nk--app-shell#close" }
          }
        )
      ) { render(Icon.new(:x, size: :sm)) }
    end

    def render_main
      html_main(**slot_attributes(:main, attributes: { id: main_id, tabindex: -1 })) { render(region(:main)) }
    end

    def navigation_region_id
      "#{identifier}-navigation-region"
    end

    def drawer_id
      "#{identifier}-navigation-drawer"
    end

    def main_id
      "#{identifier}-main"
    end

    def validate_label!(name, value)
      return value if value.is_a?(String) && !value.strip.empty?

      raise ArgumentError, "AppShell #{name} must be a non-blank String"
    end
  end
end
