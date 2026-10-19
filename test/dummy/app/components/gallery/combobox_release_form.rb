module Gallery
  class ComboboxReleaseForm < Phlex::HTML
    include Phlex::Rails::Helpers::FormWith
    include Phlex::Rails::Helpers::Routes
    include Phlex::Rails::Helpers::TurboFrameTag

    def initialize(release: ComboboxRelease.new, saved: nil)
      @release = release
      @saved = saved
    end

    def view_template
      turbo_frame_tag("gallery-combobox-release-frame") do
        render NitroKit::Flex.new(dir: :col, gap: 4, align: :stretch) do
          if @saved
            render NitroKit::Alert.new(
              title: "Saved “#{@saved.title}”",
              description: "Labels: #{@saved.labels.map(&:name).to_sentence.presence || "none"}",
              variant: :success,
              live: :polite
            )
          end
          release_form
        end
      end
    end

    private

    def release_form
      form_with(
        model: @release,
        scope: :release,
        url: gallery_combobox_release_path,
        builder: NitroKit::FormBuilder,
        id: "gallery-combobox-release-form"
      ) do |form|
        form.group do
          form.field(:title, id: "gallery-combobox-release-title")
          render NitroKit::Combobox.new(
            id: "gallery-combobox-release-labels",
            name: form.field_name(:label_ids, multiple: true),
            label: "Labels",
            src: gallery_combobox_labels_path(combobox: "gallery-combobox-release-labels"),
            multiple: true,
            selected: @release.labels.map { |label| { label: label.name, value: label.id } },
            placeholder: "Search or create labels"
          )
          form.submit("Save release", id: "gallery-combobox-release-save")
        end
      end
    end
  end
end
