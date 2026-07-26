require "test_helper"

class GalleryBillingUsersTest < ActionDispatch::IntegrationTest
  FLOW_STATES = {
    "billing" => %w[
      plans payment-method payment-validation payment-loading payment-updated invoices invoice-detail invoice-empty
      cancellation cancellation-validation cancellation-loading cancelled mobile
    ],
    "users" => %w[index detail search empty loading error bulk bulk-confirmation bulk-complete mobile]
  }.freeze

  test "catalog exposes every billing and users route with stable state order" do
    FLOW_STATES.each do |slug, states|
      entry = Gallery::Catalog.fetch!(kind: :composition, slug:)
      assert_equal states, entry.states

      states.each do |state|
        assert_equal "/gallery/compositions/#{slug}/#{state}", Gallery::Catalog.path_for(
          entry,
          routes: Rails.application.routes.url_helpers,
          state:
        )
      end
    end
  end

  test "every state is direct class-free Phlex with one current route and labelled controls" do
    FLOW_STATES.each do |slug, states|
      states.each do |state|
        get_flow(slug, state)

        assert_select "div[data-gallery='page'][data-gallery-page='#{slug}'][data-gallery-state='#{state}']"
        assert_select "[data-gallery='composition-states'] a[aria-current='page']", count: 1
        assert_select "[data-gallery='composition-surface']" do
          assert_select "#gallery-#{slug}-container[data-nk='container'][data-size='xl']" do
            assert_select "#gallery-#{slug}-stack[data-nk='flex'][data-dir='col'][data-gap='6'][data-align='stretch']" do
              assert_select "> turbo-frame#gallery-#{slug}-frame", count: 1
            end
          end
        end
        assert_select(
          "[data-gallery='example-canvas'] [data-nk='card'][id], " \
            "[data-gallery='example-canvas'] [data-nk='form-section'][id], " \
            "[data-gallery='example-canvas'] [data-nk='data-section'][id], " \
            "[data-gallery='example-canvas'] [data-nk='danger-zone'][id]",
          minimum: 1
        )
        assert_select "[data-gallery='example-canvas'] [data-nk='button']", minimum: 1
        assert_select "[data-gallery='example-canvas'] [class]", count: 0
        assert_select "[data-gallery='example-canvas'] [style]", count: 0
        assert_select "[data-gallery='example-canvas'] [data-nk-escape]", count: 0

        document = Nokogiri::HTML(response.body)
        controls = document.css(
          "[data-gallery='composition-surface'] input:not([type='hidden'])[id], " \
            "[data-gallery='composition-surface'] select[id], " \
            "[data-gallery='composition-surface'] textarea[id]"
        )
        controls.each do |control|
          assert document.at_css("label[for='#{control['id']}']"), "missing label for #{control['id']}"
        end
      end
    end
  end

  test "billing plans expose pricing current state features and decisions" do
    get_flow("billing", "plans")

    assert_select "#gallery-billing-plans-stack[data-nk='flex'][data-dir='col'][data-gap='6'][data-align='stretch']"
    assert_select "#gallery-billing-plan-grid[data-gallery='billing-plan-grid'][data-nk='grid'][data-cols='1 sm:2 lg:3']" \
                  "[aria-label='Available plans']"
    assert_select "[data-gallery='billing-plan-grid'] [data-nk='card']", count: 3
    assert_select "#gallery-billing-current-plan[data-color='success']", text: "Current: Team"
    assert_select "#gallery-billing-plan_team-badge", text: "Current plan"
    assert_select "#gallery-billing-plan_team-choose[aria-disabled='true']", text: "Manage Team plan"
    assert_select "#gallery-billing-plan_business-choose[href='#choose-plan_business']", text: "Choose Business"
    assert_select "#gallery-billing-plan_business", text: /Unlimited members.*Audit log.*Priority support/m
  end

  test "payment method covers native autocomplete validation loading and success" do
    get_flow("billing", "payment-method")
    assert_select "#gallery-billing-payment-card[data-nk='form-section']" do
      assert_select "> [data-slot='form-section-form'] > #gallery-billing-current-payment[data-nk='alert']", count: 1
      assert_select "> [data-slot='form-section-form'] > #gallery-billing-payment-form", count: 1
    end
    assert_select "#gallery-billing-payment-actions[data-nk='toolbar']"
    assert_select "#gallery-billing-payment-form[data-turbo-frame='gallery-billing-frame']"
    assert_select "input[name*='[cardholder_name]'][autocomplete='cc-name'][required]"
    assert_select "input[name*='[card_number]'][autocomplete='cc-number'][inputmode='numeric'][pattern='[0-9]{16}']"
    assert_select "input[name*='[expiry]'][autocomplete='cc-exp'][pattern]"
    assert_select "input[type='email'][name*='[billing_email]'][autocomplete='email']"
    assert_select "input[name*='[postal_code]'][autocomplete='postal-code']"

    get_flow("billing", "payment-validation")
    assert_select "#gallery-billing-payment-validation[data-slot='form-section-status'][data-variant='error']",
      text: /Card number must be 16 digits/
    assert_select "#gallery-billing-payment-form [data-nk='field'][data-state='invalid']", count: 5
    assert_select "#gallery-billing-payment-form input[aria-invalid='true'][aria-describedby*='errors']", count: 5

    get_flow("billing", "payment-loading")
    assert_select "#gallery-billing-payment-form input:not([type='hidden'])[disabled]", count: 5
    assert_select "#gallery-billing-payment-submit[disabled][data-turbo-submits-with='Saving payment method…']",
      text: "Saving payment method…"

    get_flow("billing", "payment-updated")
    assert_select "#gallery-billing-payment-updated[data-variant='success']", text: /Future Team plan charges/
    assert_select "[data-gallery='billing-payment-summary'] dt", count: 3
    assert_select "#gallery-billing-payment-updated-continue[href$='/billing/invoices']"
  end

  test "invoice history detail and empty states preserve financial record semantics" do
    get_flow("billing", "invoices")
    assert_select "#gallery-billing-invoices-card[data-nk='data-section']" do
      assert_select "> [data-slot='data-section-header'] " \
                    "#gallery-billing-invoice-history-actions[data-slot='data-section-actions']",
        count: 1
      assert_select "> #gallery-billing-invoice-table[data-slot='data-section-table'][data-nk='table']", count: 1
      assert_select "[data-nk='table']", count: 1
    end
    assert_select "#gallery-billing-invoices-stack > #gallery-billing-invoices-card + " \
                  "#gallery-billing-invoice-pagination-bar[data-nk='pagination-bar']",
      count: 1
    assert_select "#gallery-billing-invoice-table table" do
      assert_select "caption", text: /Invoices for Analytical Engines/
      assert_select "thead th[scope='col']", count: 5
      assert_select "tbody tr", count: Gallery::Data.invoices.size
      assert_select "tbody th[scope='row']", count: Gallery::Data.invoices.size
    end
    assert_select "#gallery-billing-inv_may_2026-status[data-color='warning']", text: "Refunded"
    assert_select "#gallery-billing-invoice-summary", text: "Showing the three most recent of 36 invoices"
    assert_select "#gallery-billing-invoice-pagination[data-nk='pagination'][aria-label='Invoice history pages']" do
      assert_select "span#gallery-billing-invoice-pagination-page-12[aria-current='page']" \
                    ":not([aria-disabled]):not([tabindex]):not([href])", text: "12"
      assert_select "#gallery-billing-invoice-pagination-next[aria-disabled='true'][tabindex='-1']:not([href])"
      assert_select "[data-slot='pagination-ellipsis-label']", text: "Pages 2 through 9 omitted"
    end
    assert_equal(
      "/gallery/compositions/billing/invoices?page=11",
      css_select("#gallery-billing-invoice-pagination-previous").first["href"]
    )

    get_flow("billing", "invoice-detail")
    assert_select "#gallery-billing-invoice-detail-card", text: /NK-2026-0713/
    assert_select "[data-gallery='billing-invoice-metadata'] dt", count: 4
    assert_select "#gallery-billing-invoice-lines table" do
      assert_select "caption", text: "Line items for NK-2026-0713"
      assert_select "tbody tr", count: 3
      assert_select "tbody tr:last-child", text: /Total paid.*\$49\.00/m
    end
    assert_select "#gallery-billing-invoice-download[download='NK-2026-0713.pdf']"

    get_flow("billing", "invoice-empty")
    assert_select "#gallery-billing-invoice-empty-card[data-nk='data-section']" do
      assert_select "> #gallery-billing-invoice-empty[data-slot='data-section-empty-state']" \
                    "[data-nk='empty-state'] h3[data-slot='empty-state-title']",
        text: "No invoices yet"
    end
    assert_select "#gallery-billing-invoice-empty", text: /Starter is free/
    assert_select "#gallery-billing-invoice-empty-plans[href$='/billing/plans']", text: "Compare paid plans"
  end

  test "billing cancellation requires impact reason consent and preserves recoverable outcomes" do
    get_flow("billing", "cancellation")
    assert_select "#gallery-billing-cancellation-card[data-nk='danger-zone']" do
      assert_select "> [data-slot='danger-zone-confirmation'] > " \
                    "#gallery-billing-cancellation-confirmation[data-nk='flex'][data-dir='col']",
        count: 1
      assert_select "> #gallery-billing-cancellation-keep[data-slot='danger-zone-escape']", count: 1
    end
    assert_select "#gallery-billing-cancellation-warning[data-variant='warning']", text: /18 active members/
    assert_select "#gallery-billing-cancellation-form fieldset[data-nk='radio-button-group']" do
      assert_select "legend", text: "Why are you cancelling?"
      assert_select "input[type='radio'][required]", count: 5
    end
    assert_select "#gallery-billing-cancellation-form textarea[name*='[feedback]']"
    assert_select "#gallery-billing-cancellation-form input[type='checkbox'][required][checked]"
    assert_select "#gallery-billing-cancellation-submit[data-variant='destructive']"
    assert_select "#gallery-billing-cancellation-keep[href$='/billing/plans']"

    get_flow("billing", "cancellation-validation")
    assert_select "#gallery-billing-cancellation-validation[data-variant='error']", text: /Confirmed must be accepted/
    assert_select "#gallery-billing-cancellation-form [data-nk='field'][data-state='invalid']", count: 3

    get_flow("billing", "cancellation-loading")
    assert_select "#gallery-billing-cancellation-form input:not([type='hidden'])[disabled]", count: 6
    assert_select "#gallery-billing-cancellation-form textarea[disabled]"
    assert_select "#gallery-billing-cancellation-submit[disabled]", text: "Cancelling plan…"

    get_flow("billing", "cancelled")
    assert_select "#gallery-billing-cancelled[data-variant='success']", text: /No further charges/
    assert_select "[data-gallery='billing-cancellation-summary'] dt", count: 3
    assert_select "#gallery-billing-reactivate[href='#reactivate']", text: "Reactivate Team plan"

    get_flow("billing", "mobile")
    assert_select "[data-gallery-composition='billing'][data-gallery-mobile='true']"
    assert_select "#gallery-billing-mobile-card", text: /accounts-payable\+international-research-and-production@example\.test/
  end

  test "user index and detail retain dense identity status activity and action semantics" do
    get_flow("users", "index")
    assert_select "#gallery-users-index-section[data-nk='data-section']" do
      assert_select "> [data-slot='data-section-header'] " \
                    "#gallery-users-index-actions[data-slot='data-section-actions'][data-nk='button-group']",
        count: 1
      assert_select "> #gallery-users-index-table[data-slot='data-section-table'][data-nk='table']", count: 1
      assert_select "[data-nk='table']", count: 1
    end
    assert_select "#gallery-users-index-section + #gallery-users-index-pagination-bar[data-nk='pagination-bar']", count: 1
    assert_select "#gallery-users-index-table table" do
      assert_select "caption", text: "All workspace users"
      assert_select "thead th[scope='col']", count: 6
      assert_select "tbody tr", count: Gallery::Compositions::UsersPage::USERS.size
      assert_select "tbody th[scope='row']", count: Gallery::Compositions::UsersPage::USERS.size
      assert_select "[data-nk='avatar']", count: Gallery::Compositions::UsersPage::USERS.size
    end
    assert_select "#gallery-users-index-table-mem_annie-status[data-color='danger']", text: "Suspended"
    assert_select "#gallery-users-index-summary", text: "Showing 1–8 of 128 workspace users"
    assert_select "#gallery-users-index-pagination[data-nk='pagination'][aria-label='Workspace user pages']" do
      assert_select "#gallery-users-index-pagination-previous[aria-disabled='true'][tabindex='-1']:not([href])"
      assert_select "span#gallery-users-index-pagination-page-1[aria-current='page']" \
                    ":not([aria-disabled]):not([tabindex]):not([href])", text: "1"
      assert_select "[data-slot='pagination-ellipsis-label']", text: "Pages 4 through 15 omitted"
    end
    assert_equal(
      "/gallery/compositions/users/index?page=2",
      css_select("#gallery-users-index-pagination-next").first["href"]
    )
    assert_select "#gallery-users-invite[href='#invite-user']"

    get_flow("users", "detail")
    assert_select "#gallery-users-detail-avatar[data-nk='avatar'][data-size='lg']"
    assert_select "#gallery-users-detail-status[data-color='success']", text: "Active"
    assert_select "[data-gallery='user-detail-metadata'] dt", count: 5
    assert_select "#gallery-users-detail-activity table" do
      assert_select "caption", text: "Recent activity for Grace Hopper"
      assert_select "tbody tr", count: 3
    end
    assert_select "#gallery-users-detail-actions[role='group'][aria-label='Actions for Grace Hopper']"
  end

  test "user search empty loading and error states keep queries recovery and announcements" do
    get_flow("users", "search")
    assert_select "#gallery-users-search-section[data-nk='data-section']" do
      assert_select "> #gallery-users-search-results[data-slot='data-section-table'][data-nk='table']", count: 1
      assert_select "[data-nk='table']", count: 1
    end
    assert_select "#gallery-users-search-section + #gallery-users-search-pagination-bar[data-nk='pagination-bar']", count: 1
    assert_select "#gallery-users-search-form[method='get'][data-turbo-frame='gallery-users-frame']"
    assert_select "input[type='search'][name*='[query]'][value='a']"
    assert_select "select[name*='[status]'] option[value='active'][selected]"
    assert_select "#gallery-users-search-summary[aria-live='polite']", text: /11–15 of 37 active users/
    assert_select "#gallery-users-search-results tbody tr", count: 5
    assert_select "#gallery-users-search-pagination[data-nk='pagination'][aria-label='Filtered workspace user pages']" do
      assert_select "span#gallery-users-search-pagination-page-3[aria-current='page']" \
                    ":not([aria-disabled]):not([tabindex]):not([href])", text: "3"
      assert_select "[data-slot='pagination-ellipsis-label']", text: "Pages 5 through 7 omitted"
    end
    assert_equal(
      "/gallery/compositions/users/search?page=2&query=a&status=active",
      css_select("#gallery-users-search-pagination-previous").first["href"]
    )
    assert_equal(
      "/gallery/compositions/users/search?page=4&query=a&status=active",
      css_select("#gallery-users-search-pagination-next").first["href"]
    )

    get_flow("users", "empty")
    assert_select "input[type='search'][value='unfindable@example.test']"
    assert_select "#gallery-users-empty-section[data-nk='data-section']" do
      assert_select "> #gallery-users-empty[data-slot='data-section-empty-state'][data-nk='empty-state']" do
        assert_select "h3[data-slot='empty-state-title']", text: "No users match this search"
      end
    end
    assert_select "#gallery-users-empty-reset[href$='/users/index']"

    get_flow("users", "loading")
    assert_select "[data-gallery='users-loading-region'][aria-busy='true'][aria-live='polite']"
    assert_select "#gallery-users-loading-section[data-nk='data-section']" do
      assert_select "> #gallery-users-loading-table[data-slot='data-section-table'][data-nk='table']", count: 1
      assert_select "[data-nk='table']", count: 1
    end
    assert_select "#gallery-users-search-form input[disabled]"
    assert_select "#gallery-users-search-form select[disabled]"
    assert_select "#gallery-users-search-submit[disabled]", text: "Searching…"
    assert_select "#gallery-users-loading-table tbody tr", count: 3

    get_flow("users", "error")
    assert_select "#gallery-users-error[data-variant='error']", text: /No user data was changed/
    assert_select "#gallery-users-error-card", text: /users_read_timeout_2026_07_13_0917/
    assert_select "#gallery-users-retry[href$='/users/index']", text: "Retry"
  end

  test "bulk user flow carries native selection through destructive review and audit outcome" do
    get_flow("users", "bulk")
    assert_select "#gallery-users-bulk-section[data-nk='form-section']" do
      assert_select "> [data-slot='form-section-form'] > #gallery-users-bulk-form", count: 1
    end
    assert_select "#gallery-users-bulk-selection[data-nk='checkbox-group']" do
      assert_select "legend", text: "Users to update"
      assert_select "input[type='checkbox'][name='gallery_forms_bulk_user_action[member_ids][]']",
        count: Gallery::Compositions::UsersPage::USERS.size
      assert_select "input[type='checkbox'][value='mem_ada'][disabled]"
      assert_select "input[type='checkbox'][checked]", count: 2
    end
    assert_select "#gallery-users-bulk-form select[name*='[action]'] option[value='remind'][selected]"
    assert_select "#gallery-users-bulk-review", text: "Review 2 selected users"

    get_flow("users", "bulk-confirmation")
    assert_select "#gallery-users-bulk-confirmation-zone[data-nk='danger-zone']" do
      assert_select "> [data-slot='danger-zone-confirmation'] > #gallery-users-bulk-warning", count: 1
      assert_select "> #gallery-users-bulk-confirmation-back[data-slot='danger-zone-escape']", count: 1
    end
    assert_select "#gallery-users-bulk-warning[data-variant='warning']", text: /Active sessions will end immediately/
    assert_select "#gallery-users-bulk-confirmation-form input[type='hidden'][name='gallery_forms_bulk_user_action[member_ids][]']",
      count: 2
    assert_select "#gallery-users-bulk-confirmation-form input[type='checkbox'][required]"
    assert_select "#gallery-users-bulk-confirm[data-variant='destructive']", text: "Suspend 2 users"

    get_flow("users", "bulk-complete")
    assert_select "#gallery-users-bulk-complete[data-variant='success']", text: /2 user records were updated/
    assert_select "[data-gallery='bulk-operation-summary'] dt", count: 3
    assert_select "#gallery-users-bulk-complete-return[href$='/users/index']"

    get_flow("users", "mobile")
    assert_select "[data-gallery-composition='users'][data-gallery-mobile='true']"
    assert_select "#gallery-users-mobile-card", text: /margaret\.hamilton\+apollo-guidance-software@example\.test/
    assert_select "#gallery-users-mobile-actions[role='group'][aria-label='Actions for Margaret Hamilton']"
  end

  private

  def get_flow(slug, state)
    get gallery_composition_path(slug:, state:)
    assert_response :success
  end
end
