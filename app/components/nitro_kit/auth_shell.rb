# frozen_string_literal: true

module NitroKit
  class AuthShell < Component
    def initialize(
      id: nil,
      html: {},
      aria: {},
      data: {},
      desperately_need_a_class: nil
    )
      super(
        component: :auth_shell,
        attributes: { id: }.compact,
        html:,
        aria:,
        data:,
        desperately_need_a_class:
      )
    end

    def view_template
      raise ArgumentError, "NitroKit::AuthShell requires a content block" unless block_given?

      main(**root_attributes) do
        render NitroKit::Container.new(size: :md) do
          render NitroKit::VStack.new(gap: :lg, align: :stretch) do
            yield
          end
        end
      end
    end
  end
end
