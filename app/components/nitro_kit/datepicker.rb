# frozen_string_literal: true

module NitroKit
  class Datepicker < Component
    def view_template
      render(Input.new(type: "text", **attrs, data: {controller: "nk--datepicker"}))
    end
  end
end
