module Gallery
  class UploadPreview < Phlex::HTML
    include Phlex::Rails::Helpers::FormWith
    include Phlex::Rails::Helpers::Routes
    include Phlex::Rails::Helpers::TurboFrameTag

    MODES = %w[direct multipart shared avatar compact].freeze

    def initialize(mode:, receipt: nil, error: nil)
      raise ArgumentError, "Unknown upload mode" unless MODES.include?(mode)

      @mode = mode
      @receipt = receipt
      @error = error
    end

    def view_template
      turbo_frame_tag("gallery-dropzone-#{@mode}-preview") do
        render NitroKit::Flex.new(dir: :col, gap: 4, align: :stretch) do
          if @receipt
            render NitroKit::Alert.new(
              title: "Processed #{@receipt.size} #{'file'.pluralize(@receipt.size)}",
              description: @receipt.map { |file| "#{file[:name]} (#{file[:bytes]} bytes)" }.join(", "),
              variant: :success,
              live: :polite
            )
          end
          render NitroKit::Alert.new(title: @error, variant: :destructive, live: :assertive) if @error
          send("#{@mode}_form")
        end
      end
    end

    private

    def avatar_form
      form_with(scope: :upload, url: gallery_upload_submissions_path(mode: "avatar"), builder: NitroKit::FormBuilder) do |form|
        form.group do
          form.dropzone(
            :files,
            id: "gallery-dropzone-avatar",
            presentation: :avatar,
            label: "Change profile photo",
            description: "PNG or JPG, up to 2 MB.",
            accept: "image/png,image/jpeg",
            max_bytes: 2 * 1024 * 1024,
            required: true
          )
          form.submit("Save photo")
        end
      end
    end

    def compact_form
      form_with(scope: :upload, url: gallery_upload_submissions_path(mode: "compact"), builder: NitroKit::FormBuilder) do |form|
        form.group do
          form.dropzone(
            :files,
            id: "gallery-dropzone-compact",
            presentation: :compact,
            label: "Attach receipt",
            description: "PDF, PNG or JPG, up to 2 MB.",
            accept: "application/pdf,image/png,image/jpeg",
            max_bytes: 2 * 1024 * 1024,
            required: true
          )
          form.submit("Save receipt")
        end
      end
    end

    def direct_form
      form_with(
        scope: :upload,
        url: gallery_upload_submissions_path(mode: "direct"),
        builder: NitroKit::FormBuilder,
        id: "gallery-dropzone-direct-form"
      ) do |form|
        form.group do
          form.dropzone(
            :files,
            id: "gallery-dropzone-direct",
            label: "Upload supporting evidence",
            description: "Text or PNG · 2 files · 2 MB each.",
            multiple: true,
            accept: "text/plain,image/png",
            max_files: 2,
            max_bytes: 2 * 1024 * 1024,
            required: true
          )
          form.submit("Save direct upload", id: "gallery-dropzone-direct-submit")
        end
      end
    end

    def multipart_form
      form_with(
        scope: :upload,
        url: gallery_upload_submissions_path(mode: "multipart"),
        builder: NitroKit::FormBuilder,
        id: "gallery-dropzone-multipart-form"
      ) do |form|
        form.group do
          form.dropzone(
            :files,
            id: "gallery-dropzone-multipart",
            label: "Add source files",
            description: "Choose up to three text or PNG files.",
            direct_upload: false,
            multiple: true,
            accept: "text/plain,image/png",
            max_files: 3,
            max_bytes: 1024 * 1024
          )
          form.submit("Submit files", id: "gallery-dropzone-multipart-submit")
        end
      end
    end

    def shared_form
      form_with(
        scope: :upload,
        url: gallery_upload_submissions_path(mode: "shared"),
        builder: NitroKit::FormBuilder,
        id: "gallery-dropzone-shared-form"
      ) do |form|
        form.group do
          form.dropzone(
            :primary_file,
            id: "gallery-dropzone-shared-primary",
            label: "Upload primary evidence",
            accept: "text/plain"
          )
          form.dropzone(
            :secondary_file,
            id: "gallery-dropzone-shared-secondary",
            label: "Upload secondary evidence",
            accept: "text/plain"
          )
          form.submit("Save both uploads", id: "gallery-dropzone-shared-submit")
          form.button(
            "Unavailable action",
            id: "gallery-dropzone-shared-disabled-submit",
            type: :submit,
            disabled: true
          )
        end
      end
    end
  end
end
