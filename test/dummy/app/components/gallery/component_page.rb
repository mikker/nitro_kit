module Gallery
  class ComponentPage < Page
    include Phlex::Rails::Helpers::FormWith

    private

    def page_template
      render NitroKit::Flex.new(dir: :col, gap: 2, align: :stretch) do
        render NitroKit::PageHeader.new(
          title: entry.title,
          description: entry.description,
          data: { gallery: "component-header" }
        )
        notes = Notes.new(source: source_note, api: api_note)
        render(notes) if notes.any?
      end

      component_template
      reference_sections
    end

    # Examples are the payload; the reference sections make a single fetched
    # page self-contained for an agent. They render outside every example
    # canvas on purpose.
    def reference_sections
      div(data: { gallery: "reference-sections" }) do
        render ComponentContract.new(Gallery::Contracts.for_entry(entry))
        render PatternNotes.new(Gallery::Catalog.patterns_for(entry))
        render AgentRules.new
      end
    end

    def component_template
      raise NotImplementedError, "#{self.class.name} must implement #component_template"
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

    def sample(label, slug:, description: nil, &block)
      render(Sample.new(slug:, label:, description:), &block)
    end
  end
end
