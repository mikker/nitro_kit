module Gallery
  # The plain-text rendering of the agent guide served at /llms.txt. Every line
  # is derived from the same sources the HTML page renders: Gallery::AgentGuide
  # for the prose, Gallery::AgentRules (and through it NitroKit::Component) for
  # the system rules, and Gallery::Catalog for the page index.
  module LlmsText
    module_function

    def call(origin: nil)
      [
        heading("Nitro Kit 2.0 — #{AgentGuide::TITLE}"),
        AgentGuide::INTRO,
        "Canonical HTML: #{url(origin, "/gallery/agent-guide")}",
        *AgentGuide::TOPICS.flat_map { |topic| topic_lines(topic) },
        subheading(AgentGuide::REFUSALS_TITLE),
        AgentGuide::REFUSALS_INTRO,
        *AgentGuide::QUESTIONS.flat_map { |question| question_lines(question) },
        subheading("System rules"),
        AgentRules::DESCRIPTION,
        *AgentRules.rules.map { |rule| "- #{rule}" },
        *index_lines(origin)
      ].join("\n\n") + "\n"
    end

    def topic_lines(topic)
      [ subheading(topic.title), topic.body, topic.points.map { |point| "- #{point}" }.join("\n") ]
    end

    def question_lines(question)
      [ "### #{question.question}", *question.answers ]
    end

    def index_lines(origin)
      Catalog.collections.map do |collection|
        entries = collection.entries.map do |entry|
          "- #{entry.title}: #{url(origin, Catalog.path_for(entry, routes: routes))}"
        end

        "#{subheading(collection.title)}\n\n#{collection.description}\n\n#{entries.join("\n")}"
      end
    end

    def heading(text) = "# #{text}"

    def subheading(text) = "## #{text}"

    def routes = Rails.application.routes.url_helpers

    def url(origin, path) = origin ? "#{origin}#{path}" : path
  end
end
