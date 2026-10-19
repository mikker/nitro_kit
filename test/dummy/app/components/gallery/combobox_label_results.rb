module Gallery
  class ComboboxLabelResults < Primitive
    include Phlex::Rails::Helpers::Routes

    def initialize(combobox:, query:, labels:)
      @combobox = combobox
      @query = query.to_s.strip
      @labels = labels
    end

    def view_template
      render NitroKit::Combobox::Results.new(id: @combobox) do |results|
        @labels.each do |label|
          results.option(label.name, value: label.id, description: label.description)
        end

        if @query.present? && !ComboboxLabels.exact(@query)
          results.action(
            "Create label “#{@query}”",
            url: gallery_combobox_labels_path(combobox: @combobox),
            params: { "label[name]" => @query }
          )
        end
      end
    end
  end
end
