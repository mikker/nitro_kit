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
          stylesheet_link_tag("lexxy", "nitro_kit", "gallery", data: { turbo_track: "reload" })
          javascript_importmap_tags
          javascript_import_module_tag("lexxy")
        end

        body(data: { gallery: "body" }) do
          render NitroKit::AppShell.new(
            id: "gallery-shell",
            layout: :sidebar,
            navigation_dialog_label: "Gallery navigation",
            data: { gallery: "shell" }
          ) do |shell|
            shell.brand { gallery_brand }
            shell.navigation { gallery_navigation }
            shell.main { div(data: { gallery: "main" }) { yield } }
          end
        end
      end
    end

    private

    def gallery_brand
      div(data: { gallery: "brand-row" }) do
        a(href: gallery_root_path, data: { gallery: "brand" }) do
          strong { "Nitro Kit" }
        end
        a(
          href: "https://github.com/mikker/nitro_kit/releases",
          target: "_blank",
          rel: "noopener",
          aria: { label: "Nitro Kit #{NitroKit::VERSION} — releases on GitHub" },
          data: { gallery: "brand-version" }
        ) do
          render NitroKit::Badge.new(
            "v#{NitroKit::VERSION}",
            id: "gallery-version-badge",
            size: :sm
          )
        end
      end
    end

    def gallery_navigation
      render NitroKit::AppNavigation.new(
        id: "gallery-navigation",
        label: "Gallery",
        data: {
          gallery: "navigation",
          controller: "gallery--navigation",
          action: "turbo:before-render@document->gallery--navigation#rememberScroll " \
            "turbo:render@document->gallery--navigation#sync",
          turbo_permanent: true
        }
      ) do |navigation|
        navigation.header do
          render NitroKit::CommandPalette.new(
            id: "gallery-filter",
            label: "Search gallery…",
            placeholder: "Search destinations…",
            data: { gallery: "filter" }
          ) do |palette|
            navigation_destinations.each do |destination|
              palette.destination(
                destination[:label],
                href: destination[:path],
                description: destination[:description]
              )
            end
          end
        end

        navigation.body do
          navigation_guides.each do |guide|
            navigation.item(
              guide[:label],
              href: guide[:path],
              icon: guide[:icon],
              current: request.path == guide[:path],
              data: { gallery_navigation_match: "exact:#{guide[:path]}" }
            )
          end

          Gallery::Catalog.collections.each do |collection|
            navigation.divider
            collection.categories.each do |category|
              navigation.section(
                label: section_label(collection, category),
                collapsible: true,
                expanded: section_expanded?(collection, category)
              ) do
                category.entries.each do |entry|
                  navigation.item(
                    entry.title,
                    href: entry_path(entry),
                    current: current_entry?(entry),
                    data: { gallery_navigation_match: navigation_match(entry) }
                  )
                end
              end
            end
          end
        end

        navigation.footer do
          div(data: { gallery: "theme-switcher" }) do
            render NitroKit::AppearancePicker.new(
              id: "gallery-appearance",
              label: "Appearance",
              label_visible: false
            )
          end
        end
      end
    end

    # Single-category collections read as one group; multi-category
    # collections read as their group names alone.
    def section_label(collection, category)
      collection.categories.one? ? collection.title : category.title
    end

    # Composition groups start collapsed; the group holding the current page
    # always starts open so navigation never lands somewhere invisible.
    def section_expanded?(collection, category)
      collection.kind != :composition || category.entries.any? { |entry| current_entry?(entry) }
    end

    def current_entry?(entry)
      request.path_parameters[:controller] == "gallery/#{entry.kind.to_s.pluralize}" &&
        request.path_parameters[:slug] == entry.slug
    end

    def entry_path(entry)
      Gallery::Catalog.path_for(entry, routes: self)
    end

    def navigation_match(entry)
      return "exact:#{entry_path(entry)}" unless entry.kind == :composition

      "prefix:/gallery/compositions/#{entry.slug}/"
    end

    def navigation_destinations
      guides = navigation_guides.map do |guide|
        { label: guide[:label], path: guide[:path], description: "Gallery" }
      end
      catalog = Gallery::Catalog.collections.flat_map do |collection|
        collection.categories.flat_map do |category|
          category.entries.map do |entry|
            {
              label: entry.title,
              path: entry_path(entry),
              description: "#{collection.title} · #{category.title}"
            }
          end
        end
      end

      guides + catalog
    end

    def navigation_guides
      [
        { label: "Introduction", path: gallery_root_path, icon: :house },
        { label: "Agent guide", path: gallery_agent_guide_path, icon: :bot },
        { label: "Human guide", path: gallery_guide_path, icon: :book_open }
      ]
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
