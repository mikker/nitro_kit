# frozen_string_literal: true

module NitroKit
  module ToastHelper
    def nk_toast(**attrs, &block)
      render(Toast.new(**attrs), &block)
    end

    def nk_toast_action(title: nil, description: nil, event: nil)
      {
        action: "#{event ? "#{event}->" : ""}nk--toast#toast",
        nk__toast_title_param: title,
        nk__toast_description_param: description
      }
    end

    def nk_toast_flash_messages
      capture do
        flash.each do |severity, message|
          concat(
            render(
              Toast::Item.new(
                description: message,
                variant: severity.to_sym == :alert ? :error : :default
              )
            )
          )
        end
      end
    end

    def nk_toast_turbo_stream_refresh
      turbo_stream.append("nk--toast-sink", nk_toast_flash_messages)
    end
  end
end
