module Gallery
  class Home < Page
    private

    def page_template
      header(data: { gallery: "page-header" }) do
        p(data: { gallery: "eyebrow" }) { "Nitro Kit for Rails" }
        h1 { "Nitro Kit" }
        p do
          "Nitro Kit is a purposefully modest set of Phlex UI components for Rails, " \
            "composed directly in Ruby. This is its gallery: the exhaustive test bed and " \
            "the reference a coding agent reads."
        end
      end

      div(data: { gallery: "introduction" }) do
        section(aria: { labelledby: "nitro-kit-gallery" }) do
          h2(id: "nitro-kit-gallery") { "What this is" }
          p do
            "Every gem-owned component appears here with every meaningful permutation, state, " \
              "and edge, driven by the same catalog the test suite runs against. It is boring " \
              "on purpose: complete beats curated, because this is what proves the system works."
          end
          p do
            plain "Human teaching — installation, guides, the theme Customizer, and Nitro Kit Pro — "
            plain "lives on the documentation site at "
            a(href: HumanGuide::SITE_URL) { "nitrokit.dev" }
            plain ". The gallery enumerates and proves; the site curates and teaches."
          end
        end

        section(aria: { labelledby: "nitro-kit-surfaces" }) do
          h2(id: "nitro-kit-surfaces") { "Who each surface serves" }
          ul do
            li do
              plain "The "
              a(href: gallery_agent_guide_path) { "agent guide" }
              plain " is the machine entry point: the composition model, the system rules, and why "
              plain "the API refuses what it refuses. It is also served as text at "
              a(href: "/llms.txt") { "/llms.txt" }
              plain "."
            end
            li do
              plain "The "
              a(href: gallery_guide_path) { "human guide" }
              plain " explains how to read a component page, what the compositions are, and how "
              plain "theming works."
            end
            li do
              plain "Component pages enumerate one component and are self-contained: examples with "
              plain "copyable Ruby, then that component's contract, its patterns, and the system rules."
            end
            li do
              plain "Compositions are executable composition tests — realistic screens built only "
              plain "from Nitro components, exercised across their real states."
            end
          end
        end

        section(aria: { labelledby: "nitro-kit-idea" }) do
          h2(id: "nitro-kit-idea") { "The idea" }
          p do
            "Nitro Kit owns the reusable parts: component markup, the CSS, and a little " \
              "behavior where the browser needs help. Your app themes it with CSS custom " \
              "properties, composes or subclasses the pieces, and keeps every product " \
              "decision to itself."
          end
          ul do
            li do
              "Compose in Ruby. APIs are explicit and validated, so a wrong option tells " \
                "you instead of rendering something odd."
            end
            li do
              "Prefer the platform. Rails, native HTML and CSS, and browser features come " \
                "before custom JavaScript."
            end
            li do
              "Keep ownership clear. Nitro Kit owns the reusable UI; your app owns its data, " \
                "routes, authorization, and decisions."
            end
            li do
              "Build up. Components combine into sections and whole application layouts. Keep " \
                "it simple and go fast."
            end
          end
        end
      end
    end
  end
end
