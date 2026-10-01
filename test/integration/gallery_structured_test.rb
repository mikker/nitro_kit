require "test_helper"

class GalleryStructuredTest < ActionDispatch::IntegrationTest
  test "accordion page covers native modes counts and deterministic identity" do
    get_component("accordion")

    assert_select "#gallery-accordion-one[data-mode='multiple']" do
      assert_select "[data-slot='accordion-item']", count: 1
      assert_select "details[data-slot='accordion-item']:not([name]):not([open])" do
        assert_select "summary#gallery-accordion-one-summary-trigger"
        assert_select "#gallery-accordion-one-summary-content"
      end
    end

    assert_select "#gallery-accordion-one-open[data-mode='single']" do
      assert_select "details[data-slot='accordion-item'][name='gallery-accordion-one-open'][open]", count: 1
      assert_select "summary#gallery-accordion-one-open-summary-trigger"
      assert_select "#gallery-accordion-one-open-summary-content"
    end

    assert_select "#gallery-accordion-multiple[data-mode='multiple']" do
      assert_select "[data-slot='accordion-item']", count: 4
      assert_select "details[data-slot='accordion-item'][open]", count: 2
      assert_select "details[data-slot='accordion-item']:not([open])", count: 2
      assert_select "summary#gallery-accordion-multiple-advanced-trigger"
    end
  end

  test "accordion page covers pressure and nested operational detail" do
    get_component("accordion")

    assert_select "#gallery-accordion-pressure" do
      assert_select "[data-slot='accordion-item']", count: 6
      assert_select "#gallery-accordion-pressure-retention-trigger", text: /long-running organization/
      assert_select "#gallery-accordion-pressure-retention-content li", count: 3
      assert_select "summary#gallery-accordion-pressure-legacy-trigger"
    end

    assert_select "#gallery-accordion-deployment[data-mode='single']" do
      assert_select "#gallery-accordion-deployment-card[data-nk='card']" do
        assert_select "#gallery-accordion-deployment-status[data-nk='badge'][data-color='success']"
        assert_select "#gallery-accordion-deployment-actions[data-nk='button-group'][role='group']" do
          assert_select "[data-nk='button']", count: 2
        end
      end
      assert_select "#gallery-accordion-checks-table[data-nk='table']" do
        assert_select "tbody th[scope='row']", count: 3
      end
      assert_select "#gallery-accordion-environment-card[data-nk='card']"
      assert_select "#gallery-accordion-environment-status[data-nk='badge']", text: "Protected"
    end
  end

  test "tabs page covers orientation activation defaults disabled state and counts" do
    get_component("tabs")

    assert_select "#gallery-tabs-vertical-manual[data-orientation='vertical'][data-activation='manual']" do
      assert_select "[role='tablist'][aria-label='Account controls'][aria-orientation='vertical']"
      assert_select "[role='tab']", count: 4
      assert_select "#gallery-tabs-vertical-manual-security-tab" \
                    "[aria-controls='gallery-tabs-vertical-manual-security-panel']" \
                    "[aria-selected='true'][tabindex='0']"
      assert_select "#gallery-tabs-vertical-manual-security-panel" \
                    "[aria-labelledby='gallery-tabs-vertical-manual-security-tab']" \
                    ":not([aria-hidden]):not([hidden])"
      assert_select "[data-slot='tabs-panel']:not([hidden])", count: 4
      assert_select "#gallery-tabs-vertical-manual-legacy-tab[disabled][aria-selected='false']"
      assert_select "[role='tab']" do |tabs|
        tabs.each { |tab| assert_includes tab["data-action"], "keydown->nk--tabs#navigate" }
      end
    end

    assert_select "#gallery-tabs-one[data-orientation='horizontal'][data-activation='automatic']" do
      assert_select "[role='tab']", count: 1
      assert_select "#gallery-tabs-one-summary-tab[aria-selected='true']"
      assert_select "#gallery-tabs-one-summary-panel:not([hidden])"
    end

    assert_select "#gallery-tabs-pressure" do
      assert_select "[role='tab']", count: 7
      assert_select "#gallery-tabs-pressure-regional-preferences-tab[aria-selected='true']",
        text: /time-zone behavior/
      assert_select "#gallery-tabs-pressure-regional-preferences-panel", text: /original UTC value/
      assert_select "#gallery-tabs-pressure-legacy-tab[disabled]"
    end
  end

  test "tabs page composes complete settings panels" do
    get_component("tabs")

    assert_select "#gallery-tabs-administration[data-orientation='vertical'][data-activation='manual']" do
      assert_select "#gallery-tabs-profile-card[data-nk='card']" do
        assert_select "#gallery-tabs-profile-name[data-nk='input'][name='workspace[name]']"
        assert_select "#gallery-tabs-profile-time-zone[data-nk='input'][name='workspace[time_zone]']"
        assert_select "#gallery-tabs-profile-actions[data-nk='button-group'] [data-nk='button']", count: 2
      end
      assert_select "#gallery-tabs-members-table[data-nk='table']" do
        assert_select "tbody th[scope='row']", count: Gallery::Data.members.size
        assert_select "[data-nk='badge']", count: Gallery::Data.members.size
      end
      assert_select "#gallery-tabs-members-invite[data-nk='button'][href='#invite-member']"
      assert_select "#gallery-tabs-billing-card[data-nk='card']" do
        assert_select "#gallery-tabs-billing-status[data-nk='badge']", text: "Current plan"
        assert_select "#gallery-tabs-billing-actions[data-nk='button-group'] [data-nk='button']", count: 2
      end
    end
  end

  test "card page covers heading levels slot boundaries and nested record anatomy" do
    get_component("card")

    (1..6).each do |level|
      assert_select "#gallery-card-heading-#{level}" do
        assert_select "h#{level}[data-slot='card-title']", text: "Level #{level} title"
      end
    end

    assert_select "#gallery-card-empty:empty"
    assert_select "#gallery-card-title-only" do
      assert_select "[data-slot='card-title']", count: 1
      assert_select "[data-slot='card-body'], [data-slot='card-footer']", count: 0
    end
    assert_select "#gallery-card-footer-only" do
      assert_select "[data-slot='card-footer']", count: 1
      assert_select "[data-slot='card-title'], [data-slot='card-body']", count: 0
    end
    assert_select "#gallery-card-body-footer" do
      assert_select "[data-slot='card-body']", count: 1
      assert_select "[data-slot='card-footer']", count: 1
      assert_select "[data-slot='card-title']", count: 0
    end
    assert_select "#gallery-card-full-only [data-slot='card-full']", count: 1

    assert_select "#gallery-card-integration[data-nk='card']" do
      assert_select "[data-slot='card-title']", text: "Slack"
      assert_select "#gallery-card-integration-status[data-nk='badge'][data-color='warning']"
      assert_select "#gallery-card-integration-details[data-nk='details-table']" do
        assert_select "th[scope='row']", text: "Connected"
        assert_select "th[scope='row']", text: "Delivery target"
        assert_select "td", text: "Team operations channel"
      end
      assert_select "[data-slot='card-divider']", count: 1
      assert_select "#gallery-card-integration-actions[data-nk='button-group'] [data-nk='button']", count: 2
    end
  end

  test "card examples cover every size surface and divided form" do
    get_component("card")

    assert_select "#example-card-size-matrix" do
      NitroKit::Card::SIZES.each do |size|
        assert_select "article[data-nk='card'][data-size='#{size}'] > [data-slot='card-header'] [data-slot='card-actions']", count: 1
      end
    end
    assert_select "#example-card-surface-matrix" do
      NitroKit::Card::VARIANTS.each do |variant|
        assert_select "article[data-nk='card'][data-variant='#{variant}']", count: 1
      end
    end
    assert_select "#example-card-size-surface-matrix" do
      NitroKit::Card::SIZES.product(NitroKit::Card::VARIANTS).each do |size, variant|
        assert_select "article[data-nk='card'][data-size='#{size}'][data-variant='#{variant}']", count: 1
      end
    end

    assert_select "#example-card-form-configurations" do
      NitroKit::Card::SIZES.each do |size|
        form_id = "gallery-card-preferences-#{size}"
        assert_select "form##{form_id} input[role='switch']", count: 3
        assert_select "button[type='submit'][form='#{form_id}']", count: 1
        assert_select "button[type='reset'][form='#{form_id}']", count: 1
      end
    end

    assert_select "#gallery-card-security > [data-slot='card-header']", count: 3
    assert_select "#gallery-card-transactions > [data-slot='card-full'] [data-nk='table'] caption", text: "Transactions this week"
  end

  test "card examples cover touched media edges action states and responsive parents" do
    get_component("card")

    assert_select "#example-card-media-configurations" do
      assert_select "img[src='/gallery/card-landscape.svg'][alt]", count: 3
      NitroKit::Card::SIZES.each do |size|
        assert_select "[data-size='#{size}'] > [data-slot='card-full']:first-child", count: 1
      end
    end
    assert_select "#gallery-card-media-only > [data-slot='card-full']:only-child img[alt]", count: 1

    assert_select "#example-card-footer-states" do
      assert_select "button[aria-busy='true'][disabled]", count: 1
      assert_select "button[disabled]", count: 3
    end
    assert_select "[data-nk='card'] [data-nk='button'][data-variant='ghost']", count: 0

    assert_select "#example-card-responsive-collection [data-nk='grid'][data-cols='1 sm:2 lg:3']" do
      assert_select "article[data-nk='card']", count: 3
    end
  end

  test "table page covers every alignment dense nested content and empty structure" do
    get_component("table")

    assert_select "#gallery-table-alignment" do
      (NitroKit::Table::ALIGNMENTS - [ NitroKit::Table::DEFAULT_ALIGNMENT ]).each do |alignment|
        assert_select "thead [data-align='#{alignment}']", count: 1
        assert_select "tbody [data-align='#{alignment}']", count: 2
      end
      assert_select "[data-align='left']", count: 0
    end

    assert_select "#gallery-table-credentials" do
      assert_select "tbody tr", count: Gallery::Data.api_keys.size
      assert_select "tbody th[scope='row'] strong", count: Gallery::Data.api_keys.size
      assert_select "[data-nk='badge']", count: Gallery::Data.api_keys.size
      assert_select "[data-nk='button-group']", count: Gallery::Data.api_keys.size
      assert_select "[data-nk='button-group'] [data-nk='button']", count: Gallery::Data.api_keys.size * 2
    end

    assert_select "#gallery-table-integrations" do
      assert_select "tbody tr", count: Gallery::Data.integrations.size
      assert_select "[data-nk='badge']", count: Gallery::Data.integrations.size
      assert_select "td", text: /Sync pull requests and deployment activity/
    end

    assert_select "#gallery-table-empty" do
      assert_select "caption", text: "API credentials"
      assert_select "tbody td[colspan='3']", text: "No API credentials have been created."
    end
  end

  private

  def get_component(slug)
    get gallery_component_path(slug)
    assert_response :success
  end
end
