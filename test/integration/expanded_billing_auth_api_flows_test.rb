require "test_helper"

class ExpandedBillingAuthApiFlowsTest < ActionDispatch::IntegrationTest
  FLOW_STATES = {
    "checkout" => %w[
      review payment validation processing succeeded failed requires-action cancelled refunded empty-cart long mobile
    ],
    "account-security" => %w[
      recovery-request recovery-validation recovery-sent reset reset-expired account-locked unlock-sent
      two-factor-challenge two-factor-invalid recovery-code recovery-code-invalid trusted-device loading success long mobile
    ],
    "onboarding-branches" => %w[
      choose-path company solo import invite-team skip-team integration skip-integration review-company review-solo
      validation saving complete resume long mobile
    ],
    "api-webhooks" => %w[
      list empty detail create validation loading delivery-succeeded delivery-failed retrying disabled signing-secret
      dense long mobile
    ]
  }.freeze

  test "catalog exposes the exact additive flow matrix and stable routes" do
    entries = Gallery::Catalog.entries(kind: :composition).select { |entry| FLOW_STATES.key?(entry.slug) }

    assert_equal FLOW_STATES.keys.sort, entries.map(&:slug).sort

    entries.each do |entry|
      assert_equal FLOW_STATES.fetch(entry.slug), entry.states
      assert_equal "/gallery/compositions/#{entry.slug}/#{entry.states.first}", Gallery::Catalog.path_for(
        entry,
        routes: Rails.application.routes.url_helpers
      )

      entry.states.each do |state|
        assert_equal "/gallery/compositions/#{entry.slug}/#{state}", Gallery::Catalog.path_for(
          entry,
          routes: Rails.application.routes.url_helpers,
          state:
        )
      end
    end

    FLOW_STATES.each_key do |slug|
      get gallery_composition_path(slug:, state: "invented")
      assert_response :not_found
    end
  end

  test "all 58 states render accepted roots labelled controls and leak-free direct Phlex" do
    FLOW_STATES.each do |slug, states|
      states.each do |state|
        get_flow(slug, state)

        assert_select "div[data-gallery='page'][data-gallery-page='#{slug}'][data-gallery-state='#{state}']"
        assert_select "[data-gallery='composition-states'] a[aria-current='page']", count: 1, text: state.humanize
        assert_select "#gallery-#{slug}-surface[data-gallery-composition='#{slug}'][data-gallery-composition-state='#{state}']"
        assert_select "#gallery-#{slug}-header[data-nk='page-header'] > h1[data-slot='page-header-title']"
        assert_select "#gallery-#{slug}-header [data-slot='page-header-actions'][data-nk='button-group'] [data-nk='button']", minimum: 1
        assert_select "[data-gallery='example-canvas'] [data-nk='container']", minimum: 1
        assert_select "[data-gallery='example-canvas'] [data-nk='flex'][data-dir='col']", minimum: 1
        assert_select "[data-gallery='example-canvas'] [class]", count: 0
        assert_select "[data-gallery='example-canvas'] [style]", count: 0
        assert_select "[data-gallery='example-canvas'] [data-nk-escape]", count: 0

        document = Nokogiri::HTML(response.body)
        document.css(
          "[data-gallery='composition-surface'] input:not([type='hidden'])[id], " \
            "[data-gallery='composition-surface'] select[id], " \
            "[data-gallery='composition-surface'] textarea[id]"
        ).each do |control|
          assert document.at_css("label[for='#{control['id']}']"), "missing label for #{control['id']} in #{slug}/#{state}"
        end
      end
    end
  end

  test "every family renders dark long and narrow pressure without changing its contract" do
    FLOW_STATES.each_key do |slug|
      get_flow(slug, "long", theme: "dark")

      assert_select "html[data-theme='dark']"
      assert_select "#gallery-#{slug}-surface[data-gallery-mobile]", count: 0
      assert_select "[data-gallery='example-canvas'] [class]", count: 0

      get_flow(slug, "mobile", theme: "dark")

      assert_select "html[data-theme='dark']"
      assert_select "#gallery-#{slug}-surface[data-gallery-mobile='true']"
      assert_select "[data-gallery='example-canvas'] [data-nk='button']", minimum: 1
      assert_select "[data-gallery='example-canvas'] [class]", count: 0
    end
  end

  test "checkout covers review card entry provider outcomes cancellation refunds and empty state" do
    get_flow("checkout", "review")
    assert_select "#gallery-checkout-review-grid[data-nk='stat-grid'] [data-slot='stat-grid-stat']", count: 3
    assert_select "#gallery-checkout-review-actions[data-nk='toolbar']"
    assert_select "#gallery-checkout-continue[href$='/checkout/payment']"

    get_flow("checkout", "payment")
    assert_select "#gallery-checkout-payment-section[data-nk='form-section']"
    assert_select "#gallery-checkout-payment-form" do
      assert_select "input[autocomplete='cc-name'][required]"
      assert_select "input[autocomplete='cc-number'][inputmode='numeric'][required]"
      assert_select "input[autocomplete='cc-exp'][required]"
      assert_select "input[type='email'][autocomplete='email'][required]"
      assert_select "#gallery-checkout-payment-submit[data-variant='primary']"
    end

    get_flow("checkout", "validation")
    assert_select "#gallery-checkout-payment-error[data-slot='form-section-status'][data-variant='error']"
    assert_select "#gallery-checkout-payment-form [data-nk='field'][data-state='invalid']", count: 5

    get_flow("checkout", "processing")
    assert_select "#gallery-checkout-surface[aria-busy='true']"
    assert_select "#gallery-checkout-payment-form input:not([type='hidden'])[disabled]", count: 5
    assert_select "#gallery-checkout-payment-submit[disabled]", text: /Authorizing payment/

    get_flow("checkout", "succeeded")
    assert_select "#gallery-checkout-result-alert[data-variant='success']", text: /CHK-2048/
    assert_select "[data-gallery='checkout-result-metadata'][data-nk='details-table'] tbody tr", count: 2
    assert_select "#gallery-checkout-result-action", text: "Open workspace"

    get_flow("checkout", "failed")
    assert_select "#gallery-checkout-failed-section[data-nk='form-section']"
    assert_select "#gallery-checkout-failed-alert[data-variant='error']", text: /declined/
    assert_select "#gallery-checkout-retry-form", count: 1

    get_flow("checkout", "requires-action")
    assert_select "#gallery-checkout-action-alert[data-variant='warning']", text: /3-D Secure/
    assert_select "#gallery-checkout-provider-action[href='#provider-challenge']"

    get_flow("checkout", "cancelled")
    assert_select "#gallery-checkout-result-alert[data-variant='warning']", text: /No charge/

    get_flow("checkout", "refunded")
    assert_select "#gallery-checkout-result", text: /RFN-2048/
    assert_select "#gallery-checkout-result", text: /Visa ending in 4242/

    get_flow("checkout", "empty-cart")
    assert_select "#gallery-checkout-empty[data-nk='empty-state']"
    assert_select "#gallery-checkout-empty-action[href='#plans']"
  end

  test "account security covers discovery-safe recovery locks 2FA codes and browser trust" do
    FLOW_STATES.fetch("account-security").each do |state|
      get_flow("account-security", state)
      assert_select "#gallery-account-security-shell[data-nk='auth-shell']"
    end

    get_flow("account-security", "recovery-validation")
    assert_select "#gallery-account-security-recovery-error[data-variant='error']", text: /no account information was disclosed/i
    assert_select "#gallery-account-security-recovery-form [data-state='invalid']", count: 1

    get_flow("account-security", "loading")
    assert_select "#gallery-account-security-surface[aria-busy='true']"
    assert_select "#gallery-account-security-recovery-submit[disabled]"

    get_flow("account-security", "reset")
    assert_select "#gallery-account-security-reset-form input[type='hidden'][name='password_reset[token]'][value='reset_4F8M']"
    assert_select "#gallery-account-security-reset-form input[type='password'][autocomplete='new-password']", count: 2

    get_flow("account-security", "reset-expired")
    assert_select "#gallery-account-security-message[data-nk='empty-state']", text: /No password or session changed/

    get_flow("account-security", "account-locked")
    assert_select "#gallery-account-security-locked-alert[data-variant='error']", text: /15 minutes/
    assert_select "#gallery-account-security-unlock[href$='/account-security/unlock-sent']"

    get_flow("account-security", "two-factor-invalid")
    assert_select "#gallery-account-security-two-factor-error[data-variant='error']", text: /One attempt remains/
    assert_select "#gallery-account-security-two-factor-form input[autocomplete='one-time-code'][pattern='[0-9]{6}'][aria-invalid='true']"

    get_flow("account-security", "recovery-code-invalid")
    assert_select "#gallery-account-security-code-error[data-variant='error']", text: /already used/
    assert_select "#gallery-account-security-code-form [data-state='invalid']", count: 1

    get_flow("account-security", "trusted-device")
    assert_select "#gallery-account-security-trust-warning[data-variant='warning']", text: /private device/
    assert_select "#gallery-account-security-trust-form input[type='checkbox'][name='trusted_device[trusted]']"
  end

  test "branched onboarding keeps company personal and import paths explicit through review and resume" do
    get_flow("onboarding-branches", "choose-path")
    assert_select "#gallery-onboarding-branches-paths[data-nk='grid'] > [data-nk='card']", count: 3
    %w[company solo import].each do |branch|
      assert_select "#gallery-onboarding-path-#{branch}-action[href$='/onboarding-branches/#{branch}']"
    end

    get_flow("onboarding-branches", "company")
    assert_select "#gallery-onboarding-company-section[data-nk='form-section']"
    assert_select "#gallery-onboarding-company-form input[name='company[workspace_name]'][value='Analytical Engines']"

    get_flow("onboarding-branches", "solo")
    assert_select "#gallery-onboarding-solo-form input[name='solo[workspace_name]'][value=\"Ada's research\"]"

    get_flow("onboarding-branches", "import")
    assert_select "#gallery-onboarding-import-form[enctype='multipart/form-data']"
    assert_select "#gallery-onboarding-import-form input[type='file'][accept='.json,.zip']"

    get_flow("onboarding-branches", "skip-team")
    assert_select "#gallery-onboarding-skipped-alert", text: /Team invitations skipped/
    assert_select "#gallery-onboarding-skipped-card [data-nk='button']", count: 2

    get_flow("onboarding-branches", "integration")
    assert_select "#gallery-onboarding-integrations-section[data-nk='data-section']"
    assert_select "#gallery-onboarding-integrations-table tbody tr", count: 3

    get_flow("onboarding-branches", "review-company")
    assert_select "#gallery-onboarding-review-table[data-nk='details-table'] tbody tr", count: 6
    assert_select "#gallery-onboarding-review-section [data-slot='data-section-actions'] [data-nk='button']", count: 2

    get_flow("onboarding-branches", "review-solo")
    assert_select "#gallery-onboarding-review-table[data-nk='details-table'] tbody tr", count: 4

    get_flow("onboarding-branches", "validation")
    assert_select "#gallery-onboarding-company-error[data-variant='error']"
    assert_select "#gallery-onboarding-company-form [data-state='invalid']", count: 3

    get_flow("onboarding-branches", "saving")
    assert_select "#gallery-onboarding-branches-surface[aria-busy='true']"
    assert_select "#gallery-onboarding-company-submit[disabled]"

    get_flow("onboarding-branches", "complete")
    assert_select "#gallery-onboarding-complete[data-nk='empty-state'] [data-slot='empty-state-action']", count: 2

    get_flow("onboarding-branches", "resume")
    assert_select "#gallery-onboarding-resume-card", text: /team invitations not completed/
  end

  test "API webhooks cover endpoint inventory configuration delivery attempts secrets and recovery" do
    get_flow("api-webhooks", "list")
    assert_select "#gallery-api-webhooks-list-section[data-nk='data-section']"
    assert_select "#gallery-api-webhooks-table table[aria-label='Webhook endpoints'] tbody tr", count: 3
    assert_select "#gallery-api-webhook-production-status[data-color='danger']", text: "Failing"

    get_flow("api-webhooks", "empty")
    assert_select "#gallery-api-webhooks-empty-section[data-nk='data-section']"
    assert_select "#gallery-api-webhooks-empty[data-nk='empty-state'] h3[data-slot='empty-state-title']"
    assert_select "#gallery-api-webhooks-empty [data-slot='empty-state-action']", count: 2

    get_flow("api-webhooks", "detail")
    assert_select "#gallery-api-webhooks-detail-grid[data-nk='stat-grid'] [data-slot='stat-grid-stat']", count: 3
    assert_select "#gallery-api-webhooks-deliveries-table tbody tr", count: 1

    get_flow("api-webhooks", "create")
    assert_select "#gallery-api-webhooks-form-section[data-nk='form-section']"
    assert_select "#gallery-api-webhooks-form input[type='url'][value='https://api.example.test/hooks/nitro']"
    assert_select "#gallery-api-webhooks-form [data-nk='checkbox-group'] input[type='checkbox']", count: 4

    get_flow("api-webhooks", "validation")
    assert_select "#gallery-api-webhooks-form-error[data-variant='error']"
    assert_select "#gallery-api-webhooks-form [data-state='invalid']", count: 2
    assert_select "#gallery-api-webhooks-events[aria-invalid='true']"

    get_flow("api-webhooks", "loading")
    assert_select "#gallery-api-webhooks-surface[aria-busy='true']"
    assert_select "#gallery-api-webhooks-submit[disabled]"

    get_flow("api-webhooks", "delivery-succeeded")
    assert_select "#gallery-api-webhooks-delivery-alert[data-variant='success']", text: /HTTP 202/
    assert_select "#gallery-api-webhooks-deliveries-table tbody tr", count: 1

    get_flow("api-webhooks", "delivery-failed")
    assert_select "#gallery-api-webhooks-delivery-alert[data-variant='error']", text: /HTTP 500/
    assert_select "#gallery-api-webhooks-deliveries-table tbody tr", count: 3

    get_flow("api-webhooks", "retrying")
    assert_select "#gallery-api-webhooks-delivery-alert[data-variant='warning']", text: /Attempt 3 of 8/
    assert_select "#gallery-api-webhooks-deliveries-table", text: /Scheduled 10:52 UTC/

    get_flow("api-webhooks", "disabled")
    assert_select "#gallery-api-webhooks-disabled-alert[data-variant='warning']", text: /No new deliveries/
    assert_select "#gallery-api-webhooks-enable", text: "Enable endpoint"

    get_flow("api-webhooks", "signing-secret")
    assert_select "#gallery-api-webhooks-secret[readonly][value='whsec_7P3F9J2M4Q8R']"
    assert_select "#gallery-api-webhooks-copy-secret[data-secret='whsec_7P3F9J2M4Q8R']"

    get_flow("api-webhooks", "dense")
    assert_select "#gallery-api-webhooks-table tbody tr", count: 10
    assert_select "#gallery-api-webhooks-table", text: /Reliability engineering incident coordination/
  end

  private

  def get_flow(slug, state, theme: nil)
    get gallery_composition_path(slug:, state:, theme:)
    assert_response :success
  end
end
