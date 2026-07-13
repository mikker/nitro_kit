require "test_helper"

class RailsIntegrationTest < ActionDispatch::IntegrationTest
  test "renders a model-backed Nitro form from direct Phlex" do
    get new_registration_path

    assert_response :success
    assert_select "turbo-frame#form_registration" do
      assert_select "form#details_registration[action='#{registration_path}'][method='post'][enctype='multipart/form-data']"
      assert_select "input#registration_source[name='registration[source]'][value='rails-integration'][data-nk='input']"
      assert_select "label[for='registration_email']", text: "Email"
      assert_select "input#registration_email[name='registration[email]'][type='email'][required]"
      assert_select "label[for='registration_role']", text: "Role"
      assert_select "select#registration_role[name='registration[role]'][required]"
      assert_select "label[for='registration_terms']", text: "I accept the terms"
      assert_select "input[type='hidden'][name='registration[terms]'][value='0']"
      assert_select "input#registration_terms[type='checkbox'][name='registration[terms]'][value='1']"
      assert_select "input#registration_attachment[type='file'][accept='text/plain']"
      assert_select "button[type='submit'][data-turbo-submits-with='Registering…']", text: "Register"
      assert_select "a[href='#{new_registration_path}'][data-turbo-frame='_top']", text: "Start over"
    end
  end

  test "renders real model errors and submitted values with an HTML 422" do
    post registration_path, params: {
      registration: {
        email: "not-an-email",
        role: "",
        terms: "0",
        source: "html-submit"
      }
    }

    assert_response :unprocessable_entity
    assert_select "turbo-frame#form_registration"
    assert_select "input#registration_email[value='not-an-email'][aria-invalid='true']"
    assert_select "input#registration_source[value='html-submit']"
    assert_select "[data-nk='field'][data-state='invalid'] [data-slot='field-error']", minimum: 3
    assert_select "#registration_email-errors", text: /Email is invalid/
    assert_select "#registration_role-errors", text: /Role is not included/
    assert_select "#registration_terms-errors", text: /Terms must be accepted/
  end

  test "returns a Phlex-generated Turbo Stream for validation errors" do
    post registration_path,
      params: { registration: { email: "", role: "", terms: "0" } },
      as: :turbo_stream

    assert_response :unprocessable_entity
    assert_select "turbo-stream[action='replace'][target='form_registration']", count: 1
    assert_select "turbo-stream template turbo-frame#form_registration"
    assert_select "turbo-stream [data-slot='field-error']", minimum: 3
  end

  test "redirects successful HTML submissions with 303 and a working fallback page" do
    post registration_path, params: valid_registration_params

    assert_response :see_other
    assert_redirected_to registration_path

    follow_redirect!
    assert_response :success
    assert_select "turbo-frame#form_registration h1", text: "Registration received"
    assert_select "a[href='#{new_registration_path}']", text: "Create another"
  end

  test "replaces the matching frame after a successful Turbo submission" do
    post registration_path, params: valid_registration_params, as: :turbo_stream

    assert_response :success
    assert_turbo_stream action: :replace, target: "form_registration"
    assert_select "turbo-stream template turbo-frame#form_registration h1", text: "Registration received"
  end

  private

  def valid_registration_params
    {
      registration: {
        email: "dev@example.com",
        role: "developer",
        terms: "1",
        source: "integration-test",
        attachment: fixture_file_upload("profile.txt", "text/plain")
      }
    }
  end
end
