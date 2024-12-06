# frozen_string_literal: true

module NitroKit
  class Combobox < Component
    def initialize(
      options: [],
      id: nil,

      placement: nil,
      tab_inserts_suggestions: nil,
      first_option_selection_mode: nil,
      scroll_into_view_options: nil,

      **attrs
    )
      super(**attrs)

      @placement = placement
      @tab_inserts_suggestions = tab_inserts_suggestions
      @first_option_selection_mode = first_option_selection_mode
      @scroll_into_view_options = scroll_into_view_options

      @id = id || "nk--combobox-" + SecureRandom.hex(4)

      @options = options
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
        data: data_merge(
          attrs[:data],
          slot: "control",
          controller: "nk--combobox",
          nk__combobox_placement_value: placement,
          nk__combobox_tab_inserts_suggestions_value: tab_inserts_suggestions.to_s,
          nk__combobox_first_option_selection_mode_value: first_option_selection_mode.to_s,
          nk__combobox_scroll_into_view_options_value: scroll_into_view_options&.to_json
        )
      ) do
        span(
          class: merge(wrapper_class, attrs[:class])
        ) do
          render(
            Input.new(
              type: "text",
              **attrs,
              # don't include class from attrs
              class: input_class,
              data: data_merge(
                attrs[:data],
                nk__combobox_target: "input",
                action: %w[
                  focusin->nk--combobox#open
                  focusin@window->nk--combobox#focusShift
                  click@window->nk--combobox#windowClick
                  input->nk--combobox#input
                  keydown.esc->nk--combobox#clear
                  keydown.down->nk--combobox#open
                ]
              ),
              aria: {
                controls: id(:listbox)
              }
            )
          )

          chevron_icon
        end

        input(
          type: "hidden",
          value: attrs[:value],
          data: {nk__combobox_target: "hiddenField"}
        )

        ul(
          role: "listbox",
          id: id(:listbox),
          class: merge(list_class),
          data: {nk__combobox_target: "list", state: "closed"}
        ) do
          options.each do |(key, value)|
            li(
              role: "option",
              data: {value:},
              class: merge(option_class)
            ) { key }
          end
        end
      end
    end

    private

    def id(suffix)
      "#{@id}-#{suffix}"
    end

    def wrapper_class
      "grid *:[grid-area:1/1] group/combobox"
    end

    def input_class
      "pr-8"
    end

    def list_class
      [
        "absolute top-0 left-0 p-1 bg-background rounded-md border shadow-sm w-fit max-w-sm flex-col flex",
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
        class: "size-4 self-center place-self-end mr-2 pointer-events-none text-muted-foreground group-hover/combobox:text-foreground",
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
