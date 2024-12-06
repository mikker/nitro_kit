# frozen_string_literal: true

module NitroKit
  module PaginationHelper
    include Pagy::UrlHelpers if defined?(Pagy)

    def nk_pagination(**attrs, &block)
      render(Pagination.new(**attrs), &block)
    end

    def nk_pagy_nav(pagy, id: nil, aria_label: nil, **attrs)
      attrs[:aria] ||= {label: aria_label}

      nk_pagination(id:, **attrs) do |p|
        if prev_page = pagy.prev
          p.prev(href: pagy_url_for(pagy, prev_page))
        else
          p.prev(disabled: true)
        end

        pagy.series.each do |item|
          case item
          when Integer
            p.page(item.to_s, href: pagy_url_for(pagy, item))
          when String
            p.page(item, current: true)
          when :gap
            p.ellipsis
          else
            raise ArgumentError, "Unknown item type: #{item.class}"
          end
        end

        if next_page = pagy.next
          p.next(href: pagy_url_for(pagy, next_page))
        else
          p.next(disabled: true)
        end
      end
    end
  end
end
