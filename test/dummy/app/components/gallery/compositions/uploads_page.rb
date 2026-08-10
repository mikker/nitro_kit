module Gallery
  module Compositions
    class UploadsPage < ScenarioPage
      include Phlex::Rails::Helpers::FormWith

      private

      def render_scenario
        workspace_surface do
          render_header
          render_upload_form
          render_upload_records
        end
      end

      def render_header
        render NitroKit::PageHeader.new(
          title: upload_title,
          description: state_description,
          id: "gallery-uploads-header"
        ) do |header|
          header.actions(
            NitroKit::ButtonGroup.new(id: "gallery-uploads-header-actions", label: "Upload navigation")
          ) do |actions|
            actions.button("Import history", href: "#import-history", icon: :history)
          end
        end
      end

      def render_upload_form
        submission = upload_submission
        disabled = state == "uploading"
        multiple = state.in?(%w[uploading multiple])

        render NitroKit::SettingsSection.new(
          title: multiple ? "New multi-file import" : "New import",
          description: "Choose the source files and where their records belong. Files are scanned before processing begins.",
          id: "gallery-uploads-settings-section"
        ) do |section|
          render_upload_status(section)
          section.form do
            form_with(
              model: submission,
              url: "#upload-submissions",
              builder: NitroKit::FormBuilder,
              id: "gallery-uploads-form"
            ) do |form|
              form.group do
                render_upload_file_control(form, multiple:, disabled:)
                form.field(
                  :destination,
                  as: :select,
                  label: "Destination",
                  options: Gallery::Forms::UploadSubmission::DESTINATIONS.map { |destination| [ destination.humanize, destination ] },
                  prompt: "Choose a destination",
                  required: true,
                  disabled:
                )
                form.field(:note, as: :textarea, label: "Import note", description: "Optional context for workspace audit history.", disabled:, maxlength: 240)
                form.field(
                  :overwrite,
                  as: :checkbox,
                  label: "Replace records with matching external IDs",
                  description: "Available only where the destination permits replacement.",
                  disabled:
                )
                render NitroKit::Toolbar.new(id: "gallery-uploads-form-toolbar") do |toolbar|
                  toolbar.trailing do
                    form.submit(
                      disabled ? "Uploading files…" : multiple ? "Upload selected files" : "Upload file",
                      id: "gallery-uploads-submit",
                      disabled:,
                      data: { turbo_submits_with: "Uploading files…" }
                    )
                  end
                end
              end
            end
          end
        end
      end

      def render_upload_file_control(form, multiple:, disabled:)
        if state == "error"
          form.field(
            :files,
            as: :file,
            label: "Data file",
            description: "Choose a CSV, NDJSON, JSON, or ZIP file under 250 MB.",
            accept: ".csv,.ndjson,.json,.zip,text/csv,application/json,application/zip",
            multiple:,
            required: true,
            disabled:
          )
        else
          form.dropzone(
            :files,
            id: "gallery-uploads-dropzone",
            label: multiple ? "Choose up to five data files" : "Choose a data file",
            description: "CSV, NDJSON, JSON, or ZIP · 250 MB per file",
            presentation: :minimal,
            direct_upload: false,
            accept: ".csv,.ndjson,.json,.zip,text/csv,application/json,application/zip",
            multiple:,
            max_files: multiple ? 5 : 1,
            max_bytes: 262_144_000,
            required: true,
            disabled:
          )
        end
      end

      def render_upload_status(section)
        case state
        when "uploading"
          section.status NitroKit::Alert.new(variant: :info, live: :polite, id: "gallery-uploads-uploading") do |alert|
            alert.icon NitroKit::Icon.new(:upload, id: "gallery-uploads-uploading-icon")
            alert.title("Uploading three files")
            alert.description("42.8 MB of 119.1 MB transferred. Keep this page open until the application confirms receipt.")
          end
        when "complete"
          section.status NitroKit::Alert.new(variant: :success, live: :polite, id: "gallery-uploads-complete") do |alert|
            alert.icon NitroKit::Icon.new(:circle_check, id: "gallery-uploads-complete-icon")
            alert.title("Upload complete")
            alert.description("customer-accounts-2026-07-13.csv is stored and queued for validation.")
          end
        when "error"
          section.status NitroKit::Alert.new(variant: :error, live: :assertive, id: "gallery-uploads-error") do |alert|
            alert.icon NitroKit::Icon.new(:circle_x, id: "gallery-uploads-error-icon")
            alert.title("Upload was not accepted")
            alert.description("Choose at least one supported file and a valid destination before retrying.")
          end
        end
      end

      def render_upload_records
        render NitroKit::DataSection.new(
          title: upload_records_title,
          description: upload_records_description,
          id: "gallery-uploads-records-section"
        ) do |section|
          section.actions(
            NitroKit::ButtonGroup.new(id: "gallery-uploads-record-actions", label: "Upload record actions")
          ) do |actions|
            actions.button("View import policy", href: "#import-policy")
          end

          if upload_records.empty?
            section.empty_state NitroKit::EmptyState.new(
              title: "No uploads yet",
              description: "Choose a supported file above to create your first import.",
              variant: :borderless,
              level: 3,
              id: "gallery-uploads-empty"
            ) do |empty|
              empty.icon NitroKit::Icon.new(:file_up, id: "gallery-uploads-empty-icon")
              empty.action NitroKit::Button.new("Review accepted formats", href: "#accepted-formats")
            end
          else
            section.table NitroKit::Table.new(id: "gallery-uploads-records-table") do |table|
              populate_upload_table(table)
            end
          end
        end
      end

      def populate_upload_table(table)
        table.caption("Files in this import history")
        table.thead do
          table.tr do
            table.th("File")
            table.th("Size") unless state == "mobile"
            table.th("Uploaded by") unless state == "mobile"
            table.th("Status")
          end
        end
        table.tbody do
          upload_records.each_with_index do |record, index|
            table.tr do
              table.th(upload_filename(record, index), scope: :row)
              table.td(format_size(record.size_bytes)) unless state == "mobile"
              table.td(record.uploaded_by) unless state == "mobile"
              table.td do
                render NitroKit::Badge.new(
                  record.status.to_s.humanize,
                  id: "gallery-upload-record-#{index + 1}-status",
                  color: upload_status_color(record.status),
                  size: :sm
                )
              end
            end
          end
        end
      end

      def upload_submission
        attributes = case state
        when "error"
          { files: [], destination: "unsupported", note: "Retry after validating the source.", overwrite: false }
        when "multiple", "uploading"
          {
            files: %w[accounts.csv events.ndjson archive.zip],
            destination: "research_archive",
            note: "Quarterly regulated archive import.",
            overwrite: false
          }
        else
          {
            files: [ "customer-accounts.csv" ],
            destination: "customer_accounts",
            note: state == "long" ? "Import for International Research, Production, Reliability, and Regulatory Operations." : "Verified account refresh.",
            overwrite: false
          }
        end

        Gallery::Forms::UploadSubmission.new(**attributes).tap do |submission|
          submission.validate if state == "error"
        end
      end

      def upload_records
        @upload_records ||= case state
        when "empty"
          []
        when "uploading", "multiple"
          Gallery::OperationalData.uploads
        when "complete"
          Gallery::OperationalData.uploads.first(1)
        when "error"
          [
            Gallery::OperationalData::UploadRecord.new(
              id: "upload_rejected",
              filename: "unsupported-executable.exe",
              size_bytes: 4_204_112,
              content_type: "application/octet-stream",
              status: :failed,
              uploaded_by: "Ada Lovelace",
              uploaded_at: Time.zone.parse("2026-07-13 09:29:00")
            )
          ]
        when "mobile"
          Gallery::OperationalData.uploads.first(2)
        else
          Gallery::OperationalData.uploads.first(1)
        end
      end

      def upload_filename(record, index)
        return record.filename unless state == "long" && index.zero?

        "international-research-production-reliability-regulatory-and-customer-operations-account-ledger-2026-07-13.csv"
      end

      def format_size(bytes)
        Kernel.format("%.1f MB", bytes.fdiv(1_048_576))
      end

      def upload_status_color(status)
        { complete: :success, processing: :info, queued: :neutral, failed: :danger }.fetch(status)
      end

      def upload_title
        {
          "empty" => "Upload workspace data",
          "uploading" => "Uploading workspace data",
          "complete" => "Upload received",
          "error" => "Correct upload details",
          "multiple" => "Upload multiple files",
          "long" => "Upload regulated research archive",
          "mobile" => "Upload data"
        }.fetch(state)
      end

      def upload_records_title
        state == "error" ? "Rejected uploads" : "Recent uploads"
      end

      def upload_records_description
        state == "empty" ? "Completed and processing uploads will appear here." :
          "Follow each file from receipt through validation and processing."
      end

      def loading_state? = state == "uploading"
      def section_title = "Multipart upload operations"
      def section_description = "Empty, active, complete, rejected, multi-file, long-content, and narrow upload states."

      def state_description
        {
          "empty" => "Import CSV, NDJSON, JSON, or ZIP data into a workspace destination.",
          "uploading" => "Three files are transferring now. Keep this page open until receipt is confirmed.",
          "complete" => "Your file is safely stored and waiting for validation.",
          "error" => "The last file was rejected. Correct the source and destination before retrying.",
          "multiple" => "Upload up to five related files in one audited submission.",
          "long" => "Import a regulated archive with complete filenames and operational context.",
          "mobile" => "Choose a file, destination, and import policy from any screen size."
        }.fetch(state)
      end
    end
  end
end
