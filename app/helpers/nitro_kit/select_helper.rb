module NitroKit
  module SelectHelper
    def nk_select(options = [], value: nil, **attrs, &block)
      if block_given?
        render(Select.new(value:, **attrs), &block)
      else
        render(Select.new(value:, **attrs)) do |s|
          options.each { |(key, value)| s.option(value: value || key) { key } }
        end
      end
    end
  end
end
