module Gallery
  class Layout < Phlex::HTML
    include Phlex::Rails::Layout
    include Phlex::Rails::Helpers::ContentSecurityPolicyNonce
    include Phlex::Rails::Helpers::Request
    include Phlex::Rails::Helpers::Routes

    EXPLICIT_APPEARANCES = %w[light dark].freeze

    def view_template
      doctype

      html(lang: "en", data: document_data) do
        head do
          title { "Nitro Kit Gallery" }
          meta(charset: "utf-8")
          meta(name: "viewport", content: "width=device-width, initial-scale=1")
          meta(name: "turbo-refresh-method", content: "morph")
          meta(name: "turbo-refresh-scroll", content: "preserve")
          link(rel: "icon", href: "/favicon.svg", type: "image/svg+xml")
          csrf_meta_tags
          csp_meta_tag
          render NitroKit::AppearanceBootstrap.new(
            default: appearance_default,
            nonce: content_security_policy_nonce
          )
          stylesheet_link_tag("nitro_kit", "gallery", data: { turbo_track: "reload" })
          javascript_importmap_tags
        end

        body(data: { gallery: "body" }) do
          div(data: { gallery: "shell" }) do
            gallery_sidebar
            div(data: { gallery: "main" }) { yield }
          end
        end
      end
    end

    private

    def gallery_sidebar
      aside(data: { gallery: "sidebar" }) do
        header(data: { gallery: "brand" }) do
          a(href: gallery_root_path) { "Nitro Kit" }
          small { "2.0 gallery" }
        end

        nav(aria: { label: "Gallery" }, data: { gallery: "navigation" }) do
          ul(data: { gallery: "navigation-primary" }) do
            li { navigation_link("Introduction", gallery_root_path) }
            li { navigation_link("Agent guide", gallery_agent_guide_path) }
            li { navigation_link("Human guide", gallery_guide_path) }
          end

          Gallery::Catalog.collections.each do |collection|
            navigation_collection(collection)
          end
        end

        div(data: { gallery: "theme-switcher" }) do
          render NitroKit::AppearancePicker.new(
            id: "gallery-appearance",
            label: "Appearance"
          )
        end
      end
    end

    def navigation_collection(collection)
      section(
        data: {
          gallery: "navigation-collection",
          gallery_kind: collection.kind
        }
      ) do
        h2 { collection.title }
        p(data: { gallery: "navigation-description" }) { collection.description }

        collection.categories.each { |category| navigation_category(category) }
      end
    end

    def navigation_category(category)
      details(
        open: current_category?(category) ? true : nil,
        data: {
          gallery: "navigation-category",
          gallery_category: category.slug
        }
      ) do
        summary { category.title }
        navigation_entries(category.entries)
      end
    end

    def navigation_entries(entries)
      ul do
        entries.each do |entry|
          li { navigation_link(entry.title, entry_path(entry), entry:) }
        end
      end
    end

    def navigation_link(label, path, entry: nil)
      a(
        href: path,
        aria: { current: navigation_current?(path, entry:) ? "page" : nil }
      ) { label }
    end

    def navigation_current?(path, entry:)
      entry ? current_entry?(entry) : request.path == path
    end

    def current_entry?(entry)
      request.path_parameters[:controller] == "gallery/#{entry.kind.to_s.pluralize}" &&
        request.path_parameters[:slug] == entry.slug
    end

    def current_category?(category)
      category.entries.any? { |entry| current_entry?(entry) }
    end

    def entry_path(entry)
      Gallery::Catalog.path_for(entry, routes: self)
    end

    def document_data
      data = { gallery: "document" }
      return data if appearance_default == :system

      data.merge(theme: appearance_default, theme_preference: appearance_default)
    end

    def appearance_default
      requested_theme = request.query_parameters["theme"]

      EXPLICIT_APPEARANCES.include?(requested_theme) ? requested_theme.to_sym : :system
    end
  end
end
