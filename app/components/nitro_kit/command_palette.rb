# frozen_string_literal: true

module NitroKit
  class CommandPalette < Component
    Destination = ::Data.define(
      :label,
      :href,
      :description,
      :html,
      :aria,
      :data,
      :css_class
    )
    private_constant :Destination

    module Validation
      private

      def required_text(name, value)
        return value if value.is_a?(String) && !value.strip.empty?

        raise ArgumentError, "#{name} must be a non-blank String"
      end
    end
    private_constant :Validation

    module Destinations
      def destination(
        label,
        href:,
        description: nil,
        html: {},
        aria: {},
        data: {},
        desperately_need_a_class: nil
      )
        ensure_collecting!

        @destinations << Destination.new(
          label: required_text(:label, label),
          href: required_text(:href, href),
          description: validate_optional_text!(:description, description),
          html:,
          aria:,
          data:,
          css_class: desperately_need_a_class
        )
        nil
      end
    end
    private_constant :Destinations

    include Validation
    include Destinations

    class Results < Component
      include Validation
      include Destinations

      def initialize(
        id:,
        html: {},
        aria: {},
        data: {},
        desperately_need_a_class: nil
      )
        @identifier = validate_id!("CommandPalette id:", id)
        @destinations = []

        super(
          component: :command_palette_results,
          attributes: {
            id: frame_id,
            target: "_top",
            data: {
              nk__command_palette_target: "frame",
              action: [
                "turbo:before-fetch-request->nk--command-palette#loading",
                "turbo:frame-load->nk--command-palette#loaded"
              ].join(" ")
            }
          },
          html:,
          aria:,
          data:,
          desperately_need_a_class:
        )
      end

      def view_template(&block)
        @collecting = true
        yield(self) if block

        tag(:"turbo-frame", **root_attributes) do
          nav(
            **slot_attributes(
              :results,
              attributes: { id: results_id, aria: { labelledby: title_id } }
            )
          ) do
            @destinations.each_with_index { |destination, index| render_destination(destination, index) }
          end
        end
      ensure
        @collecting = false
      end

      private

      def render_destination(destination, index)
        a(
          **slot_attributes(
            :destination,
            attributes: {
              id: destination_id(index),
              href: destination.href,
              data: {
                nk__command_palette_target: "destination",
                action: "click->nk--command-palette#select keydown->nk--command-palette#navigateDestination"
              }
            },
            html: destination.html,
            aria: destination.aria,
            data: destination.data,
            desperately_need_a_class: destination.css_class
          )
        ) do
          span(**slot_attributes(:destination_label)) { destination.label }
          if destination.description
            span(**slot_attributes(:destination_description)) { destination.description }
          end
        end
      end

      def frame_id = "#{@identifier}-results-frame"
      def results_id = "#{@identifier}-results"
      def title_id = "#{@identifier}-title"
      def destination_id(index) = "#{@identifier}-destination-#{index + 1}"

      def ensure_collecting!
        return if @collecting

        raise ArgumentError, "CommandPalette::Results destinations must be declared inside the render block"
      end

      def qualified_slot(slot)
        slot_name = normalize_identity(slot, name: "slot")
        slot_name.start_with?("command-palette-") ? slot_name : "command-palette-#{slot_name}"
      end
    end

    def initialize(
      id:,
      label: I18n.t("nitro_kit.command_palette.label"),
      placeholder: I18n.t("nitro_kit.command_palette.placeholder"),
      empty_text: I18n.t("nitro_kit.command_palette.empty"),
      close_label: I18n.t("nitro_kit.command_palette.close"),
      shortcut: true,
      shortcut_label: I18n.t("nitro_kit.command_palette.shortcut"),
      search_url: nil,
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil
    )
      @identifier = validate_id!("CommandPalette id:", id)
      @label = required_text(:label, label)
      @placeholder = required_text(:placeholder, placeholder)
      @empty_text = required_text(:empty_text, empty_text)
      @close_label = required_text(:close_label, close_label)
      @shortcut = validate_boolean!(:shortcut, shortcut)
      @shortcut_label = required_text(:shortcut_label, shortcut_label)
      @search_url = validate_optional_text!(:search_url, search_url)
      @destinations = []

      super(
        component: :command_palette,
        attributes: {
          id: @identifier,
          data: {
            controller: "nk--dialog nk--command-palette",
            action: root_actions,
            nk__dialog_dismissible_value: true,
            nk__command_palette_empty_value: @empty_text,
            nk__command_palette_results_one_value: I18n.t("nitro_kit.command_palette.results.one"),
            nk__command_palette_results_other_value: I18n.t("nitro_kit.command_palette.results.other")
          }
        },
        html:,
        aria:,
        data:,
        desperately_need_a_class:
      )
    end

    attr_reader :identifier

    def view_template(&block)
      collect_destinations(&block)

      div(**root_attributes) do
        render_trigger
        render_panel
      end
    end

    private

    def collect_destinations
      raise ArgumentError, "CommandPalette requires a declaration block" unless block_given?

      @collecting = true
      yield(self)
      raise ArgumentError, "CommandPalette requires at least one destination" if @destinations.empty?
    ensure
      @collecting = false
    end

    def render_trigger
      render_in_slot(
        Button.new(
          icon: :search,
          html: { command: "show-modal", commandfor: panel_id },
          aria: {
            haspopup: "dialog",
            keyshortcuts: @shortcut ? "Meta+K Control+K" : nil
          }.compact,
          data: {
            nk__command_palette_target: "trigger",
            nk__dialog_command: "show-modal",
            action: "click->nk--command-palette#openedByTrigger"
          }
        ),
        :trigger
      ) do
        span(**slot_attributes(:trigger_label)) { @label }
        if @shortcut
          kbd(**slot_attributes(:shortcut, attributes: { aria: { hidden: true } })) do
            @shortcut_label
          end
        end
      end
    end

    def render_panel
      dialog(
        **slot_attributes(
          :panel,
          attributes: {
            id: panel_id,
            closedby: "any",
            aria: { labelledby: title_id },
            data: {
              nk__dialog_target: "panel",
              nk__command_palette_target: "panel",
              action: [
                "command->nk--command-palette#guardOpen",
                "click->nk--dialog#dismiss",
                "cancel->nk--dialog#cancel",
                "close->nk--dialog#restoreFocus",
                "close->nk--command-palette#closed"
              ].join(" ")
            }
          }
        )
      ) do
        h2(**slot_attributes(:title, attributes: { id: title_id })) { @label }
        render_close
        render_search
        render_destinations
        render_empty
        render_status
      end
    end

    def render_search
      attributes = slot_attributes(
        :search,
        attributes: {
          hidden: true,
          action: @search_url,
          method: @search_url ? "get" : nil,
          data: {
            nk__command_palette_target: @search_url ? "form search" : "search",
            turbo_frame: @search_url ? frame_id : nil
          }.compact
        }.compact
      )

      if @search_url
        form(**attributes) { render_search_field }
      else
        div(**attributes) { render_search_field }
      end
    end

    def render_search_field
        render_in_slot(Icon.new(:search, size: :sm), :search_icon)
        render_in_slot(
          Input.new(
            type: :search,
            name: @search_url ? "query" : nil,
            placeholder: @placeholder,
            autocomplete: "off",
            aria: { label: @label, controls: results_id },
            data: {
              nk__command_palette_target: "input",
              action: [
                "input->nk--command-palette##{@search_url ? "search" : "filter"}",
                "keydown->nk--command-palette#navigateInput"
              ].join(" ")
            }
          ),
          :input
        )
    end

    def render_close
      render_in_slot(
        Button.new(
          icon: :x,
          variant: :ghost,
          size: :md,
          html: { command: "close", commandfor: panel_id },
          data: { nk__dialog_command: "close" },
          aria: { label: @close_label }
        ),
        :close
      )
    end

    def render_destinations
      render Results.new(id: identifier) do |results|
        @destinations.each do |destination|
          results.destination(
            destination.label,
            href: destination.href,
            description: destination.description,
            html: destination.html,
            aria: destination.aria,
            data: destination.data,
            desperately_need_a_class: destination.css_class
          )
        end
      end
    end

    def render_empty
      p(
        **slot_attributes(
          :empty,
          attributes: {
            hidden: true,
            data: { nk__command_palette_target: "empty" }
          }
        )
      ) { @empty_text }
    end

    def render_status
      p(
        **slot_attributes(
          :status,
          attributes: {
            role: "status",
            aria: { live: "polite", atomic: "true" },
            data: { nk__command_palette_target: "status" }
          }
        )
      )
    end

    def root_actions
      actions = [
        "turbo:before-visit@document->nk--command-palette#closeForVisit",
        "turbo:before-cache@document->nk--command-palette#closeForVisit",
        "click->nk--dialog#invoke",
        "turbo:before-cache@document->nk--dialog#closeForCache"
      ]
      actions.prepend("keydown@document->nk--command-palette#shortcut") if @shortcut
      actions.join(" ")
    end

    def panel_id = "#{identifier}-panel"
    def title_id = "#{identifier}-title"
    def results_id = "#{identifier}-results"
    def frame_id = "#{identifier}-results-frame"

    def ensure_collecting!
      return if @collecting

      raise ArgumentError, "CommandPalette destinations must be declared inside the render block"
    end
  end
end
