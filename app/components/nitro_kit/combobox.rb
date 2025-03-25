# frozen_string_literal: true

module NitroKit
  class Combobox < Component
    def initialize(
      options: [],
      id: nil,

      placement: "bottom",
      tab_inserts_suggestions: true,
      first_option_selection_mode: "selected",
      scroll_into_view_options: {block: "nearest", inline: "nearest"},

      **attrs
    )
      # floating-ui options
      @placement = placement

      # combobox-nav options
      @tab_inserts_suggestions = tab_inserts_suggestions
      @first_option_selection_mode = first_option_selection_mode
      @scroll_into_view_options = scroll_into_view_options

      @id = id || "nk--combobox-" + SecureRandom.hex(4)

      @options = options

      super(
        attrs,
        type: "text",
        class: input_class,
        data: {
          nk__combobox_target: "input",
          action: %w[
            focusin->nk--combobox#open
            focusin@window->nk--combobox#focusShift
            click@window->nk--combobox#windowClick
            input->nk--combobox#input
            keydown.esc->nk--combobox#clear
            keydown.down->nk--combobox#open
          ]
        },
        aria: {
          controls: id(:listbox)
        }
      )
    end

    attr_reader(
      :options,
      :placement,
      :tab_inserts_suggestions,
      :first_option_selection_mode,
      :scroll_into_view_options
    )

    def view_template
      div(
        data: {
          class: "isolate",
          slot: "control",
          controller: "nk--combobox",
          nk__combobox_placement_value: placement,
          nk__combobox_tab_inserts_suggestions_value: tab_inserts_suggestions.to_s,
          nk__combobox_first_option_selection_mode_value: first_option_selection_mode.to_s,
          nk__combobox_scroll_into_view_options_value: scroll_into_view_options&.to_json
        }
      ) do
        span(class: wrapper_class) do
          render(Input.new(**attrs, value: display_value))
          chevron_icon
        end

        # Since a combobox can function like a <select> element where the displayed
        # value and the form value differ, include the value in a hidden field
        input(
          type: "hidden",
          value: attrs[:value],
          name: attrs[:name],
          data: {nk__combobox_target: "hiddenField"}
        )

        ul(
          role: "listbox",
          id: id(:listbox),
          class: list_class,
          data: {nk__combobox_target: "list", state: "closed"}
        ) do
          options.each do |(key, value)|
            li(
              role: "option",
              data: {value:},
              class: merge_class(option_class)
            ) { key }
          end
        end
      end
    end

    private

    def id(suffix)
      "#{@id}-#{suffix}"
    end

    def display_value
      selected = options.find do |(key, value)|
        value.to_s == attrs[:value].to_s
      end

      selected&.first || attrs[:value]
    end

    def wrapper_class
      "inline-grid *:[grid-area:1/1] group/combobox"
    end

    def input_class
      "pr-8"
    end

    def list_class
      [
        "absolute top-0 left-0 p-1 bg-background rounded-md border shadow-sm w-fit max-w-sm flex-col flex z-10",
        "max-h-60 overflow-y-auto",
        "data-[state=closed]:hidden [&:not(:has([role=option]))]:hidden",
        "[&_[aria-selected]]:bg-muted"
      ]
    end

    def option_class
      "hidden flex-none px-2 py-1 rounded font-medium truncate cursor-pointer hover:bg-muted [&[role=option]]:block"
    end

    def chevron_icon
      svg(
        class: "size-4 self-center place-self-end mr-2 pointer-events-none text-muted-content group-hover/combobox:text-foreground",
        viewbox: "0 0 24 24",
        fill: "none",
        stroke: "currentColor",
        stroke_width: 1
      ) do |svg|
        svg.path(d: "m6 9 6 6 6-6")
      end
    end
  end
end
