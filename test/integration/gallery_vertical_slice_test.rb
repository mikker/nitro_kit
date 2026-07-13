require "test_helper"

class GalleryVerticalSliceTest < ActionDispatch::IntegrationTest
  test "button page covers variants sizes content modes and native states" do
    get_component("button")

    NitroKit::Button::VARIANTS.each do |variant|
      assert_select "[data-nk='button'][data-variant='#{variant}']", minimum: 1
    end
    NitroKit::Button::SIZES.each do |size|
      assert_select "[data-nk='button'][data-size='#{size}']", minimum: 1
    end

    assert_select "#gallery-button-leading-icon [data-slot='button-icon-start']"
    assert_select "#gallery-button-trailing-icon [data-slot='button-icon-end']"
    assert_select "#gallery-button-icon-only[aria-label='Close notification']"
    assert_select "a#gallery-button-link[href='#button-documentation']"
    assert_select "button#gallery-button-disabled[disabled]"
    assert_select "a#gallery-button-link-disabled[aria-disabled='true']:not([href])"
  end

  test "icon page covers every size decorative state labels and stroke weights" do
    get_component("icon")

    NitroKit::Icon::SIZES.each do |size|
      assert_select "[data-nk='icon'][data-size='#{size}']", minimum: 1
    end

    assert_select "#gallery-icon-meaningful[role='img'][aria-label='Deployment succeeded'][aria-hidden='false']"
    assert_select "#gallery-icon-decorative[aria-hidden='true']:not([role])"
    assert_select "#gallery-icon-save-thin[stroke-width='1']"
    assert_select "#gallery-icon-warning-bold[stroke-width='2']"
  end

  test "card page covers its anatomy long content and a composed profile form" do
    get_component("card")

    assert_select "#gallery-card-workspace[data-nk='card']" do
      assert_select "[data-slot='card-title']"
      assert_select "[data-slot='card-body']"
      assert_select "[data-slot='card-divider']"
      assert_select "[data-slot='card-footer']"
    end
    assert_select "#gallery-card-activity [data-slot='card-full']"
    assert_select "#gallery-card-long-content [data-slot='card-title']", text: /workspace name/
    assert_select "#gallery-card-profile-form-card form#gallery-card-profile-form" do
      assert_select "#gallery-card-profile-name-field[data-nk='field']"
      assert_select "#gallery-card-profile-email-field[data-nk='field']"
      assert_select "#gallery-card-profile-name[data-nk='input']"
    end
    assert_select "#gallery-card-profile-save[data-nk='button'][form='gallery-card-profile-form'][type='submit']"
    assert_select "#gallery-card-profile-reset[data-nk='button'][form='gallery-card-profile-form'][type='reset']"
  end

  test "input page covers representative native types and browser states" do
    get_component("input")

    Gallery::Data.input_examples.map(&:type).uniq.each do |type|
      assert_select "[data-nk='input'][type='#{type}']", minimum: 1
    end

    assert_select "#gallery-input-checkbox[type='checkbox'][checked]"
    assert_select "#gallery-input-file[type='file'][accept='image/png,image/jpeg']"
    assert_select "#gallery-input-range[type='range'][min='0'][max='100'][step='10']"
    assert_select "#gallery-input-invalid[required][aria-invalid='true']"
    assert_select "#gallery-input-readonly[readonly]"
    assert_select "#gallery-input-disabled-state[disabled]"
  end

  test "field page covers control modes availability validation and long content" do
    get_component("field")

    %w[string textarea select checkbox switch radio-group].each do |type|
      assert_select "[data-nk='field'][data-type='#{type}']", minimum: 1
    end

    assert_select "#gallery-field-required-wrapper[data-required] input[required]"
    assert_select "#gallery-field-disabled-wrapper[data-disabled] input[disabled]"
    assert_select "#gallery-field-invalid-wrapper[data-state='invalid'] input[aria-invalid='true']"
    assert_select "#gallery-field-switch[role='switch'][checked]"
    assert_select "#gallery-field-radio-group-wrapper fieldset[data-nk='radio-button-group']"
    assert_select "#gallery-field-long-content-wrapper [data-slot='field-description']", text: /every administrator/
  end

  test "table page covers semantics alignment badges actions and empty state" do
    get_component("table")

    assert_select "#gallery-table-members table#gallery-table-members-element" do
      assert_select "th[scope='col']", minimum: 3
      assert_select "th[scope='row']", minimum: Gallery::Data.members.size
      assert_select "[data-align='right']", minimum: 2
    end
    assert_select "#gallery-table-invoices [data-nk='badge'][data-color='success']"
    assert_select "#gallery-table-invoices [data-nk='badge'][data-color='warning']"
    assert_select "#gallery-table-invoices a[data-nk='button'][data-variant='ghost']",
      count: Gallery::Data.invoices.size
    assert_select "#gallery-table-empty td[colspan='3']", text: /No API credentials/
  end

  test "dialog page covers native states accessible relationships and a composed form" do
    get_component("dialog")

    assert_select "#gallery-dialog-remove-member [data-slot='dialog-panel']" do
      assert_select "[aria-labelledby='gallery-dialog-remove-member-title']"
      assert_select "[aria-describedby='gallery-dialog-remove-member-description']"
    end
    assert_select "#gallery-dialog-open [data-slot='dialog-panel'][open][data-state='open']"
    assert_select "#gallery-dialog-disabled [data-slot='dialog-trigger'][disabled]"
    assert_select "#gallery-dialog-invite form#gallery-dialog-invite-form" do
      assert_select "#gallery-dialog-invite-email-field[data-nk='field']"
      assert_select "#gallery-dialog-invite-role-field[data-nk='field']"
      assert_select "#gallery-dialog-invite-email[data-nk='input'][type='email']"
      assert_select "#gallery-dialog-invite-submit[data-nk='button'][type='submit']"
    end
  end

  private

  def get_component(slug)
    get gallery_component_path(slug)
    assert_response :success
  end
end
