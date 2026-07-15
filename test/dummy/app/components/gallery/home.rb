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
        Gallery::Catalog.collections.each do |collection|
          render_collection(collection)
        end
      end
    end

    def render_collection(collection)
      section(data: { gallery: "index-group", gallery_kind: collection.kind }) do
        header do
          h2 { collection.title }
          p { collection.description }
        end

        if collection.kind == :component
          render_entries(collection.entries)
        else
          div(data: { gallery: "index-categories" }) do
            collection.categories.each { |category| render_category(category) }
          end
        end
      end
    end

    def render_category(category)
      section(
        aria: { labelledby: "gallery-category-#{category.slug}" },
        data: {
          gallery: "index-category",
          gallery_category: category.slug
        }
      ) do
        header do
          h3(id: "gallery-category-#{category.slug}") { category.title }
          p { category.description } if category.description
        end
        render_entries(category.entries)
      end
    end

    def render_entries(entries)
      ul do
        entries.each do |entry|
          li do
            a(href: entry_path(entry)) { entry.title }
            small { entry.description } if entry.description
          end
        end
      end
    end
  end
end
