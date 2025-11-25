# frozen_string_literal: true

require "pagy/toolbox/helpers/support/series"

module NitroKit
  module PaginationHelper
    def nk_pagination(**attrs, &block)
      render(Pagination.from_template(**attrs), &block)
    end

    def nk_pagy_nav(pagy, id: nil, aria_label: nil, **attrs)
      attrs[:aria] ||= { label: aria_label }

      nk_pagination(id:, **attrs) do |p|
        if prev_page = pagy.previous
          p.prev(href: pagy.page_url(prev_page))
        else
          p.prev(disabled: true)
        end

        pagy.send(:series).each do |item|
          case item
          when Integer
            p.page(item.to_s, href: pagy.page_url(item))
          when String
            p.page(item, current: true)
          when :gap
            p.ellipsis
          else
            raise ArgumentError, "Unknown item type: #{item.class}"
          end
        end

        if next_page = pagy.next
          p.next(href: pagy.page_url(next_page))
        else
          p.next(disabled: true)
        end
      end
    end
  end
end
