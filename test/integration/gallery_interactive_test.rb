require "test_helper"

class GalleryInteractiveTest < ActionDispatch::IntegrationTest
  test "dropdown page covers placement native popover anatomy and disabled behavior" do
    get_component("dropdown")

    NitroKit::Dropdown::PLACEMENTS.each do |placement|
      id = "gallery-dropdown-#{placement}"
      assert_select "##{id}[data-nk='dropdown'][data-placement='#{placement.to_s.tr("_", "-")}']" do
        assert_select "##{id}-trigger[popovertarget='#{id}-content'][aria-haspopup='menu']:not([aria-expanded])"
        assert_select "##{id}-content[popover='auto'][role='menu']:not([data-state])"
      end
    end

    assert_select "#gallery-dropdown-account-content[aria-labelledby='gallery-dropdown-account-trigger']" do
      assert_select "[data-slot='dropdown-title']", count: 2
      assert_select "a[data-slot='dropdown-item'][href='/gallery/settings']"
      assert_select "button[data-slot='dropdown-item'][data-variant='destructive']", text: "Delete workspace"
      assert_select "[data-slot='dropdown-separator'][role='separator']", count: 1
    end
    assert_select "#gallery-dropdown-disabled-trigger[disabled]:not([popovertarget])"
    assert_select "#gallery-dropdown-disabled-content [data-slot='dropdown-item'][disabled]"
  end

  test "dropdown page composes a release record without leaking styling hooks" do
    get_component("dropdown")

    assert_select "#gallery-dropdown-deployment-card[data-nk='card']" do
      assert_select "#gallery-dropdown-deployment-status[data-nk='badge'][data-color='success']"
      assert_select "#gallery-dropdown-deployment[data-nk='dropdown']" do
        assert_select "a[href='/gallery/deployments/2026-07-13']"
        assert_select "button[data-variant='destructive']", text: "Roll back release"
      end
    end
    assert_clean_canvases
  end

  test "tooltip page puts descriptions on every focusable trigger" do
    get_component("tooltip")

    NitroKit::Tooltip::PLACEMENTS.each do |placement|
      id = "gallery-tooltip-#{placement}"
      assert_select "##{id}[data-placement='#{placement}']:not([data-state])" do
        assert_select "##{id}-trigger[data-nk='button'][aria-describedby='#{id}-content']"
        assert_select "##{id}-content[role='tooltip']:not([hidden]):not([data-state])"
      end
    end

    assert_select "#gallery-tooltip-icon-trigger[aria-label='Copy account identifier']" do
      assert_select "svg[data-nk='icon']"
      assert_select "[data-slot='button-label']", count: 0
    end
    assert_select "#gallery-tooltip-long-content", text: /active integrations continue/
  end

  test "tooltip page composes sensitive credential actions" do
    get_component("tooltip")

    assert_select "#gallery-tooltip-api-card[data-nk='card']" do
      assert_select "#gallery-tooltip-api-access[data-nk='badge'][data-color='warning']"
      assert_select "#gallery-tooltip-rotate-key-trigger[aria-describedby='gallery-tooltip-rotate-key-content']"
      assert_select "#gallery-tooltip-rotate-action[data-variant='destructive']"
    end
    assert_clean_canvases
  end

  test "combobox page covers typed choices selection availability and placement" do
    get_component("combobox")

    assert_select "#gallery-combobox-empty[data-state='closed']" do
      assert_select "#gallery-combobox-empty-input[role='combobox'][placeholder='Choose a country']"
      assert_select "#gallery-combobox-empty-value[name='profile[country]']" do
        assert_select "option[value='']", count: 1
      end
      assert_select "[data-slot='combobox-control'][hidden]"
      assert_select "[data-slot='combobox-native']:not([hidden])"
      assert_select "#gallery-combobox-empty-listbox[role='listbox'][hidden]"
      assert_select "[data-slot='combobox-option']", count: 5
      assert_select "[data-value='fi'][aria-disabled='true']"
    end
    assert_select "#gallery-combobox-selected" do
      assert_select "#gallery-combobox-selected-input[value='Denmark']"
      assert_select "#gallery-combobox-selected-value option[value='dk'][selected]"
      assert_select "[data-value='dk'][aria-selected='true']"
    end
    assert_select "#gallery-combobox-required-input[aria-required='true']:not([required])"
    assert_select "#gallery-combobox-required-value[required]"
    assert_select "#gallery-combobox-disabled" do
      assert_select "#gallery-combobox-disabled-input[disabled]"
      assert_select "#gallery-combobox-disabled-value[disabled]"
    end

    NitroKit::Combobox::PLACEMENTS.each do |placement|
      assert_select "#gallery-combobox-#{placement}[data-placement='#{placement.to_s.tr("_", "-")}']"
    end
  end

  test "combobox page composes one progressive search control and one native named value" do
    get_component("combobox")

    assert_select "#gallery-combobox-deployment-card[data-nk='card']" do
      assert_select "#gallery-combobox-deployment-form[method='post']" do
        assert_select "#gallery-combobox-release[data-nk='input'][readonly][name='deployment[release]']"
        assert_select "#gallery-combobox-environment[data-nk='combobox']" do
          assert_select "#gallery-combobox-environment-input[role='combobox']:not([name])"
          assert_select "#gallery-combobox-environment-value[name='deployment[environment]']" do
            assert_select "option[value='production'][selected]"
          end
          assert_select "[name='deployment[environment]']", count: 1
        end
        assert_select "#gallery-combobox-submit[type='submit'][data-variant='primary']"
      end
    end
    assert_clean_canvases
  end

  test "input page retains native date values constraints and availability" do
    get_component("input")

    assert_select "#gallery-input-date-empty[data-nk='input'][type='date'][name='schedule[date]']"
    assert_select "#gallery-input-date-selected[type='date'][value='2026-07-13']"
    assert_select "#gallery-input-date-required[min='2026-07-13'][max='2026-08-13'][required]"
    assert_select "#gallery-input-date-readonly[value='2026-07-13'][readonly]"
    assert_select "#gallery-input-date-disabled[value='2026-07-13'][disabled]"
    assert_select "#gallery-input-month[type='month'][name='billing[month]'][value='2026-08'][min='2026-01'][max='2026-12']"
    assert_select "#gallery-input-month-description", text: /YYYY-MM/
    assert_select "#gallery-input-week[type='week'][name='delivery[week]'][value='2026-W32']"
    assert_select "#gallery-input-week-description", text: /YYYY-Www/
    assert_select "[data-nk='select'] select#gallery-input-month-select[name='report[month]']" do
      assert_select "option[value='2026-08'][selected]", text: "August 2026"
    end
  end

  test "input page composes date field anatomy and scheduling action" do
    get_component("input")

    assert_select "#gallery-input-date-release-card[data-nk='card']" do
      assert_select "#gallery-input-date-release-form[method='post']" do
        assert_select "[data-nk='field'][data-field-type='date'][data-required]" do
          assert_select "label[for='gallery-input-date-release-date']", text: "Release date"
          assert_select "#gallery-input-date-release-date-description", text: /next thirty days/
          assert_select "#gallery-input-date-release-date[data-nk='input'][type='date'][name='release[date]'][required]"
        end
        assert_select "#gallery-input-date-schedule[type='submit'][data-variant='primary']"
      end
    end
    assert_clean_canvases
  end

  test "toast page covers every intent content mode and explicit Rails flash mapping" do
    get_component("toast")

    assert_select "#gallery-toast-variants[role='region']:not([aria-live])" do
      assert_select "[data-nk='toast-item']", count: NitroKit::Toast::Item::VARIANTS.size
      NitroKit::Toast::Item::VARIANTS.each do |variant|
        assert_select "[data-nk='toast-item'][data-variant='#{variant}']", count: 1
      end
    end
    assert_select "#gallery-toast-permanent [data-nk='toast-item']" do
      assert_select "[data-slot='toast-item-dismiss']", count: 0
    end
    assert_select "#gallery-toast-block" do
      assert_select "#gallery-toast-environment[data-nk='badge'][data-color='success']"
    end
    assert_select "#gallery-toast-long [data-variant='error']", text: /primary database rejected/

    assert_select "#gallery-toast-flash[data-nk='toast']" do
      assert_select "[data-nk='toast-item']", count: 4
      assert_select "[data-variant='default']", text: /Welcome back/
      assert_select "[data-variant='success']", text: /settings were saved/
      assert_select "[data-variant='warning']", text: /payment method expires/
      assert_select "[data-variant='error']", text: /session expired/
    end
  end

  test "toast page documents the whole controller to screen path" do
    get_component("toast")

    assert_select "#section-toast-controller-to-screen-description", text: /application layout/
    assert_select "#example-toast-flash-lifecycle-description", text: /see_other/
    assert_select "#example-toast-flash-lifecycle-description", text: /unprocessable_entity/
    assert_select "#example-toast-region-announcement-description", text: /role=alert/
    assert_select "#example-toast-flash-lifecycle-code [data-gallery='code-source']" do |sources|
      source = sources.first.text

      assert_match(/Toast::FlashMessages/, source)
      assert_match(/status: :see_other/, source)
      assert_match(/flash\.now\[:alert\]/, source)
      assert_match(/status: :unprocessable_entity/, source)
      assert_match(/turbo_stream\.append/, source)
    end
    assert_select "#gallery-toast-announcement [data-nk='toast-item'][data-variant='error'][role='alert']"
    assert_select "#gallery-toast-announcement [data-nk='toast-item'][data-variant='success'][role='status']"
  end

  test "toast page composes a settings result and exposes pause and dismissal actions" do
    get_component("toast")

    assert_select "#gallery-toast-integration-card[data-nk='card']" do
      assert_select "#gallery-toast-integration-status[data-color='success']"
      assert_select "#gallery-toast-configure[data-nk='button']"
    end
    assert_select "#gallery-toast-integration-result [data-nk='toast-item'][data-state='open']" do
      assert_select "[data-action*='pointerenter->nk--toast#pause']"
      assert_select "[data-action*='focusout->nk--toast#resume']"
      assert_select "[data-slot='toast-item-dismiss'][aria-label='Dismiss notification']"
    end
    assert_clean_canvases
  end

  private

  def get_component(slug)
    get gallery_component_path(slug)
    assert_response :success
  end

  def assert_clean_canvases
    assert_select "[data-gallery='example-canvas'] [class]", count: 0
    assert_select "[data-gallery='example-canvas'] [style]", count: 0
    assert_select "[data-gallery='example-canvas'] [data-nk-escape]", count: 0
  end
end
