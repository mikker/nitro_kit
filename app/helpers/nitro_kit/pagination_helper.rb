# frozen_string_literal: true

module NitroKit
  module PaginationHelper
    include Pagy::UrlHelpers

    def nk_pagination(**attrs, &block)
      render(Pagination.new(**attrs), &block)
    end

    def nk_pagy_nav(pagy, id: nil, aria_label: nil, **attrs)
      attrs[:aria] ||= {label: aria_label}

      nk_pagination(id:, **attrs) do |p|
        if href = pagy.prev
          p.prev(href:)
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

        if href = pagy.next
          p.next(href:)
        else
          p.next(disabled: true)
        end
      end
    end
  end
end
