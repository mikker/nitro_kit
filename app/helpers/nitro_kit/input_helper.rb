# frozen_string_literal: true

module NitroKit
  module InputHelper
    def nk_input(**attrs)
      render(Input.new(**attrs))
    end

    %w[
      color
      date
      datetime
      datetime_local
      email
      file
      hidden
      month
      number
      password
      phone
      range
      search
      telephone
      text
      time
      url
      week
    ]
      .each do |type|
        define_method("nk_#{type}_field_tag") do |compat_name = nil, compat_value = nil, **attrs|
          attrs[:name] ||= compat_name
          attrs[:value] ||= compat_value
          nk_input(type:, **attrs)
        end
      end
  end
end
