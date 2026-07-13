module Gallery
  class Layout < Phlex::HTML
    include Phlex::Rails::Layout
    include Phlex::Rails::Helpers::Request
    include Phlex::Rails::Helpers::Routes

    THEMES = %w[light dark].freeze

    def view_template
      doctype

      html(lang: "en", data: { gallery: "document", theme: }) do
        head do
          title { "Nitro Kit Gallery" }
          meta(charset: "utf-8")
          meta(name: "viewport", content: "width=device-width, initial-scale=1")
          meta(name: "turbo-refresh-method", content: "morph")
          meta(name: "turbo-refresh-scroll", content: "preserve")
          link(rel: "icon", href: "/favicon.svg", type: "image/svg+xml")
          csrf_meta_tags
          csp_meta_tag
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
          navigation_link("Overview", gallery_root_path)

          Gallery::Catalog.navigation_groups.each do |group|
            section(data: { gallery: "navigation-group" }) do
              h2 { group.title }

              if group.entries.any?
                group.entries.each do |entry|
                  navigation_link(entry.title, entry_path(entry))
                end
              else
                small { "None yet" }
              end
            end
          end
        end

        nav(aria: { label: "Theme" }, data: { gallery: "theme-switcher" }) do
          THEMES.each do |name|
            a(
              href: theme_path(name),
              aria: { current: theme == name ? "page" : nil },
              data: { gallery_theme: name }
            ) { name.capitalize }
          end
        end
      end
    end

    def navigation_link(label, path)
      a(
        href: path,
        aria: { current: request.path == path ? "page" : nil }
      ) { label }
    end

    def entry_path(entry)
      Gallery::Catalog.path_for(entry, routes: self)
    end

    def theme_path(name)
      "#{request.path}?theme=#{name}"
    end

    def theme
      requested_theme = request.query_parameters["theme"]

      THEMES.include?(requested_theme) ? requested_theme : "light"
    end
  end
end
