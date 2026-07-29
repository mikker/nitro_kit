require "test_helper"

class PublicSystemMarketingFlowsTest < ActionDispatch::IntegrationTest
  FLOW_STATES = {
    "system-status" => %w[403 404 422 500 maintenance offline rate-limited degraded long mobile],
    "landing" => %w[default announcement customer-proof long mobile],
    "pricing" => %w[monthly annual comparison enterprise long mobile],
    "features" => %w[overview security automation collaboration long mobile],
    "contact" => %w[form validation sending sent unavailable long mobile],
    "checkout-result" => %w[invoice-issued bank-transfer-pending trial-started credit-applied manual-review long mobile]
  }.freeze

  FLOW_TITLES = {
    "system-status" => "System status and errors",
    "landing" => "Product landing",
    "pricing" => "Public pricing",
    "features" => "Product features",
    "contact" => "Public contact",
    "checkout-result" => "Checkout results"
  }.freeze

  test "catalog appends exact public system marketing and checkout-result routes" do
    public_slugs = Gallery::Catalog.entries(kind: :composition).map(&:slug).select { |slug| FLOW_STATES.key?(slug) }
    assert_equal FLOW_STATES.keys.sort, public_slugs.sort

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

    get gallery_composition_path(slug: "system-status", state: "invented")
    assert_response :not_found
  end

  test "every public state renders both themes through accepted leak-free composition" do
    FLOW_STATES.each do |slug, states|
      states.each do |state|
        %w[light dark].each do |theme|
          get_flow(slug, state, theme:)

          assert_select "html[data-theme='#{theme}']"
          assert_select "div[data-gallery='page'][data-gallery-page='#{slug}'][data-gallery-state='#{state}']"
          assert_select "[data-gallery-composition='#{slug}'][data-gallery-composition-state='#{state}']" do
            assert_select "> [data-nk='container'] > [data-nk='flex'][data-dir='col'][data-gap='6']" do
              assert_select "> [data-nk='page-header']", count: 1
            end
          end
          assert_select "nav[aria-label='#{FLOW_TITLES.fetch(slug)} states'] a[aria-current='page']", count: 1
          assert_select "[data-gallery='example-canvas'] [class]", count: 0
          assert_select "[data-gallery='example-canvas'] [style]", count: 0
          assert_select "[data-gallery='example-canvas'] [data-nk-escape]", count: 0
          assert_labelled_controls
        end
      end
    end
  end

  test "system states distinguish HTTP policy availability connectivity and recovery" do
    {
      "403" => [ "403", "policy_denied_2048" ],
      "404" => [ "404", "route_not_found_2048" ],
      "422" => [ "422", "unprocessable_change_2048" ],
      "500" => [ "500", "server_error_2048" ],
      "maintenance" => [ "Maintenance", "11:30 UTC" ],
      "offline" => [ "Offline", "browser_offline" ],
      "rate-limited" => [ "429", "42 seconds" ]
    }.each do |state, expected_copy|
      get_flow("system-status", state)

      assert_select "#gallery-system-status-alert[data-gallery-status-code]", text: /#{Regexp.escape(expected_copy.first)}/
      assert_select "#gallery-system-status-table[data-nk='details-table']", text: /#{Regexp.escape(expected_copy.last)}/
      assert_select "#gallery-system-status-actions [data-nk='button']", minimum: 1
    end

    get_flow("system-status", "degraded")
    assert_select "#gallery-system-status-alert[data-variant='warning']", text: /workspace access is available/i
    assert_select "#gallery-system-status-metrics [data-slot='stat-grid-stat']", count: 3
    assert_select "#gallery-system-status-metrics", text: /Webhook delivery/

    get_flow("system-status", "long")
    assert_select "#gallery-system-status-header", text: /International Research, Production/
    assert_select "#gallery-system-status-actions", text: /complete organization workspace/

    get_flow("system-status", "mobile")
    assert_select "[data-gallery-mobile='true']"
    assert_select "#gallery-system-status-actions [data-nk='button']", count: 1
  end

  test "landing page keeps product evidence announcement and proof focused" do
    get_flow("landing", "default")
    assert_select "#gallery-landing-results [data-slot='stat-grid-stat']", count: 3
    assert_select "#gallery-landing-feature-grid > [data-nk='card']", count: 3
    assert_select "#gallery-landing-announcement", count: 0

    get_flow("landing", "announcement")
    assert_select "#gallery-landing-announcement[data-variant='success']", text: /2.0 beta/

    get_flow("landing", "customer-proof")
    assert_select "#gallery-landing-proof-table tbody tr", count: 3
    assert_select "#gallery-landing-proof-table", text: /Zero runtime styling dependencies/

    get_flow("landing", "long")
    assert_select "#gallery-landing-header", text: /International Research, Production/

    get_flow("landing", "mobile")
    assert_select "#gallery-landing-feature-grid > [data-nk='card']", count: 2
  end

  test "pricing keeps cadence amounts comparison and enterprise policy caller-owned" do
    get_flow("pricing", "monthly")
    assert_select "#gallery-pricing-cadence [aria-current='page']", text: "Monthly"
    assert_select "#gallery-pricing-plan-team", text: /\$49 per month/
    assert_select "#gallery-pricing-plan-grid > [data-nk='card']", count: 3
    assert_select "#gallery-pricing-plan-grid [data-nk='typeset']", count: 3

    get_flow("pricing", "annual")
    assert_select "#gallery-pricing-cadence [aria-current='page']", text: "Annual"
    assert_select "#gallery-pricing-plan-team", text: /\$490 per year/
    assert_select "#gallery-pricing-cadence", text: /Two months included/

    get_flow("pricing", "comparison")
    assert_select "#gallery-pricing-comparison-table tbody tr", count: 3
    assert_select "#gallery-pricing-comparison-table thead th", count: 4

    get_flow("pricing", "enterprise")
    assert_select "#gallery-pricing-enterprise", text: /procurement process/

    get_flow("pricing", "long")
    assert_select "#gallery-pricing-plan-scale", text: /Regulatory Operations/

    get_flow("pricing", "mobile")
    assert_select "[data-gallery-mobile='true']"
    assert_select "#gallery-pricing-plan-grid > [data-nk='card']", count: 3
  end

  test "feature page filters one caller collection without adding product components" do
    get_flow("features", "overview")
    assert_select "#gallery-features-facts [data-slot='stat-grid-stat']", count: 3
    assert_select "#gallery-features-grid > [data-nk='card']", count: 6

    get_flow("features", "security")
    assert_select "#gallery-features-grid > [data-nk='card']", count: 1
    assert_select "#gallery-feature-accessible-contracts", text: /Visible interface contracts/

    get_flow("features", "automation")
    assert_select "#gallery-features-grid > [data-nk='card']", count: 2
    assert_select "#gallery-features-grid", text: /Rails-native forms/
    assert_select "#gallery-features-grid", text: /Hotwire-ready behavior/

    get_flow("features", "collaboration")
    assert_select "#gallery-features-grid > [data-nk='card']", count: 1
    assert_select "#gallery-feature-application-ownership"

    get_flow("features", "long")
    assert_select "#gallery-features-grid", text: /International Research, Production/

    get_flow("features", "mobile")
    assert_select "#gallery-features-grid > [data-nk='card']", count: 3
  end

  test "contact inquiry preserves Rails validation submission availability and durable result" do
    get_flow("contact", "form")
    assert_select "#gallery-contact-form" do
      assert_select "#contact_name[name='contact[name]'][value='Ada Lovelace'][required]"
      assert_select "#contact_email[type='email'][name='contact[email]'][value='ada@example.test'][required]"
      assert_select "#contact_topic[name='contact[topic]'] option[value='sales'][selected]"
      assert_select "#contact_message[name='contact[message]'][required]", text: /evaluating Nitro Kit/
    end

    get_flow("contact", "validation")
    assert_select "#gallery-contact-validation[data-variant='error']"
    assert_select "#gallery-contact-form [data-nk='field'][data-state='invalid']", count: 4
    assert_select "#contact_email[aria-invalid='true'][value='invalid']"

    get_flow("contact", "sending")
    assert_select "[data-gallery-composition='contact'][aria-busy='true']"
    assert_select "#gallery-contact-fieldset[disabled]"
    assert_select "#gallery-contact-submit[disabled]", text: "Sending inquiry…"

    get_flow("contact", "unavailable")
    assert_select "#gallery-contact-unavailable[data-variant='warning']", text: /temporarily unavailable/
    assert_select "#gallery-contact-fieldset[disabled]"

    get_flow("contact", "sent")
    assert_select "#gallery-contact-sent[data-variant='success']", text: /CON-2048/
    assert_select "#gallery-contact-sent-table[data-nk='details-table'] tbody tr", count: 4
    assert_select "#gallery-contact-form", count: 0

    get_flow("contact", "long")
    assert_select "#contact_company[value*='International Research, Production']"

    get_flow("contact", "mobile")
    assert_select "[data-gallery-mobile='true']"
    assert_select "#gallery-contact-form", count: 1
  end

  test "checkout result adds asynchronous and non-card outcomes without duplicating checkout" do
    {
      "invoice-issued" => [ "INV-3049", "Invoice issued" ],
      "bank-transfer-pending" => [ "BTR-2048", "Bank transfer pending" ],
      "trial-started" => [ "TRL-2048", "14-day trial" ],
      "credit-applied" => [ "CRD-2048", "credit covered" ],
      "manual-review" => [ "REV-2048", "manual review" ]
    }.each do |state, expected_copy|
      get_flow("checkout-result", state)

      assert_select "#gallery-checkout-result-page-alert[data-gallery-checkout-outcome='#{state}']", text: /#{expected_copy.last}/i
      assert_select "#gallery-checkout-result-page-table[data-nk='details-table']", text: /#{expected_copy.first}/
      assert_select "#gallery-checkout-result-page-actions [data-nk='button']", count: 2
    end

    checkout_states = Gallery::Catalog.fetch!(kind: :composition, slug: "checkout").states
    result_states = Gallery::Catalog.fetch!(kind: :composition, slug: "checkout-result").states
    assert_empty (result_states - %w[long mobile]) & (checkout_states - %w[long mobile])

    get_flow("checkout-result", "long")
    assert_select "#gallery-checkout-result-page-alert", text: /International Research, Production/
    assert_select "#gallery-checkout-result-page-table[data-nk='details-table']", text: /INV-INTERNATIONAL-RESEARCH-3049/

    get_flow("checkout-result", "mobile")
    assert_select "[data-gallery-mobile='true']"
    assert_select "#gallery-checkout-result-page-table[data-nk='details-table'] tbody tr", count: 4
  end

  private

  def get_flow(slug, state, theme: nil)
    get gallery_composition_path(slug:, state:, theme:)
    assert_response :success
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
