require "test_helper"
require "base64"
require "digest"

class DropzoneGalleryTest < ActionDispatch::IntegrationTest
  test "gallery executes direct multipart shared form constraint and disabled examples" do
    get gallery_component_path("dropzone")

    assert_response :success
    assert_select "[data-gallery-page='dropzone']"
    assert_select "[data-gallery='example']", count: 10
    assert_select "[data-gallery='code-source']", count: 10
    assert_select "[data-gallery='code-source']", text: /form\.dropzone/

    assert_select "#gallery-dropzone-direct-form[method='post'][enctype='multipart/form-data']" do
      assert_select "#gallery-dropzone-direct[data-nk='dropzone'][data-state='idle']" do
        assert_select "input[type='file'][name='upload[files][]'][multiple][required]" \
          "[data-direct-upload-url='#{rails_direct_uploads_path}']"
        assert_select "[data-slot='dropzone-progress']", minimum: 1
        assert_select "[data-slot='dropzone-remove-control'][type='button']", minimum: 1
      end
      assert_select "#gallery-dropzone-direct-submit[type='submit']"
    end

    assert_select "#gallery-dropzone-multipart-form[method='post'][enctype='multipart/form-data']" do
      assert_select "#gallery-dropzone-multipart[data-nk='dropzone']" do
        assert_select "input[type='file'][name='upload[files][]'][multiple]:not([data-direct-upload-url])"
      end
      assert_select "#gallery-dropzone-multipart-submit[type='submit']"
    end

    assert_select "#gallery-dropzone-shared-form[method='post'][enctype='multipart/form-data']" do
      assert_select "#gallery-dropzone-shared-primary input[type='file'][name='upload[primary_file]']"
      assert_select "#gallery-dropzone-shared-secondary input[type='file'][name='upload[secondary_file]']"
      assert_select "#gallery-dropzone-shared-submit[type='submit']:not([disabled])"
      assert_select "#gallery-dropzone-shared-disabled-submit[type='submit'][disabled]"
    end

    assert_select "#gallery-dropzone-minimal[data-presentation='minimal']" do
      assert_select "input[type='file'][name='avatar[file]']:not([hidden])"
      assert_select "label[data-slot='dropzone-message'][for='gallery-dropzone-minimal-input']"
    end

    assert_select "#gallery-dropzone-required-input[required][accept='application/pdf']"
    assert_select "#gallery-dropzone-disabled[data-state='disabled']:not([data-controller])" do
      assert_select "input[type='file'][disabled]"
    end
    assert_select "[data-gallery='example-canvas'] [class]", count: 0
    assert_select "[data-gallery='example-canvas'] [style]", count: 0
  end

  test "ordinary multipart endpoint receives native browser files" do
    post gallery_upload_submissions_path, params: {
      upload: {
        files: [
          fixture_file_upload("profile.txt", "text/plain"),
          fixture_file_upload("evidence.txt", "text/plain")
        ]
      }
    }

    assert_response :success
    assert_select "turbo-frame#gallery-dropzone-multipart-preview"
    assert_select "[data-nk=alert]", text: /Processed 2 files.*profile.txt.*evidence.txt/
    assert_select "#gallery-dropzone-multipart[data-state=idle]"
  end

  test "processes signed blobs and renders a fresh direct upload form" do
    blob = issue_upload("real upload contents", "evidence.txt")
    key = blob.key

    assert_difference("ActiveStorage::Blob.count", -1) do
      post gallery_upload_submissions_path(mode: "direct"), params: { upload: { files: [ blob.signed_id ] } }
    end

    assert_response :success
    assert_select "turbo-frame#gallery-dropzone-direct-preview" do
      assert_select "[data-nk=alert]", text: /Processed 1 file.*evidence.txt \(20 bytes\)/
      assert_select "#gallery-dropzone-direct[data-state=idle]"
      assert_select "[data-slot=dropzone-signed-id]", count: 0
      assert_select "input[type=file]:not([value])"
    end
    refute ActiveStorage::Blob.service.exist?(key)
  end

  test "processes both shared inputs and reports expired uploads" do
    blobs = %w[primary secondary].map do |name|
      issue_upload(name, "#{name}.txt")
    end
    post gallery_upload_submissions_path(mode: "shared"), params: {
      upload: { primary_file: blobs.first.signed_id, secondary_file: blobs.last.signed_id }
    }
    assert_response :success
    assert_select "turbo-frame#gallery-dropzone-shared-preview [data-nk=alert]", text: /Processed 2 files.*primary.txt.*secondary.txt/
    assert_select "#gallery-dropzone-shared-primary[data-state=idle]"
    assert_select "#gallery-dropzone-shared-secondary[data-state=idle]"

    post gallery_upload_submissions_path(mode: "direct"), params: { upload: { files: [ "invalid" ] } }
    assert_response :unprocessable_entity
    assert_select "turbo-frame#gallery-dropzone-direct-preview [role=alert]", text: /no longer available/
  end

  test "dummy Active Storage endpoint creates a direct upload contract" do
    contents = "Nitro Kit"

    assert_difference("ActiveStorage::Blob.count", 1) do
      post rails_direct_uploads_path,
        params: {
          blob: {
            filename: "evidence.txt",
            content_type: "text/plain",
            byte_size: contents.bytesize,
            checksum: Base64.strict_encode64(Digest::MD5.digest(contents))
          }
        },
        as: :json
    end

    assert_response :success
    payload = response.parsed_body
    assert payload.fetch("signed_id").present?
    assert_equal "evidence.txt", payload.fetch("filename")
    assert_equal "text/plain", payload.fetch("content_type")
    assert_equal contents.bytesize, payload.fetch("byte_size")
    assert payload.dig("direct_upload", "url").present?
    assert_kind_of Hash, payload.dig("direct_upload", "headers")
  end

  test "engine import map exposes Active Storage to the gallery" do
    get gallery_component_path("dropzone")

    assert_response :success
    imports = JSON.parse(css_select("script[type='importmap']").first.text).fetch("imports")
    assert_match %r{\A/assets/activestorage\.esm-}, imports.fetch("@rails/activestorage")
    assert_match %r{\A/assets/controllers/nk/dropzone_controller-}, imports.fetch("controllers/nk/dropzone_controller")
  end

  test "a signed blob from another session cannot be read or purged" do
    blob = issue_upload("private demo", "private.txt")
    other = open_session
    assert_no_difference "ActiveStorage::Blob.count" do
      other.post gallery_upload_submissions_path(mode: "direct"), params: { upload: { files: [ blob.signed_id ] } }
    end
    assert_equal 422, other.response.status
    assert ActiveStorage::Blob.service.exist?(blob.key)
  end

  test "foreign expired and attached blobs reject the entire submission" do
    own = issue_upload("own", "own.txt")
    foreign = ActiveStorage::Blob.create_and_upload!(io: StringIO.new("foreign"), filename: "foreign.txt")
    assert_no_difference "ActiveStorage::Blob.count" do
      post gallery_upload_submissions_path(mode: "direct"), params: { upload: { files: [ own.signed_id, foreign.signed_id ] } }
    end
    assert_response :unprocessable_entity
    assert ActiveStorage::Blob.service.exist?(own.key)

    own.update!(created_at: 31.minutes.ago)
    post gallery_upload_submissions_path(mode: "direct"), params: { upload: { files: [ own.signed_id ] } }
    assert_response :unprocessable_entity
    own.update!(created_at: Time.current)
    record = Gallery::CatalogItem.create!(sku: "UPLOAD-TEST", name: "Upload", owner: "Test", status: "active", seats: 1)
    ActiveStorage::Attachment.create!(name: "evidence", record:, blob: own)
    post gallery_upload_submissions_path(mode: "direct"), params: { upload: { files: [ own.signed_id ] } }
    assert_response :unprocessable_entity
    assert ActiveStorage::Blob.service.exist?(own.key)
  end

  test "issuance enforces size pending count and server-owned metadata" do
    issue_upload("data", "data.txt", metadata: { gallery_upload_owner: "client-selected" })
    owner = response.parsed_body.fetch("metadata").fetch("gallery_upload_owner")
    refute_equal "client-selected", owner
    [ nil, false, "invalid", 0, -1, 11.megabytes ].each do |size|
      assert_no_difference "ActiveStorage::Blob.count" do
        post rails_direct_uploads_path, params: { blob: upload_attributes("data", "data.txt").merge(byte_size: size) }, as: :json
      end
      assert_response :unprocessable_entity
    end
    11.times { issue_upload("data", "data.txt") }
    assert_no_difference "ActiveStorage::Blob.count" do
      post rails_direct_uploads_path, params: { blob: upload_attributes("data", "extra.txt") }, as: :json
    end
    assert_response :too_many_requests
  end

  test "issuance works with the issuing session CSRF token and rejects missing tokens" do
    previous = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    get gallery_component_path("dropzone")
    token = css_select("meta[name=csrf-token]").first["content"]
    post rails_direct_uploads_path, params: { blob: upload_attributes("data", "data.txt") },
      headers: { "X-CSRF-Token" => token }, as: :json
    assert_response :success
    assert_no_difference "ActiveStorage::Blob.count" do
      post rails_direct_uploads_path, params: { blob: upload_attributes("data", "data.txt") },
        headers: { "X-CSRF-Token" => nil }, as: :json
    end
    assert_response :unprocessable_entity
  ensure
    ActionController::Base.allow_forgery_protection = previous
  end

  private

  def upload_attributes(contents, filename)
    { filename:, content_type: "text/plain", byte_size: contents.bytesize,
      checksum: Base64.strict_encode64(Digest::MD5.digest(contents)) }
  end

  def issue_upload(contents, filename, metadata: {})
    post rails_direct_uploads_path, params: { blob: upload_attributes(contents, filename).merge(metadata:) }, as: :json
    assert_response :success
    blob = ActiveStorage::Blob.find_signed!(response.parsed_body.fetch("signed_id"))
    blob.upload(StringIO.new(contents))
    blob
  end
end
