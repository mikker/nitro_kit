module Gallery
  class Home < Page
    private

    def page_template
      header(data: { gallery: "page-header" }) do
        p(data: { gallery: "eyebrow" }) { "Nitro Kit 2.0" }
        h1 { "Component gallery" }
        p do
          "Direct-Phlex components, blocks, and application flows rendered with Nitro Kit CSS."
        end
      end

      div(data: { gallery: "index" }) do
        Gallery::Catalog.navigation_groups.each do |group|
          render_group(group)
        end
      end
    end

    def render_group(group)
      section(data: { gallery: "index-group", gallery_kind: group.kind }) do
        header do
          h2 { group.title }
          p { group.description }
        end

        if group.entries.any?
          ul do
            group.entries.each do |entry|
              li do
                a(href: entry_path(entry)) { entry.title }
                small { entry.description } if entry.description
              end
            end
          end
        else
          p(data: { gallery: "empty" }) { "Pages will appear here as the 2.0 catalog is migrated." }
        end
      end
    end
  end
end
