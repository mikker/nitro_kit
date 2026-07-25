module Gallery
  class Home < Page
    private

    def page_template
      header(data: { gallery: "page-header" }) do
        p(data: { gallery: "eyebrow" }) { "Nitro Kit for Rails" }
        h1 { "Nitro Kit" }
        p do
          "Nitro Kit is a purposefully modest set of Phlex UI components for Rails, " \
            "composed directly in Ruby."
        end
      end

      div(data: { gallery: "introduction" }) do
        section(aria: { labelledby: "nitro-kit-idea" }) do
          h2(id: "nitro-kit-idea") { "The idea" }
          p do
            "Nitro Kit owns the reusable parts: component markup, the CSS, and a little " \
              "behavior where the browser needs help. Your app themes it with CSS custom " \
              "properties, composes or subclasses the pieces, and keeps every product " \
              "decision to itself."
          end
        end

        section(aria: { labelledby: "nitro-kit-rules" }) do
          h2(id: "nitro-kit-rules") { "The rules" }
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
              "Build up. Components combine into blocks and whole application layouts. Keep " \
                "it simple and go fast."
            end
          end
        end
      end
    end
  end
end
