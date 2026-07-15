require "test_helper"

class AuthOnboardingFlowsTest < ActionDispatch::IntegrationTest
  FLOW_STATES = {
    "sign-in" => %w[default invalid loading success mobile],
    "password-reset" => %w[request validation sent update expired loading],
    "email-verification" => %w[pending verified expired invalid-token long-copy],
    "invitation-acceptance" => %w[valid validation loading accepted expired invalid-token mobile],
    "account-creation" => %w[default validation loading success long-copy mobile],
    "onboarding" => %w[workspace workspace-validation team integrations review loading complete resume mobile]
  }.freeze

  test "catalog exposes stable deterministic routes for every auth and onboarding state" do
    auth_slugs = Gallery::Catalog.entries(kind: :flow).map(&:slug).select { |slug| FLOW_STATES.key?(slug) }
    assert_equal FLOW_STATES.keys, auth_slugs

    FLOW_STATES.each do |slug, states|
      entry = Gallery::Catalog.fetch!(kind: :flow, slug:)
      assert_equal states, entry.states

      states.each do |state|
        assert_equal "/gallery/flows/#{slug}/#{state}", Gallery::Catalog.path_for(
          entry,
          routes: Rails.application.routes.url_helpers,
          state:
        )
      end
    end

    get gallery_flow_path(slug: "sign-in", state: "invented")
    assert_response :not_found
  end

  test "every state is direct class-free Phlex with one current state link and labelled native controls" do
    FLOW_STATES.each do |slug, states|
      states.each do |state|
        get gallery_flow_path(slug:, state:)

        assert_response :success
        assert_select "div[data-gallery='page'][data-gallery-page='#{slug}'][data-gallery-state='#{state}']"
        assert_select "[data-gallery='flow-states'] a[aria-current='page']", count: 1
        assert_select "[data-gallery='example'][data-gallery-mode='full-width'] [data-gallery='example-canvas']", count: 1
        assert_select "main[data-nk='auth-shell'][data-gallery='flow-surface']" \
          "[data-gallery-flow='#{slug}']", count: 1 do
          assert_select "> [data-nk='container'][data-size='md'] > " \
            "[data-nk='flex'][data-dir='col'][data-gap='6'][data-align='stretch'] > turbo-frame", count: 1
          assert_select "turbo-frame > [data-nk='card'][id]", count: 1
        end
        assert_select "[data-gallery='flow-surface'] [data-nk='card'][id]", minimum: 1
        assert_select "div[data-gallery='page'] > [data-gallery='flow-header'] h1", count: 1
        assert_select "[data-gallery='section'] > [data-gallery='section-header'] h2", count: 1
        assert_select "[data-gallery='example'] > [data-gallery='example-header'] h3", count: 1
        assert_select "[data-gallery='flow-surface'] h4[data-slot='card-title']", count: 1
        assert_select "[data-gallery='example-canvas'] [class]", count: 0
        assert_select "[data-gallery='example-canvas'] [style]", count: 0
        assert_select "[data-gallery='example-canvas'] [data-nk-escape]", count: 0

        document = Nokogiri::HTML(response.body)
        document.css("[data-gallery='flow-surface'] input:not([type='hidden'])[id], " \
          "[data-gallery='flow-surface'] select[id], " \
          "[data-gallery='flow-surface'] textarea[id]").each do |control|
          assert document.at_css("label[for='#{control['id']}']"), "missing label for #{control['id']}"
        end
      end
    end
  end

  test "sign-in covers validation disabled submission success and mobile pressure" do
    get_flow("sign-in", "invalid")
    assert_select "turbo-frame#gallery-sign-in-frame form#gallery-sign-in-form"
    assert_select "#gallery-sign-in-error[data-nk='alert'][data-variant='error']"
    assert_select "input[type='email'][aria-invalid='true'][aria-describedby*='errors']"
    assert_select "input[type='password'][value]", count: 0

    get_flow("sign-in", "loading")
    assert_select "#gallery-sign-in-form input:not([type='hidden'])[disabled]", minimum: 3
    assert_select "#gallery-sign-in-submit[disabled][data-turbo-submits-with='Signing in…']", text: "Signing in…"

    get_flow("sign-in", "success")
    assert_select "#gallery-sign-in-success[data-variant='success']"
    assert_select "#gallery-sign-in-continue[href='#workspace']", text: "Continue to workspace"

    get_flow("sign-in", "mobile")
    assert_select "[data-gallery-flow='sign-in'][data-gallery-mobile='true'] input[type='email'][value*='+analytical-engines']"
  end

  test "password reset preserves hidden tokens new-password semantics and recoverable expiration" do
    get_flow("password-reset", "validation")
    assert_select "#gallery-password-reset-error[data-variant='error']"
    assert_select "input[type='email'][aria-invalid='true']"

    get_flow("password-reset", "update")
    assert_select "#gallery-password-reset-update-form input[type='hidden'][name*='[token]'][value^='verify_']"
    assert_select "#gallery-password-reset-update-form input[type='password'][autocomplete='new-password']", count: 2
    assert_select "#gallery-password-reset-update-form input[type='password'][value]", count: 0

    get_flow("password-reset", "expired")
    assert_select "#gallery-password-reset-expired[data-variant='warning']", text: /expired/
    assert_select "#gallery-password-reset-secondary[href$='/password-reset/request']", text: "Request a new link"

    get_flow("password-reset", "sent")
    assert_select "#gallery-password-reset-sent", text: /katherine\.johnson\+analytical-engines@example\.test/
  end

  test "email verification separates pending success expiration invalid tokens and long copy" do
    get_flow("email-verification", "pending")
    assert_select "#gallery-email-verification-form[data-turbo-frame='gallery-email-verification-frame']"
    assert_select "#gallery-email-verification-status[data-color='info']", text: "Pending verification"

    get_flow("email-verification", "verified")
    assert_select "#gallery-email-verification-alert[data-variant='success']"
    assert_select "#gallery-email-verification-continue[href='#workspace']"

    get_flow("email-verification", "expired")
    assert_select "#gallery-email-verification-alert[data-variant='warning']", text: /expired/
    assert_select "#gallery-email-verification-resend", text: "Send a fresh link"

    get_flow("email-verification", "invalid-token")
    assert_select "#gallery-email-verification-alert[data-variant='error']", text: /invalid/
    assert_select "#gallery-email-verification-support[href='mailto:support@example.test']"

    get_flow("email-verification", "long-copy")
    assert_select "#gallery-email-verification-alert", text: /forwarding rules/
  end

  test "invitation acceptance carries workspace role validation loading and token recovery" do
    get_flow("invitation-acceptance", "valid")
    assert_select "#gallery-invitation-form input[type='hidden'][name*='[token]'][value^='invite_']"
    assert_select "#gallery-invitation-role[data-color='info']", text: "Administrator"
    assert_select "#gallery-invitation-card", text: /Analytical Engines — Research and Production/

    get_flow("invitation-acceptance", "validation")
    assert_select "#gallery-invitation-validation[data-variant='error']"
    assert_select "#gallery-invitation-form [data-nk='field'][data-state='invalid']", minimum: 3

    get_flow("invitation-acceptance", "loading")
    assert_select "#gallery-invitation-form input:not([type='hidden'])[disabled]", minimum: 3
    assert_select "#gallery-invitation-submit[disabled]", text: "Joining workspace…"

    %w[expired invalid-token].each do |state|
      get_flow("invitation-acceptance", state)
      assert_select "#gallery-invitation-token-error", text: state == "expired" ? /expired/ : /invalid/
      assert_select "#gallery-invitation-recovery[href='mailto:ada@example.test']"
    end

    get_flow("invitation-acceptance", "mobile")
    assert_select "[data-gallery-flow='invitation-acceptance'][data-gallery-mobile='true']"
  end

  test "account creation covers consent validation privacy loading and verification handoff" do
    get_flow("account-creation", "validation")
    assert_select "#gallery-account-creation-validation[data-variant='error']"
    assert_select "#gallery-account-creation-form [data-nk='field'][data-state='invalid']", minimum: 4

    get_flow("account-creation", "loading")
    assert_select "#gallery-account-creation-form input:not([type='hidden'])[disabled]", minimum: 4
    assert_select "#gallery-account-creation-submit[disabled]", text: "Creating account…"

    get_flow("account-creation", "long-copy")
    assert_select "#gallery-account-creation-privacy", text: /administrative audit events/

    get_flow("account-creation", "success")
    assert_select "#gallery-account-creation-success[data-variant='success']"
    assert_select "#gallery-account-creation-verify[href$='/email-verification/pending']"

    get_flow("account-creation", "mobile")
    assert_select "[data-gallery-flow='account-creation'][data-gallery-mobile='true']"
  end

  test "onboarding covers every step validation native choices loading completion and resume" do
    get_flow("onboarding", "workspace")
    assert_select "#gallery-onboarding-progress", text: "Step 1 of 4"
    assert_select "[data-gallery='flow-progress'] li[aria-current='step']", text: /Name your workspace/
    assert_select "#gallery-onboarding-workspace-form select[name*='[team_size]']"

    get_flow("onboarding", "workspace-validation")
    assert_select "#gallery-onboarding-validation[data-variant='error']"
    assert_select "#gallery-onboarding-workspace-form [data-nk='field'][data-state='invalid']", minimum: 2

    get_flow("onboarding", "team")
    assert_select "#gallery-onboarding-team-form textarea[name*='[invitees]']", text: /grace@example\.test/

    get_flow("onboarding", "integrations")
    assert_select "#gallery-onboarding-integrations-form fieldset[data-nk='radio-button-group']" do
      assert_select "legend", text: "First integration"
      assert_select "input[type='radio'][name*='[integration]']", count: 3
    end

    get_flow("onboarding", "review")
    assert_select "[data-gallery='flow-summary'] dt", count: 4
    assert_select "#gallery-onboarding-review-form input[type='checkbox'][required][checked]"

    get_flow("onboarding", "loading")
    assert_select "#gallery-onboarding-review-form input[type='checkbox'][disabled]"
    assert_select "#gallery-onboarding-review-submit[disabled]", text: "Creating workspace…"

    get_flow("onboarding", "complete")
    assert_select "#gallery-onboarding-complete[data-variant='success']", text: /two pending invitations/
    assert_select "#gallery-onboarding-open-workspace[href='#workspace']"

    get_flow("onboarding", "resume")
    assert_select "#gallery-onboarding-resume[data-variant='warning']", text: /July 13, 2026/
    assert_select "#gallery-onboarding-resume-setup[href$='/onboarding/integrations']"

    get_flow("onboarding", "mobile")
    assert_select "[data-gallery-flow='onboarding'][data-gallery-mobile='true'] textarea", text: /katherine@example\.test/
  end

  private

  def get_flow(slug, state)
    get gallery_flow_path(slug:, state:)
    assert_response :success
  end
end
