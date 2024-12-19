# frozen_string_literal: true

module NitroKit
  module FieldGroupHelper
    def nk_field_group(**attrs)
      render(NitroKit::FieldGroup.new(**attrs)) { yield }
    end
  end
end
