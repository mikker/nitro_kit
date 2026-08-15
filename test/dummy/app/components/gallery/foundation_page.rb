module Gallery
  class FoundationPage < Page
    private

    def page_template
      render NitroKit::Flex.new(dir: :col, gap: 2, align: :stretch) do
        render NitroKit::PageHeader.new(
          title: entry.title,
          description: entry.description,
          data: { gallery: "foundation-header" }
        )
        notes = Notes.new(source: source_note, api: api_note)
        render(notes) if notes.any?
      end

      foundation_template
      render AgentRules.new
    end

    def foundation_template
      raise NotImplementedError, "#{self.class.name} must implement #foundation_template"
    end

    def source_note
      nil
    end

    def api_note
      nil
    end

    def example_section(title, slug:, description: nil, &block)
      render(Section.new(slug:, title:, description:), &block)
    end

    def example(
      title,
      slug:,
      description: nil,
      mode: :constrained,
      layout: :stack,
      density: :comfortable,
      scroll: false,
      source: nil,
      api: nil,
      code: nil,
      &block
    )
      render_example(
        slug:,
        title:,
        description:,
        mode:,
        layout:,
        density:,
        scroll:,
        source:,
        api:,
        code:,
        &block
      )
    end
  end
end
