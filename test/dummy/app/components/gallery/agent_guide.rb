module Gallery
  # The machine-audience entry point. Its prose lives in TOPICS and QUESTIONS so
  # the HTML page and the plain-text /llms.txt render from one source; the system
  # rules come from Gallery::AgentRules, which every component page also renders.
  class AgentGuide < Phlex::HTML
    include Phlex::Rails::Helpers::Routes

    Topic = ::Data.define(:slug, :title, :body, :points)
    Question = ::Data.define(:slug, :question, :answers)

    TITLE = "Agent guide".freeze
    INTRO = "Everything a coding agent needs to compose Nitro Kit correctly. The gallery " \
      "enumerates and proves the system; nitrokit.dev teaches it to humans.".freeze

    TOPICS = [
      Topic.new(
        slug: "composition",
        title: "The composition model",
        body: "A Nitro component is a Phlex class. You render it directly, and that is the " \
          "entire public API. There is no helper layer, no template registry, and no generator " \
          "that copies component source into an application.",
        points: [
          "Render a component with `render NitroKit::Button.new(\"Save\", variant: :primary)`. " \
            "Arguments are the contract; a wrong keyword or an unknown enumerated value raises " \
            "`ArgumentError` at render time.",
          "Compound components yield themselves: `render NitroKit::Card.new do |card| " \
            "card.title(\"Plan\"); card.body { ... } end`. The compound methods are the " \
            "component's published anatomy, and the blocks take ordinary Phlex content.",
          "Rails forms use `form_with(model: record, builder: NitroKit::FormBuilder)`. Rails keeps " \
            "naming, ids, values, CSRF, multipart, and ActiveModel errors; Nitro renders the controls.",
          "Layout is `Flex(dir:, gap:, align:, justify:, wrap:)` and `Grid(cols:, gap:)`. Responsive " \
            "properties take a required base value plus fixed `sm md lg xl 2xl` overrides.",
          "Extend by wrapping Nitro components inside your own Phlex classes. Subclassing is allowed " \
            "for a narrow fixed vocabulary, but private methods are not an API.",
          "Theme with the documented `--nk-*` custom properties, globally or scoped to a subtree. " \
            "Never edit the generated `nitro_kit.css`, and never depend on private `--_nk-*` variables."
        ]
      ),
      Topic.new(
        slug: "pages",
        title: "Every component page is self-contained",
        body: "Fetch one component page and you have enough to compose that component correctly. " \
          "The reference sections below the examples are rendered from one source into every page, " \
          "so nothing requires reading a second page.",
        points: [
          "`[data-gallery-reference=\"contract\"]` carries that component's own options, slots, and " \
            "closed vocabularies.",
          "`[data-gallery-reference=\"patterns\"]` inlines the application conventions that apply to " \
            "the component, such as queryable collections on Table or destructive actions on Dialog.",
          "`[data-gallery-reference=\"system-rules\"]` repeats the rules at the end of this page, " \
            "identically, on every component page.",
          "Every example pairs a Preview tab, a Responsive tab, and a Code tab. The Code tab holds the " \
            "executable Ruby that rendered the preview above it, extracted from the source, so it " \
            "cannot drift.",
          "Component pages live at `/gallery/components/:slug`. Compositions live at " \
            "`/gallery/compositions/:slug(/:state)` and are executable whole-application tests: the " \
            "same components under real states, including empty, loading, error, dense, and mobile.",
          "Select on `data-nk`, component-qualified `data-slot`, `data-variant`, `data-size`, and " \
            "`data-state`. Gallery chrome uses `data-gallery`. Nothing in the system uses classes."
        ]
      )
    ].freeze

    REFUSALS_TITLE = "Why the system refuses things".freeze
    REFUSALS_INTRO = "Nitro Kit says no to a few things an agent will otherwise try. The reasons " \
      "are here so you stop fighting the API and reach for the supported path instead.".freeze

    QUESTIONS = [
      Question.new(
        slug: "no-class",
        question: "Why is there no class: prop?",
        answers: [
          "Because it is a second styling API in disguise. The moment components accept arbitrary " \
            "classes, every internal class name becomes something an application depends on, and " \
            "every upgrade can quietly break its styling.",
          "Components render classless, self-describing markup, and customization flows through the " \
            "documented `--nk-*` custom properties. When an external script or widget genuinely needs " \
            "a hook there is `desperately_need_a_class:`, which emits both the class and " \
            "`data-nk-escape=\"class\"` and is named that way so you think twice. `class:` and " \
            "`style:` are rejected everywhere, including inside `html:`."
        ]
      ),
      Question.new(
        slug: "explicit-keywords",
        question: "Why is every option an explicit keyword?",
        answers: [
          "So a mistake tells you instead of rendering something slightly wrong. No component takes a " \
            "catch-all `**options`, so a misspelled keyword raises `ArgumentError` rather than leaking " \
            "into the HTML, and an unknown enumerated value raises with the accepted set in the message.",
          "Do not route around this. If an option you want does not exist, compose the component inside " \
            "your own Phlex class rather than trying to pass extra attributes through."
        ]
      ),
      Question.new(
        slug: "why-phlex",
        question: "Why Phlex rather than templates?",
        answers: [
          "Because components are Ruby, and Ruby is good at this. A Phlex component is a plain class " \
            "with a constructor and a `view_template`, composed like any other object. There is no " \
            "partial whose locals you have to guess at and no helper soup.",
          "It also lets a component check its own inputs. The constructor is the contract, and the " \
            "contract is enforced where the component is rendered."
        ]
      ),
      Question.new(
        slug: "why-not-html",
        question: "Why not just write HTML?",
        answers: [
          "You still get HTML, and it stays native: real buttons, real forms, real `details`/`summary`, " \
            "native dialogs, and Popover menus. The question is only what you author against.",
          "Raw HTML is a wide-open API: any attribute, any structure, any typo. A component kit needs a " \
            "narrower contract so markup, accessibility, and styling can be promised to agree. Named " \
            "slots and content blocks still accept ordinary Phlex content."
        ]
      ),
      Question.new(
        slug: "why-not-tailwind",
        question: "Why not Tailwind?",
        answers: [
          "Nitro Kit ships static plain CSS. There is no Tailwind build requirement and no runtime " \
            "dependency, so the components render the same in every application.",
          "An application may still use Tailwind, and an optional Tailwind v4 adapter maps Nitro's " \
            "tokens into Tailwind theme variables so utilities and components share values. Do not put " \
            "utility classes inside the components; that is what the components are for."
        ]
      ),
      Question.new(
        slug: "ownership",
        question: "What does Nitro Kit own, and what does the application own?",
        answers: [
          "Nitro Kit owns the reusable parts: component markup, CSS, and a little behavior where the " \
            "browser needs help. The application owns data, routes, authorization, business rules, and " \
            "how the pieces compose into product.",
          "The line matters in practice. `AppShell` gives you responsive chrome but you decide the " \
            "navigation. `Table` renders sortable headers and `aria-sort` but you supply the URLs and " \
            "the sort policy. Do not push product decisions into a component."
        ]
      ),
      Question.new(
        slug: "javascript",
        question: "How much JavaScript is there?",
        answers: [
          "As little as possible. Accordions are `details`/`summary`, dialogs use native commands, " \
            "dropdowns use Popover, and tooltips use CSS hover and focus.",
          "What remains is a handful of small Stimulus controllers for the gaps, such as menu keyboard " \
            "navigation and Active Storage uploads. They are progressive, they clean up in `disconnect`, " \
            "and they behave through Turbo Drive, Frames, Streams, and morphs. Do not add a controller " \
            "to reimplement behavior a component already has."
        ]
      ),
      Question.new(
        slug: "rails-and-turbo",
        question: "Does it work with Rails forms and Turbo?",
        answers: [
          "Yes, that is the home turf. Use `form_with` with `NitroKit::FormBuilder` and keep everything " \
            "Rails gives you: naming, ids, model values, CSRF, multipart forms, and real ActiveModel " \
            "errors wired to the controls.",
          "Turbo Frames and Streams use the normal Rails helpers from Phlex. Active Storage direct " \
            "uploads work through `Dropzone`, with plain form submission as the no-JavaScript fallback. " \
            "Nitro Kit does not wrap Rails; it stays out of the way where Rails is already good."
        ]
      )
    ].freeze

    def view_template
      div(data: { gallery: "page", gallery_page: "agent-guide" }) do
        header(data: { gallery: "page-header" }) do
          p(data: { gallery: "eyebrow" }) { "Nitro Kit 2.0" }
          h1 { TITLE }
          p { INTRO }
          p do
            plain "The same content is served as plain text at "
            a(href: "/llms.txt") { "/llms.txt" }
            plain "."
          end
        end

        div(data: { gallery: "guide" }) do
          TOPICS.each { |topic| render_topic(topic) }
          render_refusals
        end

        div(data: { gallery: "reference-sections" }) { render AgentRules.new }
      end
    end

    private

    def render_topic(topic)
      section(aria: { labelledby: topic.slug }, data: { gallery: "guide-topic" }) do
        h2(id: topic.slug) { topic.title }
        p { topic.body }
        ul { topic.points.each { |point| li { render MarkdownText.new(point) } } }
      end
    end

    def render_refusals
      section(aria: { labelledby: "refusals" }, data: { gallery: "guide-topic" }) do
        h2(id: "refusals") { REFUSALS_TITLE }
        p { REFUSALS_INTRO }

        QUESTIONS.each do |question|
          div(data: { gallery: "guide-question", gallery_question: question.slug }) do
            h3(id: question.slug) { question.question }
            question.answers.each { |answer| p { render MarkdownText.new(answer) } }
          end
        end
      end
    end
  end
end
