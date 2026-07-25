module Gallery
  class PreviewLayout < Phlex::HTML
    include Phlex::Rails::Layout
    include Phlex::Rails::Helpers::ContentSecurityPolicyNonce
    include Phlex::Rails::Helpers::Request

    EXPLICIT_APPEARANCES = %w[light dark].freeze

    def view_template
      doctype

      html(lang: "en", data: document_data) do
        head do
          title { "Nitro Kit responsive preview" }
          meta(charset: "utf-8")
          meta(name: "viewport", content: "width=device-width, initial-scale=1")
          csrf_meta_tags
          csp_meta_tag
          render NitroKit::AppearanceBootstrap.new(
            default: appearance_default,
            nonce: content_security_policy_nonce
          )
          stylesheet_link_tag("nitro_kit", "gallery", data: { turbo_track: "reload" })
          javascript_importmap_tags
        end

        body(data: { gallery: "preview-body" }) { yield }
      end
    end

    private

    def document_data
      data = { gallery: "document", gallery_preview_document: "true" }
      return data if appearance_default == :system

      data.merge(theme: appearance_default, theme_preference: appearance_default)
    end

    def appearance_default
      requested_theme = request.query_parameters["theme"]
      EXPLICIT_APPEARANCES.include?(requested_theme) ? requested_theme.to_sym : :system
    end
  end
end
