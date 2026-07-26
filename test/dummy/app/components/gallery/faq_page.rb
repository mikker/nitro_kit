module Gallery
  class FaqPage < Phlex::HTML
    include Phlex::Rails::Helpers::Routes

    def view_template
      div(data: { gallery: "page", gallery_page: "faq" }) do
        header(data: { gallery: "page-header" }) do
          p(data: { gallery: "eyebrow" }) { "Nitro Kit 2.0" }
          h1 { "Good questions" }
          p { "Nitro Kit does a few things differently, so here are the reasons, in plain terms." }
        end

        div(data: { gallery: "faq" }) do
          why_phlex
          why_not_html
          why_no_class
          how_to_change_stuff
          why_not_tailwind
          who_owns_what
          how_much_javascript
          rails_forms_and_turbo
        end
      end
    end

    private

    def why_phlex
      faq("why-phlex", "Why Phlex?") do
        p do
          plain "Because components are Ruby, and Ruby is good at this. A Phlex component is a "
          plain "plain class with a constructor and a "
          code { "view_template" }
          plain ". You compose it like any other object. No template registry, no helper soup, "
          plain "no wondering where a partial's locals come from."
        end
        p do
          plain "It also lets the components check their own inputs. Every option is an explicit "
          plain "keyword with a closed set of values, and a wrong one raises with the accepted "
          plain "vocabulary in the message. That beats rendering something slightly off and "
          plain "finding out in production."
        end
      end
    end

    def why_not_html
      faq("why-not-html", "Why not HTML?") do
        p do
          plain "You still get HTML. Phlex renders ordinary HTML, and it stays native: real "
          plain "buttons, real forms, real "
          code { "details" }
          plain "/"
          code { "summary" }
          plain ". The question is what you author against."
        end
        p do
          plain "Raw HTML is a wide open API. Any attribute, any structure, any typo. That's fine "
          plain "for a page you own, but a component kit needs a narrower contract so it can promise "
          plain "the markup, accessibility, and styling all agree. Ruby constructors give you that "
          plain "contract. Named slots and blocks still accept ordinary Phlex content."
        end
      end
    end

    def why_no_class
      faq("why-no-class", "Why is there no class: prop?") do
        p do
          plain "Because it's a second styling API in disguise. The moment components accept "
          plain "arbitrary classes, every internal class name becomes something your app can depend "
          plain "on, and every Nitro Kit upgrade can quietly break your styling. We'd rather not do "
          plain "that to you."
        end
        p do
          plain "Instead, components render classless, self-describing markup and customization "
          plain "flows through CSS custom properties. If an external script or widget genuinely "
          plain "needs a class hook, there's "
          code { "desperately_need_a_class:" }
          plain ". It works, marks itself in the markup, and is named that way so you'll think twice."
        end
      end
    end

    def how_to_change_stuff
      faq("how-to-change-stuff", "How do I change stuff?") do
        p do
          plain "Start with the "
          a(href: gallery_customize_path) { "configurator" }
          plain ". Pick accent, neutral, radius, density, font, and shell layout, see the system "
          plain "update live, then copy the deterministic CSS and AppShell composition into your app."
        end
        p do
          plain "Past that, theming is the documented "
          code { "--nk-*" }
          plain " custom properties. Override them globally or scope them to part of your app. For "
          plain "structural changes, wrap and compose Nitro components in your own, or subclass one "
          plain "when you need a small, fixed vocabulary such as a SaveButton that's always primary."
        end
      end
    end

    def why_not_tailwind
      faq("why-not-tailwind", "Why not Tailwind?") do
        p do
          plain "Nitro Kit ships static, plain CSS. There is no Tailwind build requirement or "
          plain "runtime dependency, and the components work the same in every app."
        end
        p do
          plain "Your app can absolutely still use Tailwind. An optional Tailwind v4 adapter maps "
          plain "Nitro Kit's tokens into Tailwind theme variables, so utilities and components can "
          plain "share the same values. What you won't need is utility classes inside the components "
          plain "themselves. That's the point of the components."
        end
      end
    end

    def who_owns_what
      faq("who-owns-what", "What does Nitro Kit own, and what do I own?") do
        p do
          plain "Nitro Kit owns the reusable parts: component markup, CSS, and a little behavior "
          plain "where the browser needs help. Your app owns everything that makes it your app: data, "
          plain "routes, authorization, business rules, and how the pieces compose into product."
        end
        p do
          plain "The line matters in practice. AppShell gives you responsive chrome, but you decide "
          plain "the navigation. Table renders sortable headers and "
          code { "aria-sort" }
          plain ", but you supply the URLs and sort policy. Nitro Kit doesn't want your product decisions."
        end
      end
    end

    def how_much_javascript
      faq("how-much-javascript", "How much JavaScript is in it?") do
        p do
          plain "As little as we could get away with. Native HTML and CSS come first: accordions are "
          code { "details" }
          plain "/"
          code { "summary" }
          plain ", dialogs use native commands, dropdowns use Popover, and tooltips use CSS hover "
          plain "and focus."
        end
        p do
          plain "What remains is a handful of small Stimulus controllers for the gaps, such as menu "
          plain "keyboard navigation and Active Storage uploads. They're progressive, clean up after "
          plain "themselves, and behave through Turbo Drive, Frames, Streams, and morphs."
        end
      end
    end

    def rails_forms_and_turbo
      faq("rails-forms-and-turbo", "Does it work with Rails forms and Turbo?") do
        p do
          plain "Yes, that's the home turf. Use "
          code { "form_with" }
          plain " with NitroKit::FormBuilder and keep everything Rails gives you: naming, IDs, model "
          plain "values, CSRF, multipart forms, and real ActiveModel errors wired to the controls."
        end
        p do
          plain "Turbo Frames and Streams use the normal Rails helpers from Phlex. Active Storage "
          plain "direct uploads work through Dropzone, with plain form submission as the no-JavaScript "
          plain "fallback. Nitro Kit doesn't wrap Rails. It stays out of the way where Rails is already good."
        end
      end
    end

    def faq(id, question, &answer)
      section(aria: { labelledby: id }, data: { gallery: "faq-entry" }) do
        h2(id:) { question }
        div(data: { gallery: "faq-answer" }, &answer)
      end
    end
  end
end
