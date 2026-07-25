require "test_helper"

class GalleryFormFamilyTest < ActionDispatch::IntegrationTest
  FORM_SLUGS = %w[
    label textarea select checkbox checkbox-group radio-button radio-button-group switch field-group fieldset
  ].freeze

  test "catalog reaches every explicit form family page without escape leaks" do
    FORM_SLUGS.each do |slug|
      entry = Gallery::Catalog.fetch!(kind: :component, slug:)

      assert_equal "all", Gallery::Catalog.category_for(entry).slug
      assert_predicate entry.expected_roots, :any?

      get gallery_component_path(slug)

      assert_response :success
      assert_select "div[data-gallery='page'][data-gallery-page='#{slug}']"
      assert_select "[data-gallery='example-canvas'] [class]", count: 0
      assert_select "[data-gallery='example-canvas'] [style]", count: 0
      assert_select "[data-gallery='example-canvas'] [data-nk-escape]", count: 0
    end
  end

  test "label page connects direct and builder labels to native controls" do
    get_component("label")

    assert_select "#gallery-label-email-label[data-nk='label'][for='gallery-label-email']",
      text: "Billing email"
    assert_select "#gallery-label-email[data-nk='input'][name='billing[email]'][value='billing@example.test']"
    assert_select "#gallery-label-message-label[for='gallery-label-message']"
    assert_select "#gallery-label-message[data-nk='textarea'][name='invitation[message]']",
      text: "Join the release planning workspace."
    assert_select "#gallery-label-role-label[for='gallery-label-role']"
    assert_select "#gallery-label-role[name='member[role]'] option[value='member'][selected]"
    assert_select "#gallery-label-search-label[for='gallery-label-search'] strong", text: "Search"
    assert_select "#gallery-label-incident-label[for='gallery-label-incident']", text: /recovery timeline/

    assert_select "#gallery-label-profile-form" do
      assert_select "label[for='gallery-label-profile-name']", text: "Name"
      assert_select "#gallery-label-profile-name[name='profile[name]'][required]"
      assert_select "label[for='gallery-label-profile-email']", text: "Account email"
      assert_select "#gallery-label-profile-email[name='profile[email]']" \
                    "[aria-describedby='gallery-label-profile-email-description']"
    end
  end

  test "textarea page covers values constraints availability and builder errors" do
    get_component("textarea")

    assert_select "#gallery-textarea-default[data-nk='textarea'][name='profile[bio]'][rows='4']",
      text: /Building reliable interfaces/
    assert_select "#gallery-textarea-empty[name='invitation[message]'][placeholder='Add an optional welcome message']",
      text: ""
    assert_select "#gallery-textarea-constrained[required][rows='6'][cols='48']" \
                  "[minlength='20'][maxlength='280'][wrap='hard']"
    assert_select "#gallery-textarea-readonly[readonly]"
    assert_select "#gallery-textarea-disabled[disabled]"
    assert_select "#gallery-textarea-long[wrap='soft']", text: /original timestamps/

    assert_select "[data-nk='field'][data-state='invalid'] #gallery-textarea-invalid" \
                  "[aria-invalid='true']" \
                  "[aria-describedby='gallery-textarea-invalid-description gallery-textarea-invalid-errors']"
    assert_select "#gallery-textarea-invalid-errors[data-slot='field-error']", text: /too long/

    assert_select "#gallery-textarea-profile-form" do
      assert_select "label[for='gallery-textarea-profile-bio']", text: "Bio"
      assert_select "#gallery-textarea-profile-bio[name='profile[bio]'][required][maxlength='280']" \
                    "[aria-invalid='true']"
      assert_select "#gallery-textarea-profile-bio-errors", text: /too long/
      assert_select "#gallery-textarea-profile-save[type='submit']", text: "Save biography"
    end
  end

  test "select page covers normalized choices blanks prompts multiple values and builder errors" do
    get_component("select")

    assert_select "#gallery-select-mixed[data-nk='select']" do
      assert_select "#gallery-select-mixed-control[name='workspace[region]']" do
        assert_select "option", count: 5
        assert_select "option[value=''][selected]", count: 0
        assert_select "option[value='eu-central'][selected][id='region-eu-central']",
          text: "European Union Central"
        assert_select "option[value='ap-legacy'][disabled][id='region-ap-legacy']"
      end
    end
    assert_select "#gallery-select-prompt-control[required] option[value=''][selected]", text: "Choose a role"
    assert_select "#gallery-select-empty-control[disabled] option", count: 0
    assert_select "#gallery-select-multiple-control[name='notifications[channels][]'][multiple]" do
      assert_select "option[selected]", count: 2
      assert_select "option[value='email'][selected]"
      assert_select "option[value='security'][selected]"
    end
    assert_select "#gallery-select-disabled-control[disabled] option[value='USD'][selected]"
    assert_select "#gallery-select-long-control option[value='regulated'][selected]",
      text: /immutable audit exports/

    assert_select "#gallery-select-profile-form [data-nk='field'][data-state='invalid']" do
      assert_select "#gallery-select-profile-time-zone[name='profile[time_zone]'][required][aria-invalid='true']"
      assert_select "#gallery-select-profile-time-zone-errors", text: /not included/
    end
  end

  test "checkbox page preserves values labels mixed state and builder validation" do
    get_component("checkbox")

    assert_select "#gallery-checkbox-unchecked[data-state='unchecked']" do
      assert_select "input[type='hidden'][name='preferences[email_summaries]'][value='disabled']"
      assert_select "#gallery-checkbox-unchecked-control[type='checkbox']" \
                    "[name='preferences[email_summaries]'][value='enabled']:not([checked])"
      assert_select "label[for='gallery-checkbox-unchecked-control']", text: "Email summaries"
    end
    assert_select "#gallery-checkbox-checked[data-state='checked'] #gallery-checkbox-checked-control[checked][required]"
    assert_select "#gallery-checkbox-indeterminate[data-state='indeterminate']" do
      assert_select "input[type='hidden']", count: 0
      assert_select "#gallery-checkbox-indeterminate-control[aria-checked='mixed']"
    end
    assert_select "#gallery-checkbox-disabled[data-disabled='true']" do
      assert_select "input", count: 2
      assert_select "input[disabled]", count: 2
    end
    assert_select "#gallery-checkbox-standalone" do
      assert_select "label", count: 0
      assert_select "#gallery-checkbox-standalone-control[aria-label='Select deployment row']"
    end
    assert_select "#gallery-checkbox-long label", text: /immediately invalidates/

    assert_select "#gallery-checkbox-registration-form [data-nk='field'][data-state='invalid']" do
      assert_select "input[type='hidden'][name='registration[terms]'][value='no']"
      assert_select "#gallery-checkbox-registration-terms[name='registration[terms]'][value='yes'][required]" \
                    "[aria-invalid='true']"
      assert_select "#gallery-checkbox-registration-terms-errors", text: /must be accepted/
    end
  end

  test "checkbox group page preserves array names IDs selection and disabled state" do
    get_component("checkbox-group")

    assert_select "#gallery-checkbox-group-notifications[data-nk='checkbox-group']" do
      assert_select "legend", text: "Notification channels"
      assert_select "#gallery-checkbox-group-notifications-description"
      assert_select "input[type='hidden'][name='preferences[channels][]']", count: 1
      assert_select "input[type='checkbox'][name='preferences[channels][]']", count: 4
      assert_select "input[type='checkbox'][checked]", count: 2
      assert_select "#gallery-channel-operations[value='operations']"
      assert_select "#gallery-channel-pager[value='pager'][disabled]"
      assert_select "input[type='checkbox'][aria-describedby='gallery-checkbox-group-notifications-description']",
        count: 4
    end
    assert_select "#gallery-checkbox-group-one input[type='checkbox']", count: 1
    assert_select "#gallery-checkbox-group-none input[type='checkbox'][checked]", count: 0
    assert_select "#gallery-checkbox-group-many input[type='checkbox']", count: 6
    assert_select "#gallery-checkbox-group-many input[value='billing'][disabled]"
    assert_select "#gallery-checkbox-group-disabled[disabled] input[disabled]", count: 3

    assert_select "#gallery-checkbox-group-report-form" do
      assert_select "#gallery-checkbox-group-reports input[name='subscription[reports][]'][checked]", count: 2
      assert_select "#gallery-checkbox-group-report-save[type='submit']", text: "Save subscriptions"
    end
  end

  test "radio button page covers same-name selection sizes labels and builder mapping" do
    get_component("radio-button")

    assert_select "input[type='radio'][name='workspace[visibility]']", count: 3
    assert_select "#gallery-radio-button-private[data-state='checked']" do
      assert_select "#gallery-radio-button-private-control[value='private'][checked][required]"
      assert_select "label[for='gallery-radio-button-private-control']", text: "Private to invited members"
    end
    assert_select "#gallery-radio-button-public[data-disabled='true'] input[disabled]"
    assert_select "#gallery-radio-button-medium[data-size='md']"
    assert_select "#gallery-radio-button-large[data-size='lg']"
    assert_select "#gallery-radio-button-standalone" do
      assert_select "label", count: 0
      assert_select "input[aria-label='Select deployment 1842']"
    end
    assert_select "#gallery-radio-button-long label", text: /extended regulated/

    assert_select "#gallery-radio-button-invitation-form" do
      assert_select "input[type='radio'][name='invitation[role]']", count: 3
      assert_select "#gallery-radio-button-builder-member[value='member'][checked][aria-label='Member']"
      assert_select "#gallery-radio-button-builder-viewer[value='viewer'][disabled][aria-label='Viewer']"
    end
  end

  test "radio group page preserves fieldset descriptions requirements selection and errors" do
    get_component("radio-button-group")

    assert_select "#gallery-radio-button-group-role[data-nk='radio-button-group'][data-required='true']" do
      assert_select "legend", text: "Default member role"
      assert_select "#gallery-radio-button-group-role-description"
      assert_select "input[type='radio'][name='workspace[default_role]'][required]", count: 3
      assert_select "#gallery-role-member[value='member'][checked]"
      assert_select "#gallery-role-viewer[value='viewer'][disabled]"
      assert_select "input[aria-describedby='gallery-radio-button-group-role-description']", count: 3
    end
    assert_select "#gallery-radio-button-group-one input[type='radio']", count: 1
    assert_select "#gallery-radio-button-group-none input[checked]", count: 0
    assert_select "#gallery-radio-button-group-many[data-size='lg'] input[type='radio']", count: 4
    assert_select "#gallery-radio-button-group-disabled[disabled] input[disabled]", count: 2

    assert_select "#gallery-radio-button-group-invitation-form [data-nk='field'][data-state='invalid']" do
      assert_select "#gallery-radio-button-group-invitation-role[aria-invalid='true']" \
                    "[aria-describedby='gallery-radio-button-group-invitation-role-description gallery-radio-button-group-invitation-role-errors']"
      assert_select "input[type='radio'][name='invitation[role]'][required]", count: 3
      assert_select "input[type='radio'][checked]", count: 0
      assert_select "#gallery-radio-button-group-invitation-role-errors", text: /not included/
    end
  end

  test "switch page covers role values sizes labels state and builder errors" do
    get_component("switch")

    assert_select "#gallery-switch-small[data-size='sm'][data-state='unchecked']" do
      assert_select "input[type='hidden'][name='preferences[weekly_digest]'][value='0']"
      assert_select "#gallery-switch-small-control[type='checkbox'][role='switch'][value='1']:not([checked])"
    end
    assert_select "#gallery-switch-medium[data-size='md'][data-state='checked']" do
      assert_select "#gallery-switch-medium-control[role='switch'][checked]"
      assert_select "[data-slot='switch-track'] [data-slot='switch-handle']"
    end
    assert_select "#gallery-switch-required-control[required]"
    assert_select "#gallery-switch-disabled[data-disabled='true'] input[disabled]", count: 2
    assert_select "#gallery-switch-block label", text: /Activity reports.*workspace owners/
    assert_select "#gallery-switch-aria" do
      assert_select "input[type='hidden']", count: 0
      assert_select "#gallery-switch-aria-control[aria-label='Use compact table rows']"
    end
    assert_select "#gallery-switch-long [data-slot='switch-description']", text: /every deployment target/

    assert_select "#gallery-switch-registration-form [data-nk='field'][data-state='invalid']" do
      assert_select "#gallery-switch-registration-terms[role='switch'][name='registration[terms]']" \
                    "[required][aria-invalid='true']"
      assert_select "#gallery-switch-registration-terms-errors", text: /must be accepted/
    end
  end

  test "field group page keeps layout separate from field semantics and Rails state" do
    get_component("field-group")

    assert_select "#gallery-field-group-one[data-nk='field-group']" do
      assert_select "[data-nk='field']", count: 1
      assert_select "#gallery-field-group-workspace-name[name='workspace[name]'][required]"
    end
    assert_select "#gallery-field-group-empty:empty"
    assert_select "#gallery-field-group-mixed" do
      assert_select "> [data-nk='field']", count: 4
      assert_select "[data-nk='textarea']", count: 1
      assert_select "[data-nk='select']", count: 1
      assert_select "[data-nk='checkbox']", count: 1
      assert_select "[data-nk='switch']", count: 1
    end

    assert_select "#gallery-field-group-profile-form" do
      assert_select "#gallery-field-group-profile-identity[data-nk='field-group'] > [data-nk='field']", count: 2
      assert_select "#gallery-field-group-profile-details[data-nk='field-group'] > [data-nk='field']", count: 2
      assert_select "[data-nk='field'][data-state='invalid']", count: 4
      assert_select "#gallery-field-group-profile-name[name='profile[name]']"
      assert_select "#gallery-field-group-profile-time-zone[name='profile[time_zone]']"
    end
    assert_select "#gallery-field-group-pressure label", text: /replacement credentials/
  end

  test "fieldset page covers empty disabled long and multipart builder compositions" do
    get_component("fieldset")

    assert_select "#gallery-fieldset-empty[data-nk='fieldset']" do
      assert_select "[data-slot='fieldset-legend']", text: "Optional advanced settings"
      assert_select "[data-slot='fieldset-description']", text: /No advanced settings/
      assert_select "[data-slot='fieldset-fields']:empty"
    end
    assert_select "#gallery-fieldset-disabled[disabled][name='legacy-sync']" do
      assert_select "#gallery-fieldset-disabled-destination[name='legacy[destination]']"
    end
    assert_select "#gallery-fieldset-long" do
      assert_select "#gallery-fieldset-long-fields[data-nk='field-group']"
      assert_select "#gallery-fieldset-rotation-window[type='number'][min='1'][max='90'][required]"
      assert_select "#gallery-fieldset-automatic-rotation[role='switch'][checked]"
    end

    assert_select "#gallery-fieldset-registration-form[enctype='multipart/form-data']" do
      assert_select "#gallery-fieldset-registration-source[type='hidden']" \
                    "[name='registration[source]'][value='gallery']"
      assert_select "#gallery-fieldset-registration[data-nk='fieldset']" do
        assert_select "[data-slot='fieldset-legend']", text: "Registration details"
        assert_select "#gallery-fieldset-registration-fields[data-nk='field-group'] > [data-nk='field']", count: 4
      end
      assert_select "#gallery-fieldset-registration-email[type='email'][name='registration[email]']" \
                    "[value='not-an-email'][aria-invalid='true']"
      assert_select "#gallery-fieldset-registration-role[name='registration[role]'][required][aria-invalid='true']"
      assert_select "#gallery-fieldset-registration-terms[type='checkbox'][required][aria-invalid='true']"
      assert_select "#gallery-fieldset-registration-attachment[type='file'][accept='text/plain']:not([value])"
      assert_select "[data-slot='field-error']", minimum: 3
      assert_select "#gallery-fieldset-registration-save[type='submit']", text: "Register"
    end
  end

  private

  def get_component(slug)
    get gallery_component_path(slug)
    assert_response :success
  end
end
