# frozen_string_literal: true

module NitroKit
  module TextareaHelper
    def nk_textarea(**attrs)
      render(Textarea.new(**attrs))
    end
  end
end
