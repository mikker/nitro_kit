require "test_helper"
require "base64"
require "digest"

class DropzoneGalleryTest < ActionDispatch::IntegrationTest
  test "gallery executes direct multipart shared form constraint and disabled examples" do
    get gallery_component_path("dropzone")

    assert_response :success
    assert_select "[data-gallery-page='dropzone']"
    assert_select "[data-gallery='example']", count: 5
    assert_select "[data-gallery='code-source']", count: 5
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
    assert_equal "Received 2 files: profile.txt, evidence.txt", response.body
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
end
