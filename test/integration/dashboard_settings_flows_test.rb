require "test_helper"

class DashboardSettingsFlowsTest < ActionDispatch::IntegrationTest
  DASHBOARD_STATES = %w[new active degraded loading dense mobile].freeze
  SETTINGS_STATES = %w[
    profile profile-validation profile-success security security-disabled notifications notifications-success
    integrations integrations-empty integrations-error appearance appearance-loading long-content mobile
  ].freeze

  test "catalog declares exact dashboard and settings state routes" do
    dashboard = Gallery::Catalog.fetch!(kind: :composition, slug: "dashboard")
    settings = Gallery::Catalog.fetch!(kind: :composition, slug: "settings")

    assert_equal DASHBOARD_STATES, dashboard.states
    assert_equal SETTINGS_STATES, settings.states
    assert_equal Gallery::Compositions::DashboardPage, dashboard.page
    assert_equal Gallery::Compositions::SettingsPage, settings.page
    assert_equal(
      "/gallery/compositions/dashboard/new",
      Gallery::Catalog.path_for(dashboard, routes: Rails.application.routes.url_helpers)
    )
    assert_equal(
      "/gallery/compositions/settings/profile",
      Gallery::Catalog.path_for(settings, routes: Rails.application.routes.url_helpers)
    )
  end

  test "every dashboard state renders navigation common blocks and a leak-free canvas" do
    DASHBOARD_STATES.each do |state|
      get_flow("dashboard", state)

      assert_select "#gallery-dashboard-surface[data-gallery-composition-state='#{state}']"
      assert_select "nav[aria-label='Workspace dashboard states'] [data-nk='button'][aria-current='page']",
        text: state.humanize
      assert_select "#gallery-dashboard-surface > " \
                    "#gallery-dashboard-container[data-nk='container'][data-size='xl'] > " \
                    "#gallery-dashboard-stack[data-nk='flex'][data-dir='col'][data-gap='6'][data-align='stretch']" do
        assert_select "> #gallery-dashboard-workspace-header[data-nk='page-header']" do
          assert_select "> h1[data-slot='page-header-title']"
        end
      end
      assert_select "#gallery-dashboard-workspace-actions[data-nk='button-group'][aria-label='Workspace actions']" do
        assert_select "[data-nk='button']", count: 2
      end
      assert_select "#gallery-dashboard-workspace-context[data-nk='flex'][data-dir='row']" do
        assert_select "#gallery-dashboard-workspace-status[data-nk='badge']"
        assert_select "#gallery-dashboard-members[data-nk='avatar-stack']"
      end
      assert_leak_free_canvas
    end
  end

  test "dashboard new and active states cover empty success metrics and activity" do
    get_flow("dashboard", "new")

    assert_select "#gallery-dashboard-new-success[data-variant='success']", text: /Workspace created/
    assert_select "#gallery-dashboard-empty-card[data-nk='empty-state']" do
      assert_select "[data-slot='empty-state-title']", text: "No activity yet"
      assert_select "#gallery-dashboard-empty-action[href='#new-project']", text: "Create the first project"
    end

    get_flow("dashboard", "active")

    assert_select "#gallery-dashboard-workspace-status[data-color='success']", text: "Operational"
    assert_select "#gallery-dashboard-operational[data-variant='success']", text: /All systems operational/
    assert_select "#gallery-dashboard-metrics[data-nk='stat-grid'] [data-slot='stat-grid-stat']", count: 3
    assert_select "#gallery-dashboard-metrics [data-key='usage']", text: /1,284,320/
    assert_select "#gallery-dashboard-activity-section[data-nk='data-section']"
    assert_select "#gallery-dashboard-activity[data-nk='table'] tbody tr", count: Gallery::Data.activities.size
    assert_select "#gallery-dashboard-activity tbody th[scope='row']", count: Gallery::Data.activities.size
  end

  test "dashboard chart placeholder preserves normal loading error dense and mobile semantics" do
    get_flow("dashboard", "active")

    assert_select "#gallery-dashboard-request-chart[data-gallery='chart-placeholder']" \
                  "[data-gallery-chart-state='normal'][aria-labelledby='gallery-dashboard-request-chart-caption']"
    assert_select "#gallery-dashboard-request-chart-caption", text: "Hourly API requests for July 13, 2026"
    assert_select "#gallery-dashboard-request-chart-plot[role='img']" \
                  "[aria-labelledby='gallery-dashboard-request-chart-plot-title " \
                  "gallery-dashboard-request-chart-plot-description']" do
      assert_select "title#gallery-dashboard-request-chart-plot-title", text: "Hourly API request volume"
      assert_select "desc#gallery-dashboard-request-chart-plot-description", text: /peak of 96,420/
      assert_select "polyline[vector-effect='non-scaling-stroke']", count: 1
    end
    assert_select "[data-gallery='chart-summary'] dt", count: 3

    get_flow("dashboard", "loading")

    assert_select "#gallery-dashboard-request-chart[data-gallery-chart-state='loading'][aria-busy='true']"
    assert_select "#gallery-dashboard-request-chart-loading", text: /24 hourly request totals/
    assert_select "#gallery-dashboard-request-chart-plot", count: 0

    get_flow("dashboard", "degraded")

    assert_select "#gallery-dashboard-request-chart[data-gallery-chart-state='error']"
    assert_select "#gallery-dashboard-request-chart-error[data-variant='error']", text: /No usage data was changed/
    assert_select "#gallery-dashboard-request-chart-retry[href='#request-volume']", text: "Retry request chart"

    get_flow("dashboard", "dense")

    assert_select "#gallery-dashboard-request-chart[data-gallery-chart-state='dense']"
    assert_select "#gallery-dashboard-request-chart-plot polyline[points]"
    assert_select "[data-gallery='chart-summary']", text: /84,212 requests/

    get_flow("dashboard", "mobile")

    assert_select "#gallery-dashboard-request-chart[data-gallery-chart-state='mobile']"
    assert_select "#gallery-dashboard-request-chart-caption", text: /Analytical Engines — Research and Production/
    assert_select "#gallery-dashboard-request-chart-plot-description", text: /narrow viewport/
  end

  test "dashboard degraded state exposes incident impact records and recovery" do
    get_flow("dashboard", "degraded")

    assert_select "#gallery-dashboard-workspace-status[data-color='danger']", text: "Degraded"
    assert_select "#gallery-dashboard-degraded-alert[data-variant='error']", text: /Eight Slack deliveries/
    assert_select "#gallery-dashboard-incident-card" do
      assert_select "#gallery-dashboard-incident-status[data-color='danger']", text: "Investigating"
      assert_select "#gallery-dashboard-retry-deliveries[type='button']", text: "Retry failed deliveries"
    end
    assert_select "#gallery-dashboard-integrations tbody tr", count: Gallery::Data.integrations.size
    assert_select "#gallery-dashboard-integrations tbody th[scope='row']", count: Gallery::Data.integrations.size
  end

  test "dashboard loading dense and mobile states pressure availability and content" do
    get_flow("dashboard", "loading")

    assert_select "#gallery-dashboard-surface[aria-busy='true']"
    assert_select "#gallery-dashboard-workspace-status[data-color='info']", text: "Loading"
    assert_select "#gallery-dashboard-workspace-actions [data-nk='button'][disabled]", count: 2
    assert_select "[id^='gallery-dashboard-loading-card-'][data-nk='card']", count: 3
    assert_select "#gallery-dashboard-loading-action[disabled]", text: "Refreshing…"

    get_flow("dashboard", "dense")

    assert_select "#gallery-dashboard-dense-members tbody tr", count: Gallery::Data.members.size
    assert_select "#gallery-dashboard-dense-activity tbody tr", count: Gallery::Data.activities.size
    assert_select "#gallery-dashboard-dense-invoices tbody tr", count: Gallery::Data.invoices.size
    assert_select "#gallery-dashboard-dense-members [data-nk='badge']", count: Gallery::Data.members.size

    get_flow("dashboard", "mobile")

    assert_select "#gallery-dashboard-surface[data-gallery-mobile='true']"
    assert_select "#gallery-dashboard-mobile-alert", text: /deliberately long workspace name/
    assert_select "#gallery-dashboard-mobile-card li", count: Gallery::Data.activities.size
    assert_select "#gallery-dashboard-mobile-action[href='#activity']", text: /complete activity history/
  end

  test "every settings state renders section navigation common atoms and a leak-free canvas" do
    SETTINGS_STATES.each do |state|
      get_flow("settings", state)

      assert_select "#gallery-settings-surface[data-gallery-composition-state='#{state}']"
      assert_select "nav[aria-label='Workspace settings states'] [data-nk='button'][aria-current='page']",
        text: state.humanize
      assert_select "#gallery-settings-layout nav[data-slot='settings-layout-navigation'][aria-label='Settings sections']" do
        assert_select "ul[data-slot='settings-layout-items'] > li[data-slot='settings-layout-item']", count: 5
        assert_select "a[data-slot='settings-layout-item-link'][aria-current='page']", count: 1
      end
      assert_select "#gallery-settings-surface > " \
                    "#gallery-settings-container[data-nk='container'][data-size='xl'] > " \
                    "#gallery-settings-stack[data-nk='flex'][data-dir='col'][data-gap='6'][data-align='stretch'] > " \
                    "#gallery-settings-layout[data-nk='settings-layout']",
        count: 1
      assert_select "#gallery-settings-layout > [data-slot='settings-layout-content'] > [data-nk]", minimum: 1
      assert_leak_free_canvas
    end
  end

  test "profile settings preserve Rails values help validation success and mobile pressure" do
    get_flow("settings", "profile")

    assert_select "#gallery-settings-profile-section[data-nk='form-section']" do
      assert_select "> [data-slot='form-section-form'] > #gallery-settings-profile-form", count: 1
    end
    assert_select "#gallery-settings-profile-form" do
      assert_select "#gallery-settings-profile-fieldset[data-nk='fieldset']"
      assert_select "#gallery-settings-profile-fields[data-nk='field-group'] > [data-nk='field']", count: 4
      assert_select "input#profile_name[name='profile[name]'][value='Ada Lovelace'][required]"
      assert_select "input#profile_email[name='profile[email]'][value='ada@example.test'][required]"
      assert_select "select#profile_time_zone[name='profile[time_zone]'] option[value='Europe/Copenhagen'][selected]"
      assert_select "textarea#profile_bio[name='profile[bio]'][maxlength='280']", text: /reliable interfaces/
      assert_select "#gallery-settings-profile-submit[type='submit'][data-turbo-submits-with='Saving profile…']"
    end

    get_flow("settings", "profile-validation")

    assert_select "#gallery-settings-profile-section > " \
                  "#gallery-settings-profile-error[data-slot='form-section-status'][data-variant='error']",
      text: /Email is invalid/
    assert_select "#gallery-settings-profile-form [data-nk='field'][data-state='invalid']", count: 4
    assert_select "#profile_email[aria-invalid='true'][aria-describedby='profile_email-errors']"
    assert_select "#profile_email-errors", text: /Email is invalid/

    get_flow("settings", "profile-success")
    assert_select "#gallery-settings-profile-success[data-variant='success']", text: /Profile saved/
    assert_select "#gallery-settings-profile-form", count: 1

    get_flow("settings", "mobile")
    assert_select "#gallery-settings-surface[data-gallery-mobile='true']"
    assert_select "#profile_name[value*='Orbital Mechanics and Flight Research']"
    assert_select "#profile_email[value*='analytical-engines-research-and-production']"
  end

  test "security settings cover password semantics sessions and fully disabled mutation" do
    get_flow("settings", "security")

    assert_select "#gallery-settings-security-section[data-nk='form-section']" do
      assert_select "> [data-slot='form-section-form'] > #gallery-settings-security-form", count: 1
    end
    assert_select "#gallery-settings-sessions-section[data-nk='data-section']" do
      assert_select "> #gallery-settings-sessions-table[data-slot='data-section-table'][data-nk='table']", count: 1
      assert_select "[data-nk='table']", count: 1
    end
    assert_select "#gallery-settings-security-form" do
      assert_select "#gallery-settings-security-fieldset:not([disabled])"
      assert_select "input#security_current_password[type='password'][name='security[current_password]']" \
                    "[required][autocomplete='current-password']:not([value])"
      assert_select "input#security_new_password[type='password'][name='security[new_password]']" \
                    "[required][autocomplete='new-password']:not([value])"
      assert_select "select#security_session_timeout[name='security[session_timeout]'] option[value='30'][selected]"
      assert_select "#security_two_factor[role='switch'][name='security[two_factor]'][checked]"
      assert_select "#gallery-settings-security-submit:not([disabled])"
    end
    assert_select "#gallery-settings-sessions-table tbody tr", count: 2
    assert_select "#gallery-settings-session-1-action[disabled]", text: "Current session"
    assert_select "#gallery-settings-session-2-action:not([disabled])", text: "Revoke"

    get_flow("settings", "security-disabled")

    assert_select "#gallery-settings-security-disabled[data-variant='warning']"
    assert_select "#gallery-settings-security-fieldset[disabled]"
    assert_select "#gallery-settings-security-form input:not([type='hidden'])[disabled]", minimum: 3
    assert_select "#gallery-settings-security-form select[disabled]", count: 1
    assert_select "#gallery-settings-security-submit[disabled]", text: "Security changes disabled"
    assert_select "#gallery-settings-sessions-table [data-nk='button'][disabled]", count: 2
  end

  test "notification settings preserve switch checkbox radio and success semantics" do
    get_flow("settings", "notifications")

    assert_select "#gallery-settings-notifications-section[data-nk='form-section']" do
      assert_select "> [data-slot='form-section-form'] > #gallery-settings-notifications-form", count: 1
    end
    assert_select "#gallery-settings-notifications-form" do
      assert_select "#notifications_security_alerts[role='switch'][name='notifications[security_alerts]'][checked]"
      assert_select "#notifications_deployment_alerts[role='switch'][name='notifications[deployment_alerts]'][checked]"
      assert_select "#notifications_weekly_digest[type='checkbox'][name='notifications[weekly_digest]']:not([checked])"
      assert_select "#notifications_delivery_frequency[data-nk='radio-button-group'][aria-required='true']" do
        assert_select "input[type='radio'][name='notifications[delivery_frequency]'][required]", count: 3
        assert_select "input[value='immediately'][checked]"
      end
      assert_select "#gallery-settings-notifications-submit[type='submit']"
    end

    get_flow("settings", "notifications-success")
    assert_select "#gallery-settings-notifications-success[data-variant='success']", text: /preferences saved/
    assert_select "#gallery-settings-notifications-form", count: 1
  end

  test "integration settings cover populated empty error and long content states" do
    get_flow("settings", "integrations")

    assert_select "#gallery-settings-integrations-heading-card"
    assert_select "[id^='gallery-settings-integration-int_'][data-nk='card']", count: Gallery::Data.integrations.size
    assert_select "[id^='gallery-settings-integration-int_'][data-nk='badge']", count: Gallery::Data.integrations.size
    assert_select "#gallery-settings-integration-int_slack-status[data-color='danger']", text: "Action required"

    get_flow("settings", "integrations-empty")
    assert_select "#gallery-settings-integrations-empty-section[data-nk='data-section']" do
      assert_select "> #gallery-settings-integrations-empty[data-slot='data-section-empty-state'][data-nk='empty-state']" do
        assert_select "h3[data-slot='empty-state-title']", text: "No integrations connected"
      end
    end
    assert_select "#gallery-settings-integrations-empty-action[href='#integration-catalog']"
    assert_select "[id^='gallery-settings-integration-int_']", count: 0

    get_flow("settings", "integrations-error")
    assert_select "#gallery-settings-integrations-error[data-variant='error']", text: /connection expired/
    assert_select "#gallery-settings-integration-int_slack"
    assert_select "#gallery-settings-integration-int_slack-action[href='#integration-int_slack']", text: "Manage"

    get_flow("settings", "long-content")
    assert_select "#gallery-settings-integrations-heading-card", text: /customer-visible incident updates/
    assert_select "[id^='gallery-settings-integration-int_'][data-nk='card']", count: Gallery::Data.integrations.size
    assert_select "#gallery-settings-integration-int_github", text: /preserves deterministic delivery history/
  end

  test "appearance settings preserve native choice relationships and loading state" do
    get_flow("settings", "appearance")

    assert_select "#gallery-settings-appearance-section[data-nk='form-section']" do
      assert_select "> [data-slot='form-section-form'] > #gallery-settings-appearance-form", count: 1
    end
    assert_select "#gallery-settings-appearance-form" do
      assert_select "#appearance_theme[data-nk='radio-button-group'] input[type='radio']", count: 3
      assert_select "#appearance_theme input[value='system'][checked]"
      assert_select "#appearance_density input[value='comfortable'][checked]"
      assert_select "#appearance_reduce_motion[role='switch']:not([checked])"
      assert_select "#gallery-settings-appearance-submit:not([disabled])", text: "Save appearance"
    end

    get_flow("settings", "appearance-loading")

    assert_select "#gallery-settings-surface[aria-busy='true']"
    assert_select "#gallery-settings-appearance-loading", text: /synchronizing across open sessions/
    assert_select "#gallery-settings-appearance-fieldset[disabled]"
    assert_select "#gallery-settings-appearance-form input:not([type='hidden'])[disabled]", count: 6
    assert_select "#gallery-settings-appearance-submit[disabled]", text: "Applying settings…"
  end

  private

  def get_flow(slug, state)
    get gallery_composition_path(slug:, state:)
    assert_response :success
  end

  def assert_leak_free_canvas
    assert_select "[data-gallery='example-canvas'] [class]", count: 0
    assert_select "[data-gallery='example-canvas'] [style]", count: 0
    assert_select "[data-gallery='example-canvas'] [data-nk-escape]", count: 0
  end
end
