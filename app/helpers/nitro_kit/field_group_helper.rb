# frozen_string_literal: true

module NitroKit
  module FieldGroupHelper
    def nk_field_group(**attrs)
      render(NitroKit::FieldGroup.from_erb(**attrs)) { yield }
    end
  end
end
