require "test_helper"

class OperationalGalleryFlowsTest < ActionDispatch::IntegrationTest
  FLOW_STATES = {
    "integration-management" => %w[catalog detail connected config-error mobile],
    "uploads" => %w[empty uploading complete error multiple long mobile],
    "activity-audit" => %w[normal filter empty dense error mobile],
    "changelog" => %w[latest archive empty long mobile],
    "help-center" => %w[faq search empty contact contact-validation contact-sent long mobile]
  }.freeze

  test "catalog appends every operational flow with exact routes and common block roots" do
    operational_slugs = Gallery::Catalog.entries(kind: :composition).map(&:slug).select { |slug| FLOW_STATES.key?(slug) }
    assert_equal FLOW_STATES.keys, operational_slugs

    FLOW_STATES.each do |slug, states|
      entry = Gallery::Catalog.fetch!(kind: :composition, slug:)

      assert_equal states, entry.states
      assert_equal %w[page-header container flex button-group button], entry.expected_roots
      states.each do |state|
        assert_equal "/gallery/compositions/#{slug}/#{state}", Gallery::Catalog.path_for(
          entry,
          routes: Rails.application.routes.url_helpers,
          state:
        )
      end
    end
  end

  test "every operational state is block-composed direct Phlex with labelled controls" do
    FLOW_STATES.each do |slug, states|
      states.each do |state|
        get_flow(slug, state)

        assert_select "div[data-gallery='page'][data-gallery-page='#{slug}'][data-gallery-state='#{state}']"
        assert_select "##{surface_id(slug)}[data-gallery='composition-surface'][data-gallery-composition='#{slug}']" \
                      "[data-gallery-composition-state='#{state}']"
        if slug == "activity-audit"
          assert_select "div[data-gallery='page'] > header nav [data-nk='button'][aria-current='page']", count: 1
        else
          assert_select "[data-gallery='composition-states'] > a[aria-current='page']", count: 1
        end
        assert_select "[data-gallery='example'][data-gallery-mode='full-width']", count: 1
        assert_select "[data-gallery='composition-surface'] [data-nk='container'] > [data-nk='flex'][data-dir='col']", count: 1
        assert_select "[data-gallery='composition-surface'] [data-nk='page-header']", count: 1
        assert_select "[data-gallery='composition-surface'] [data-nk='button-group']", minimum: 1
        assert_select "[data-gallery='composition-surface'] [data-nk='button']", minimum: 1
        assert_select "[data-gallery='example-canvas'] [class]", count: 0
        assert_select "[data-gallery='example-canvas'] [style]", count: 0
        assert_select "[data-gallery='example-canvas'] [data-nk-escape]", count: 0
        assert_labelled_controls
      end
    end
  end

  test "every operational flow renders in dark mode and every mobile state marks the narrow surface" do
    FLOW_STATES.each_key do |slug|
      get_flow(slug, FLOW_STATES.fetch(slug).first, theme: "dark")
      assert_select "html[data-theme='dark']"

      next unless FLOW_STATES.fetch(slug).include?("mobile")

      get_flow(slug, "mobile")
      assert_select "##{surface_id(slug)}[data-gallery-mobile='true']"
    end
  end

  test "integration catalog detail connection and configuration failure remain distinct" do
    get_flow("integration-management", "catalog")
    assert_select "#gallery-integration-catalog-section[data-nk='data-section']" do
      assert_select "> #gallery-integration-catalog-table[data-slot='data-section-table'][data-nk='table']", count: 1
      assert_select "[data-nk='table']", count: 1
    end
    assert_select "#gallery-integration-catalog-table tbody tr", count: 4
    assert_select "#gallery-integration-provider_slack-status[data-color='danger']", text: "Configuration error"
    assert_select "#gallery-integration-provider_sentry-action[href$='/integration-management/detail']", text: "View"

    get_flow("integration-management", "detail")
    assert_select "#gallery-integration-detail-grid[data-nk='grid'][data-cols='1 sm:2 lg:3']" do
      assert_select "> #gallery-integration-detail-card[data-nk='card']", count: 1
      assert_select "> #gallery-integration-configuration-section[data-nk='form-section']", count: 1
    end
    assert_select "[data-gallery='integration-detail-metadata'] dt", count: 3
    assert_select "#gallery-integration-configuration-form input[type='hidden'][name$='[provider]'][value='sentry']"
    assert_select "#gallery-integration-configuration-form input[type='url'][value^='https://']"

    get_flow("integration-management", "connected")
    assert_select "#gallery-integration-connected-alert[data-variant='success']", text: /GitHub is connected/
    assert_select "#gallery-integration-connected-section[data-nk='data-section'] > " \
                  "#gallery-integration-connected-table[data-nk='table'][data-slot='data-section-table']",
      count: 1
    assert_select "#gallery-integration-connected-table tbody tr", count: 2

    get_flow("integration-management", "config-error")
    assert_select "#gallery-integration-configuration-error[data-slot='form-section-status'][data-variant='error']"
    assert_select "#gallery-integration-configuration-form [data-nk='field'][data-state='invalid']", count: 3
    assert_select "input[name$='[webhook_url]'][value='http://expired.example.test'][aria-invalid='true']"
    assert_select "select[name$='[event]'] option[value='everything'][selected]", count: 0

    get_flow("integration-management", "mobile")
    assert_select "#gallery-integration-catalog-table thead th", count: 3
    assert_select "#gallery-integration-catalog-table tbody tr", count: 3
  end

  test "uploads preserve real multipart form semantics through every operational state" do
    FLOW_STATES.fetch("uploads").each do |state|
      get_flow("uploads", state)

      assert_select "#gallery-uploads-form[method='post'][enctype='multipart/form-data']" do
        assert_select "input[type='file'][name^='gallery_forms_upload_submission[files]']" \
                      "[accept*='.csv'][accept*='.ndjson'][accept*='.zip']:not([value])",
          count: 1
        assert_select "select[name='gallery_forms_upload_submission[destination]']", count: 1
        assert_select "textarea[name='gallery_forms_upload_submission[note]'][maxlength='240']", count: 1
        assert_select "input[type='checkbox'][name='gallery_forms_upload_submission[overwrite]']", count: 1
      end
      assert_select "#gallery-uploads-records-section[data-nk='data-section']", count: 1
    end

    get_flow("uploads", "empty")
    assert_select "#gallery-uploads-empty[data-nk='empty-state'][data-slot='data-section-empty-state']" do
      assert_select "h3", text: "No uploads yet"
    end

    get_flow("uploads", "uploading")
    assert_select "#gallery-uploads-surface[aria-busy='true']"
    assert_select "#gallery-uploads-uploading", text: /42\.8 MB of 119\.1 MB/
    assert_select "#gallery-uploads-form input[type='file'][multiple][disabled]"
    assert_select "#gallery-uploads-form input:not([type='hidden'])[disabled]", minimum: 2
    assert_select "#gallery-uploads-form select[disabled]"
    assert_select "#gallery-uploads-submit[disabled]", text: "Uploading files…"

    get_flow("uploads", "complete")
    assert_select "#gallery-uploads-complete[data-variant='success']", text: /stored and queued for validation/
    assert_select "#gallery-uploads-records-table tbody tr", count: 1

    get_flow("uploads", "error")
    assert_select "#gallery-uploads-error[data-variant='error']"
    assert_select "#gallery-uploads-form [data-nk='field'][data-state='invalid']", count: 2
    assert_select "#gallery_forms_upload_submission_files[aria-invalid='true']" \
                  "[aria-describedby*='errors']:not([value])"
    assert_select "#gallery-upload-record-1-status[data-color='danger']", text: "Failed"

    get_flow("uploads", "multiple")
    assert_select "#gallery-uploads-form input[type='file'][multiple]" \
                  "[name='gallery_forms_upload_submission[files][]']"
    assert_select "#gallery-uploads-records-table tbody tr", count: 3

    get_flow("uploads", "long")
    assert_select "#gallery-uploads-records-table", text: /international-research-production-reliability-regulatory/

    get_flow("uploads", "mobile")
    assert_select "#gallery-uploads-records-table thead th", count: 2
  end

  test "activity audit distinguishes filtering empty density service failure and mobile columns" do
    get_flow("activity-audit", "normal")
    assert_select "#gallery-activity-audit-filter-form[method='get']"
    assert_select "#gallery-activity-audit-results[data-nk='data-section'] > " \
                  "#gallery-activity-audit-table[data-nk='table'][data-slot='data-section-table']",
      count: 1
    assert_select "#gallery-activity-audit-table tbody tr", count: Gallery::OperationalData.audit_events.size
    assert_select "#gallery-activity-audit-pagination[data-nk='pagination'][aria-label='Audit history pages']"

    get_flow("activity-audit", "filter")
    assert_select "input[type='search'][name='audit[query]'][value='credential']"
    assert_select "select[name='audit[category]'] option[value='security'][selected]"
    assert_select "#gallery-activity-audit-table tbody tr", count: 1, text: /revoked a production API credential/

    get_flow("activity-audit", "empty")
    assert_select "#gallery-activity-audit-empty[data-nk='empty-state']", text: /No audit events match/
    assert_select "#gallery-activity-audit-table", count: 0

    get_flow("activity-audit", "dense")
    assert_select "#gallery-activity-audit-table tbody tr", count: Gallery::OperationalData.audit_events.size * 3

    get_flow("activity-audit", "error")
    assert_select "#gallery-activity-audit-error[data-variant='error']", text: /No export or audit record was changed/
    assert_select "#gallery-activity-audit-empty", text: /temporarily unavailable/

    get_flow("activity-audit", "mobile")
    assert_select "#gallery-activity-audit-table thead th", count: 3
  end

  test "changelog covers latest archive empty long and mobile release records" do
    get_flow("changelog", "latest")
    assert_select "#gallery-changelog-latest-card", text: /2\.0\.0-beta\.3.*Typed application sections/m
    assert_select "#gallery-changelog-latest-card li", count: 3
    assert_select "#gallery-changelog-table tbody tr", count: Gallery::OperationalData.changelog_entries.size

    get_flow("changelog", "archive")
    assert_select "#gallery-changelog-table tbody tr", count: Gallery::OperationalData.changelog_entries.size * 2

    get_flow("changelog", "empty")
    assert_select "#gallery-changelog-latest-card", count: 0
    assert_select "#gallery-changelog-empty[data-nk='empty-state']", text: /No archived releases/

    get_flow("changelog", "long")
    assert_select "#gallery-changelog-header", text: /regulated international workspaces/
    assert_select "#gallery-changelog-latest-card", text: /International Research, Production, Reliability Engineering/

    get_flow("changelog", "mobile")
    assert_select "#gallery-changelog-table thead th", count: 2
  end

  test "help center covers FAQ search zero results contact validation and durable outcome" do
    get_flow("help-center", "faq")
    assert_select "#gallery-help-center-faq[data-nk='accordion'][data-mode='single']" do
      assert_select "> [data-slot='accordion-item']", count: Gallery::OperationalData.help_questions.size
      assert_select "> details[data-slot='accordion-item'][name='gallery-help-center-faq'][open]", count: 1
      assert_select "> details[data-slot='accordion-item']:not([open])",
        count: Gallery::OperationalData.help_questions.size - 1
    end

    get_flow("help-center", "search")
    assert_select "#gallery-help-center-search-form[method='get']"
    assert_select "input[type='search'][name='help[query]'][value='upload']"
    assert_select "select[name='help[category]'] option[value='data'][selected]"
    assert_select "#gallery-help-center-results-table tbody tr", count: 1, text: /Which files can I upload/

    get_flow("help-center", "empty")
    assert_select "#gallery-help-center-empty[data-nk='empty-state']", text: /No help articles match/
    assert_select "#gallery-help-center-empty-contact[href$='/help-center/contact']"

    get_flow("help-center", "contact")
    assert_select "#gallery-help-center-contact-form" do
      assert_select "input[type='email'][name='gallery_forms_help_contact[email]'][value='ada@example.test'][required]"
      assert_select "select[name='gallery_forms_help_contact[category]'][required] option[value='integrations'][selected]"
      assert_select "input[name='gallery_forms_help_contact[subject]'][maxlength='120']"
      assert_select "textarea[name='gallery_forms_help_contact[message]'][minlength='20'][maxlength='2000']"
    end

    get_flow("help-center", "contact-validation")
    assert_select "#gallery-help-center-contact-error[data-slot='form-section-status'][data-variant='error']"
    assert_select "#gallery-help-center-contact-form [data-nk='field'][data-state='invalid']", count: 4

    get_flow("help-center", "contact-sent")
    assert_select "#gallery-help-center-contact-sent[data-variant='success']", text: /SUP-2048/
    assert_select "[data-gallery='support-request-metadata'] dt", count: 3

    get_flow("help-center", "long")
    assert_select "#gallery-help-center-header", text: /International Research, Production, Reliability Engineering/
    assert_select "#gallery-help-center-faq", text: /Regulatory Operations, and Customer Operations upload/

    get_flow("help-center", "mobile")
    assert_select "#gallery-help-center-faq > [data-slot='accordion-item']", count: 3
  end

  private

  def get_flow(slug, state, **query)
    get gallery_composition_path(slug:, state:, **query)
    assert_response :success
  end

  def surface_id(slug)
    "gallery-#{slug}-surface"
  end

  def assert_labelled_controls
    document = Nokogiri::HTML(response.body)
    document.css(
      "[data-gallery='composition-surface'] input:not([type='hidden'])[id], " \
        "[data-gallery='composition-surface'] select[id], " \
        "[data-gallery='composition-surface'] textarea[id]"
    ).each do |control|
      assert document.at_css("label[for='#{control['id']}']"), "missing label for #{control['id']}"
    end
  end
end
