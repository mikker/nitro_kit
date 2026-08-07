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
          eyebrow: "Data operations",
          description: state_description,
          id: "gallery-uploads-header"
        ) do |header|
          header.actions(
            NitroKit::ButtonGroup.new(id: "gallery-uploads-header-actions", label: "Upload navigation")
          ) do |actions|
            actions.button("Import history", href: "#import-history")
            actions.button("Upload files", href: entry_path(entry, state: "empty"), variant: :primary)
          end
        end
      end

      def render_upload_form
        submission = upload_submission
        disabled = state == "uploading"
        multiple = state.in?(%w[uploading multiple])

        render NitroKit::SettingsSection.new(
          title: multiple ? "Upload data files" : "Upload a data file",
          description: "The application owns accepted formats, limits, storage, scanning, processing, and retention.",
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
              form.fieldset(
                legend: "Import source",
                description: "CSV, NDJSON, JSON, or ZIP. Up to five files per submission."
              ) do
                form.group do
                  form.field(
                    :files,
                    as: :file,
                    label: multiple ? "Data files" : "Data file",
                    description: "Files are submitted with native multipart form semantics.",
                    accept: ".csv,.ndjson,.json,.zip,text/csv,application/json,application/zip",
                    multiple:,
                    required: true,
                    disabled:
                  )
                  form.field(
                    :destination,
                    as: :select,
                    label: "Destination",
                    options: Gallery::Forms::UploadSubmission::DESTINATIONS.map do |destination|
                      [ destination.humanize, destination ]
                    end,
                    prompt: "Choose a destination",
                    required: true,
                    disabled:
                  )
                  form.field(
                    :note,
                    as: :textarea,
                    label: "Import note",
                    description: "Optional context for workspace audit history.",
                    disabled:,
                    maxlength: 240
                  )
                  form.field(
                    :overwrite,
                    as: :checkbox,
                    label: "Replace records with matching external IDs",
                    description: "The application validates whether the selected destination permits replacement.",
                    disabled:
                  )
                end
              end
              render NitroKit::Toolbar.new(id: "gallery-uploads-form-toolbar") do |toolbar|
                toolbar.leading do
                  render NitroKit::Badge.new(
                    multiple ? "Up to 5 files" : "One file",
                    color: :info,
                    id: "gallery-uploads-file-limit"
                  )
                end
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

      def render_upload_status(section)
        case state
        when "uploading"
          section.status NitroKit::Alert.new(id: "gallery-uploads-uploading") do |alert|
            alert.icon NitroKit::Icon.new(:upload, id: "gallery-uploads-uploading-icon")
            alert.title("Uploading three files")
            alert.description("42.8 MB of 119.1 MB transferred. Keep this page open until the application confirms receipt.")
          end
        when "complete"
          section.status NitroKit::Alert.new(variant: :success, id: "gallery-uploads-complete") do |alert|
            alert.icon NitroKit::Icon.new(:circle_check, id: "gallery-uploads-complete-icon")
            alert.title("Upload complete")
            alert.description("customer-accounts-2026-07-13.csv is stored and queued for validation.")
          end
        when "error"
          section.status NitroKit::Alert.new(variant: :error, id: "gallery-uploads-error") do |alert|
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
              description: "Select a supported file above to create the first application-owned upload record.",
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
        table.caption("Application-owned file upload records")
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
          "Caller-owned records expose file identity, size, actor, and processing state."
      end

      def loading_state? = state == "uploading"
      def composition_label = "File upload"
      def section_title = "Multipart upload operations"
      def section_description = "Empty, active, complete, rejected, multi-file, long-content, and narrow upload states."

      def state_description
        {
          "empty" => "A ready multipart Rails form sits beside a meaningful zero-record state.",
          "uploading" => "Every input is disabled while visible progress and queued records remain stable.",
          "complete" => "The receipt identifies the accepted file and its next validation step.",
          "error" => "Model errors preserve destination and note values without placing a value on the file input.",
          "multiple" => "A native multiple file input and three deterministic records pressure the queue.",
          "long" => "Long filenames and destination context wrap without truncation or custom classes.",
          "mobile" => "Caller-owned compact table columns complement the narrow composition surface."
        }.fetch(state)
      end
    end
  end
end
