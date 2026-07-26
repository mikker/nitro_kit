module Gallery
  # How a person reads this gallery. Teaching, guides, and the theme Customizer
  # live on the documentation site; this page only explains the test bed.
  class HumanGuide < Phlex::HTML
    include Phlex::Rails::Helpers::Routes

    SITE_URL = "https://nitrokit.dev".freeze
    TITLE = "Human guide".freeze
    INTRO = "The gallery is the exhaustive test bed: every component, every meaningful state, " \
      "proven by the same suite that ships the gem. This page explains how to read it. Guides, " \
      "tutorials, the theme Customizer, and Nitro Kit Pro live on the documentation site.".freeze

    def view_template
      div(data: { gallery: "page", gallery_page: "guide" }) do
        header(data: { gallery: "page-header" }) do
          p(data: { gallery: "eyebrow" }) { "Nitro Kit 2.0" }
          h1 { TITLE }
          p { INTRO }
        end

        div(data: { gallery: "guide" }) do
          reading_a_component_page
          compositions
          theming
          elsewhere
        end
      end
    end

    private

    def reading_a_component_page
      topic("component-pages", "Reading a component page") do
        p do
          plain "Every component has one page, reached from the sidebar. It opens with the "
          plain "component's purpose, then works through examples: the plain cases first, then "
          plain "variants, sizes, states, long content, disabled and error cases, and narrow widths."
        end
        ul do
          li { "Preview shows the rendered example in an isolated canvas." }
          li do
            plain "Responsive shows the same example at fixed device widths, so you can see how it "
            plain "reflows without resizing your window."
          end
          li do
            plain "Code shows the Ruby that rendered the preview. It is extracted from the executable "
            plain "source, not retyped, so it is always copyable and always current."
          end
          li do
            plain "The appearance picker in the sidebar switches light, dark, and system. Every "
            plain "example is expected to hold up in all three."
          end
        end
        p do
          plain "Below the examples each page repeats three reference sections: the component's "
          plain "contract, the application patterns it belongs to, and the system rules. They are "
          plain "there so a coding agent can fetch a single page and compose correctly. People can "
          plain "read them as the precise version of the prose on "
          a(href: SITE_URL) { "nitrokit.dev" }
          plain "."
        end
      end
    end

    def compositions
      topic("compositions", "What the compositions are") do
        p do
          plain "The Compositions section of the sidebar is not a showcase. Each entry is an "
          plain "executable composition test: a realistic screen — sign in, billing, a settings "
          plain "page, a whole application shell — assembled only from Nitro components and run by "
          plain "the test suite."
        end
        p do
          plain "Most compositions have several states listed in their URL, such as empty, loading, "
          plain "error, dense, and mobile. They exist to prove the components survive real pressure "
          plain "together, and they double as the most honest example of how much application code "
          plain "a screen actually takes."
        end
      end
    end

    def theming
      topic("theming", "Theming basics") do
        p do
          plain "Nitro Kit owns component CSS and its default light and dark themes. Applications "
          plain "customize by overriding documented "
          code { "--nk-*" }
          plain " custom properties: semantic colors, typography, spacing, radii, borders, focus "
          plain "geometry, shadows, motion, control heights, content widths, and shell chrome."
        end
        ul do
          li do
            plain "Load "
            code { "nitro_kit" }
            plain " first and your own stylesheet after it. Nitro's selectors sit inside "
            code { ":where()" }
            plain " in named cascade layers, so an ordinary rule wins without "
            code { "!important" }
            plain "."
          end
          li do
            plain "Override globally on "
            code { ":root" }
            plain ", or scope a subtree by putting the variables on a wrapper element. Nitro "
            plain "descendants inherit them."
          end
          li do
            plain "Color tokens need three selectors: light, a "
            code { "prefers-color-scheme" }
            plain " fallback for visitors without JavaScript, and explicit "
            code { "[data-theme=\"dark\"]" }
            plain "."
          end
          li do
            plain "Variables beginning with "
            code { "--_nk-" }
            plain " are private component mechanics. Never override them, and never edit the "
            plain "generated stylesheet."
          end
        end
        p do
          plain "The interactive theme Customizer — pick an accent, neutral, radius, density, font, "
          plain "and shell, then copy the CSS — lives on the documentation site at "
          a(href: "#{SITE_URL}/customize") { "nitrokit.dev/customize" }
          plain "."
        end
      end
    end

    def elsewhere
      topic("elsewhere", "Where to go next") do
        ul do
          li do
            a(href: SITE_URL) { "nitrokit.dev" }
            plain " — installation, guides, and the component documentation written for people."
          end
          li do
            a(href: "#{SITE_URL}/customize") { "nitrokit.dev/customize" }
            plain " — the theme Customizer and its copyable exports."
          end
          li do
            a(href: "#{SITE_URL}/pro") { "nitrokit.dev/pro" }
            plain " — Nitro Kit Pro: the application blocks, flows, and templates catalog."
          end
          li do
            plain "The "
            a(href: gallery_agent_guide_path) { "agent guide" }
            plain " and "
            a(href: "/llms.txt") { "/llms.txt" }
            plain " — the same system, written for coding agents."
          end
        end
      end
    end

    def topic(slug, title, &block)
      section(aria: { labelledby: slug }, data: { gallery: "guide-topic" }) do
        h2(id: slug) { title }
        yield
      end
    end
  end
end
