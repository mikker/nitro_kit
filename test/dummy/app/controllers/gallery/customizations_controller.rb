module Gallery
  class CustomizationsController < ApplicationController
    def show
      result = ThemePreset.parse(request.query_parameters)

      render CustomizePage.new(
        preset: result.preset,
        errors: result.errors,
        nonce: content_security_policy_nonce
      )
    end
  end
end
