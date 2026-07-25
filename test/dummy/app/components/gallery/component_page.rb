module Gallery
  class ComponentPage < Page
    include Phlex::Rails::Helpers::FormWith

    private

    def page_template
      header(data: { gallery: "component-header" }) do
        h1 { entry.title }
        p { entry.description } if entry.description

        notes = Notes.new(source: source_note, api: api_note)
        render(notes) if notes.any?
      end

      component_template
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
