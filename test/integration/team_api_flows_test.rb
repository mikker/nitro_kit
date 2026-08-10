require "test_helper"

class TeamApiFlowsTest < ActionDispatch::IntegrationTest
  FLOW_STATES = {
    "team-management" => %w[
      members multiple-teams search empty invite invite-validation loading role-change last-owner-validation
      remove-confirmation removed error dense mobile
    ],
    "api-credentials" => %w[
      list empty create validation loading reveal-once revoke-confirmation revoked expired error long dense mobile
    ]
  }.freeze

  test "catalog exposes stable deterministic routes for every team and credential state" do
    operation_slugs = Gallery::Catalog.entries(kind: :composition).map(&:slug).select { |slug| FLOW_STATES.key?(slug) }
    assert_equal FLOW_STATES.keys, operation_slugs

    FLOW_STATES.each do |slug, states|
      entry = Gallery::Catalog.fetch!(kind: :composition, slug:)
      assert_equal states, entry.states
      assert_equal %w[container flex button], entry.expected_roots

      states.each do |state|
        assert_equal "/gallery/compositions/#{slug}/#{state}", Gallery::Catalog.path_for(
          entry,
          routes: Rails.application.routes.url_helpers,
          state:
        )
      end
    end

    get gallery_composition_path(slug: "team-management", state: "invented")
    assert_response :not_found
    get gallery_composition_path(slug: "api-credentials", state: "invented")
    assert_response :not_found
  end

  test "every state is direct class-free Phlex with current navigation and labelled controls" do
    FLOW_STATES.each do |slug, states|
      states.each do |state|
        get_flow(slug, state)

        assert_select "div[data-gallery='page'][data-gallery-page='#{slug}'][data-gallery-state='#{state}']"
        assert_select "[data-gallery='composition-states'] a[aria-current='page']", count: 1
        container_id = slug == "team-management" ? "gallery-team-container" : "gallery-api-credentials-container"
        stack_id = slug == "team-management" ? "gallery-team-stack" : "gallery-api-credentials-stack"
        frame_id = slug == "team-management" ? "gallery-team-management-frame" : "gallery-api-credentials-frame"
        assert_select "[data-gallery='composition-surface']" do
          assert_select "##{container_id}[data-nk='container'][data-size='xl']" do
            assert_select "##{stack_id}[data-nk='flex'][data-dir='col'][data-gap='6'][data-align='stretch']" do
              assert_select "> turbo-frame##{frame_id}", count: 1
            end
          end
        end
        assert_select(
          "[data-gallery='composition-surface'] [data-nk='card'][id], " \
            "[data-gallery='composition-surface'] [data-nk='settings-section'][id], " \
            "[data-gallery='composition-surface'] [data-nk='data-section'][id], " \
            "[data-gallery='composition-surface'] [data-nk='danger-zone'][id], " \
            "[data-gallery='composition-surface'] turbo-frame > [data-nk='flex'][data-dir='col'][id]",
          minimum: 1
        )
        assert_select "[data-gallery='composition-surface'] [data-nk='button']", minimum: 1
        assert_select "div[data-gallery='page'] > [data-gallery='composition-header'] h1", count: 1
        assert_select "[data-gallery='section'] > [data-gallery='section-header'] h2", count: 1
        assert_select "[data-gallery='example'] > [data-gallery='example-header'] h3", count: 1
        assert_select "[data-gallery='example-canvas'] [class]", count: 0
        assert_select "[data-gallery='example-canvas'] [style]", count: 0
        assert_select "[data-gallery='example-canvas'] [data-nk-escape]", count: 0

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
  end

  test "team inventory search empty and pressure states preserve semantic operations" do
    get_flow("team-management", "members")
    assert_select "#gallery-team-members-section[data-nk='data-section']" do
      assert_select "> #gallery-team-members-table[data-slot='data-section-table'][data-nk='table']", count: 1
      assert_select "[data-nk='table']", count: 1
    end
    assert_select "#gallery-team-members-table table[aria-label='Workspace members']" do
      assert_select "caption", text: "2 workspace members"
      assert_select "thead th[scope='col']", count: 5
      assert_select "tbody tr", count: 2
      assert_select "tbody th[scope='row']", count: 2
    end
    assert_select "[role='group'][aria-label='Actions for Ada Lovelace']"
    assert_select "#gallery-team-member-mem_ada-change-role[href*='/team-management/last-owner-validation']"
    assert_select "#gallery-team-member-mem_ada-remove[href*='/team-management/last-owner-validation']"
    assert_select "#gallery-team-invitations-section[data-nk='data-section']" do
      assert_select "> [data-slot='data-section-header'] #gallery-team-footer-invite" \
        "[data-slot='data-section-actions'][data-nk='button']",
        count: 1
      assert_select "> #gallery-team-invitations-table[data-slot='data-section-table'][data-nk='table']"
    end
    assert_select "#gallery-team-invitations-table table[aria-label='Pending team invitations']" do
      assert_select "caption", text: "2 pending invitations"
      assert_select "tbody tr", count: 2
      assert_select "tbody", text: /katherine@example\.test/
    end

    get_flow("team-management", "multiple-teams")
    assert_select "#gallery-team-context-section[data-nk='settings-section']"
    assert_select "#gallery-team-context-status[data-variant='info']", text: /is selected/
    assert_select "#gallery-team-context-form[method='get'][data-turbo-frame='gallery-team-management-frame']" \
      "[data-turbo-action='replace']"
    assert_select "#team_context_team_id option", count: 3
    assert_select "#team_context_team_id option[selected][value='team_analytical']"
    assert_select "#gallery-team-members-table tbody tr", count: 2
    assert_select "#gallery-team-invitations-table tbody tr", count: 2

    get gallery_composition_path(
      slug: "team-management",
      state: "multiple-teams",
      team_context: { team_id: "team_apollo" }
    )
    assert_response :success
    assert_select "#team_context_team_id option[selected][value='team_apollo']"
    assert_select "#gallery-team-context-status", text: /Ada Lovelace is admin here/
    assert_select "#gallery-team-members-table tbody tr", count: 2
    assert_select "#gallery-team-invitations-empty", text: /No pending invitations match/
    assert_select "#gallery-team-member-mem_ada-change-role" \
                  "[href*='team_context%5Bteam_id%5D=team_apollo'][href*='member_id=mem_ada']"
    assert_select "#gallery-team-member-mem_grace-change-role" \
                  "[href*='/last-owner-validation'][href*='team_context%5Bteam_id%5D=team_apollo']"

    get gallery_composition_path(
      slug: "team-management",
      state: "role-change",
      team_context: { team_id: "team_apollo" },
      member_id: "mem_ada"
    )
    assert_response :success
    assert_select "#gallery-team-role-context", text: /Changing Ada Lovelace/
    assert_select "#gallery-team-role-form input[name$='[team_id]'][value='team_apollo']"
    assert_select "#gallery-team-role-form input[name$='[member_id]'][value='mem_ada']"

    get gallery_composition_path(
      slug: "team-management",
      state: "remove-confirmation",
      team_context: { team_id: "team_apollo" },
      member_id: "mem_ada"
    )
    assert_response :success
    assert_select "#gallery-team-remove-escape" \
                  "[href*='team_context%5Bteam_id%5D=team_apollo'][href*='member_id=mem_ada']"

    get_flow("team-management", "search")
    assert_select "#gallery-team-search-section[data-nk='settings-section']" do
      assert_select "> [data-slot='settings-section-form'] > #gallery-team-search-form", count: 1
    end
    assert_select "#gallery-team-search-form[method='get'][data-turbo-frame='gallery-team-management-frame']" \
      "[data-turbo-action='replace']"
    assert_select "#gallery-team-search-query[type='search'][name='team[query]'][value='Grace']"
    assert_select "#gallery-team-members-section", text: /1 current membership/
    assert_select "#gallery-team-members-table tbody tr", count: 1, text: /Grace Hopper/
    assert_select "#gallery-team-invitations-empty", text: /No pending invitations match/

    get_flow("team-management", "empty")
    assert_select "#gallery-team-empty-section[data-nk='data-section']" do
      assert_select "> #gallery-team-empty[data-slot='data-section-empty-state'][data-nk='empty-state']" do
        assert_select "h3[data-slot='empty-state-title']", text: "No teammates yet"
      end
    end
    assert_select "#gallery-team-empty-invite[href$='/team-management/invite']"

    get_flow("team-management", "dense")
    assert_select "[data-gallery-composition='team-management']"
    assert_select "#gallery-team-members-section", text: /8 current memberships/
    assert_select "#gallery-team-members-table tbody tr", count: 8
    assert_select "#gallery-team-members-table", text: /hedy\.lamarr@example\.test/
    assert_select "#gallery-team-invitations-table tbody tr", count: 2

    get_flow("team-management", "mobile")
    assert_select "[data-gallery-composition='team-management'][data-gallery-mobile='true']"
    assert_select "#gallery-team-members-table tbody tr", count: 2
    assert_select "#gallery-team-invitations-table tbody tr", count: 2
  end

  test "team invitation role and removal states use model errors disabled submission and explicit consequences" do
    get_flow("team-management", "invite")
    assert_select "#gallery-team-invitation-section[data-nk='settings-section']" do
      assert_select "> [data-slot='settings-section-form'] > #gallery-team-invitation-form", count: 1
    end
    assert_select "#gallery-team-invitation-form[data-turbo-frame='gallery-team-management-frame']"
    assert_select "input[type='email'][name='gallery_forms_team_invitation[email]'][required]"
    assert_select "select[name='gallery_forms_team_invitation[role]'][required] option", count: 3
    assert_select "textarea[name='gallery_forms_team_invitation[message]']", text: /release planning/

    get_flow("team-management", "invite-validation")
    assert_select "#gallery-team-invitation-error[data-variant='error']"
    assert_select "#gallery-team-invitation-section > #gallery-team-invitation-error[data-slot='settings-section-status']"
    assert_select "#gallery-team-invitation-form [data-nk='field'][data-state='invalid']", count: 3
    assert_select "#gallery-team-invitation-form [aria-invalid='true']", count: 3

    get_flow("team-management", "loading")
    assert_select "#gallery-team-invitation-form input:not([type='hidden'])[disabled]", count: 1
    assert_select "#gallery-team-invitation-form select[disabled]", count: 1
    assert_select "#gallery-team-invitation-form textarea[disabled]", count: 1
    assert_select "#gallery-team-invitation-submit[disabled][data-turbo-submits-with='Sending invitation…']"

    get_flow("team-management", "role-change")
    assert_select "#gallery-team-role-section[data-nk='settings-section']"
    assert_select "#gallery-team-role-form input[type='hidden'][name$='[action]'][value='change_role']"
    assert_select "#gallery-team-role-form input[type='hidden'][name$='[member_id]'][value='mem_grace']"
    assert_select "#gallery-team-role-context", text: /take effect immediately/
    assert_select "#gallery-team-role-form select[name$='[role]'] option[selected][value='viewer']"

    get_flow("team-management", "last-owner-validation")
    assert_select "#gallery-team-last-owner-section[data-nk='settings-section']" do
      assert_select "> #gallery-team-last-owner-error[data-slot='settings-section-status'][data-variant='error']"
      assert_select "> [data-slot='settings-section-form'] > #gallery-team-last-owner-form", count: 1
    end
    assert_select "#gallery-team-last-owner-error[role='alert']", text: /server rejected this change/i
    assert_select "#gallery-team-last-owner-form input[name$='[member_id]'][value='mem_ada']"
    assert_select "#gallery-team-last-owner-form select[name$='[role]'][aria-invalid='true']" do
      assert_select "option[value='member'][selected]"
    end
    assert_select "#gallery-team-last-owner-form [data-slot='field-error']", text: /every team must keep at least one owner/

    get_flow("team-management", "remove-confirmation")
    assert_select "#gallery-team-remove-zone[data-nk='danger-zone']" do
      assert_select "> [data-slot='danger-zone-confirmation'] > #gallery-team-remove-dialog[data-nk='dialog']"
      assert_select "> #gallery-team-remove-escape[data-slot='danger-zone-escape'][data-variant='default']"
    end
    assert_select "#gallery-team-remove-dialog[data-nk='dialog'][data-controller='nk--dialog'] dialog[open]" \
      "[aria-labelledby='gallery-team-remove-dialog-title']" \
      "[aria-describedby='gallery-team-remove-dialog-description']"
    assert_select "#gallery-team-remove-dialog-title", text: "Remove Grace Hopper?"
    assert_select "#gallery-team-remove-form input[type='email'][required][value='grace@example.test']"
    assert_select "#gallery-team-remove-submit[data-variant='destructive'][data-turbo-submits-with='Removing member…']"

    get_flow("team-management", "removed")
    assert_select "#gallery-team-removed[data-variant='success']", text: /sessions were revoked/

    get_flow("team-management", "error")
    assert_select "#gallery-team-error[data-variant='error']", text: /No access changed/
  end

  test "last-owner protection is a server-side form-model validation" do
    action = Gallery::OperationsFormExamples.team_member_action(:last_owner_invalid)

    assert_predicate action, :invalid?
    assert_includes action.errors[:role], "cannot be changed because every team must keep at least one owner"
  end

  test "credential list empty and pressure states keep scope recency and labelled actions visible" do
    get_flow("api-credentials", "list")
    assert_select "#gallery-api-credentials-section[data-nk='data-section']" do
      assert_select "> [data-slot='data-section-header'] #gallery-api-credentials-actions" \
                    "[data-slot='data-section-actions'][data-nk='button-group']",
        count: 1
      assert_select "> #gallery-api-credentials-table[data-slot='data-section-table'][data-nk='table']", count: 1
      assert_select "[data-nk='table']", count: 1
    end
    assert_select "#gallery-api-credentials-table table[aria-label='Workspace API credentials']" do
      assert_select "caption", text: "2 active API credentials"
      assert_select "thead th[scope='col']", count: 5
      assert_select "tbody tr", count: 2
      assert_select "tbody th[scope='row']", count: 2
    end
    assert_select "#gallery-api-key-key_production-access[data-color='warning']", text: "Read write"
    assert_select "[role='group'][aria-label='Actions for Production'] [data-nk='button']", count: 2
    assert_select "#gallery-api-credentials-table", text: /Never/

    get_flow("api-credentials", "empty")
    assert_select "#gallery-api-credentials-empty-section[data-nk='data-section']" do
      assert_select "> #gallery-api-credentials-empty[data-slot='data-section-empty-state'][data-nk='empty-state']" do
        assert_select "h3[data-slot='empty-state-title']", text: "No API credentials"
      end
    end
    assert_select "#gallery-api-credentials-empty-create[href$='/api-credentials/create']"

    get_flow("api-credentials", "long")
    assert_select "[data-gallery-composition='api-credentials']"
    assert_select "#gallery-api-credentials-table tbody tr", count: 1
    assert_select "#gallery-api-credentials-table", text: /Finance reconciliation and revenue recognition export/

    get_flow("api-credentials", "dense")
    assert_select "#gallery-api-credentials-section", text: /6 active credentials/
    assert_select "#gallery-api-credentials-table tbody tr", count: 6

    get_flow("api-credentials", "mobile")
    assert_select "[data-gallery-composition='api-credentials'][data-gallery-mobile='true']"
    assert_select "#gallery-api-credentials-table tbody tr", count: 2
  end

  test "credential creation reveal revocation and recovery states enforce the security lifecycle" do
    get_flow("api-credentials", "create")
    assert_select "#gallery-api-credential-section[data-nk='settings-section']" do
      assert_select "> [data-slot='settings-section-form'] > #gallery-api-credential-form", count: 1
    end
    assert_select "#gallery-api-credential-form[data-turbo-frame='gallery-api-credentials-frame']"
    assert_select "input[name='gallery_forms_api_key[name]'][required][value='Reporting']"
    assert_select "select[name='gallery_forms_api_key[access]'][required] option", count: 2
    assert_select "select[name='gallery_forms_api_key[expires_in_days]'][required] option", count: 4

    get_flow("api-credentials", "validation")
    assert_select "#gallery-api-credential-validation[data-variant='error']"
    assert_select "#gallery-api-credential-section > #gallery-api-credential-validation[data-slot='settings-section-status']"
    assert_select "#gallery-api-credential-form [data-nk='field'][data-state='invalid']", count: 3
    assert_select "#gallery-api-credential-form [aria-invalid='true']", count: 3

    get_flow("api-credentials", "loading")
    assert_select "#gallery-api-credential-form input:not([type='hidden'])[disabled]", count: 1
    assert_select "#gallery-api-credential-form select[disabled]", count: 2
    assert_select "#gallery-api-credential-submit[disabled][data-turbo-submits-with='Creating credential…']"

    get_flow("api-credentials", "reveal-once")
    assert_select "#gallery-api-credential-reveal-warning[data-variant='warning']", text: /shown once/
    assert_select "#gallery-api-credential-secret[readonly][value='nk_live_2M8Q_7uT9cK4dP6xR3vN8mL1sH5jF']"
    assert_select "#gallery-api-credential-copy[type='button'][data-credential='nk_live_2M8Q_7uT9cK4dP6xR3vN8mL1sH5jF']"
    assert_select "#gallery-api-credentials-footer-stored[href$='/api-credentials/list']"

    get_flow("api-credentials", "revoke-confirmation")
    assert_select "#gallery-api-credential-revoke-zone[data-nk='danger-zone']" do
      assert_select "> [data-slot='danger-zone-confirmation'] > #gallery-api-credential-revoke-dialog[data-nk='dialog']"
      assert_select "> #gallery-api-credential-revoke-escape[data-slot='danger-zone-escape'][data-variant='default']"
    end
    assert_select "#gallery-api-credential-revoke-dialog dialog[open]" \
      "[aria-labelledby='gallery-api-credential-revoke-dialog-title']" \
      "[aria-describedby='gallery-api-credential-revoke-dialog-description']"
    assert_select "#gallery-api-credential-revoke-form input[type='hidden'][name$='[key_id]'][value='key_production']"
    assert_select "#gallery-api-credential-revoke-form input[type='checkbox'][required][checked]"
    assert_select "#gallery-api-credential-revoke-submit[data-variant='destructive']"

    get_flow("api-credentials", "revoked")
    assert_select "#gallery-api-credential-revoked[data-variant='success']", text: /now fail authentication/

    get_flow("api-credentials", "expired")
    assert_select "#gallery-api-credential-expired[data-variant='warning']", text: /expired before it was installed/
    assert_select "#gallery-api-credentials-footer-replace[href$='/api-credentials/create']"

    get_flow("api-credentials", "error")
    assert_select "#gallery-api-credential-error[data-variant='error']", text: /still active/
    assert_select "#gallery-api-credentials-footer-retry[href$='/api-credentials/revoke-confirmation']"
  end

  private

  def get_flow(slug, state)
    get gallery_composition_path(slug:, state:)
    assert_response :success
  end
end
