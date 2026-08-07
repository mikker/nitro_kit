require "test_helper"

class GalleryActionsTest < ActionDispatch::IntegrationTest
  test "button group page covers membership content labels disabled state and pressure" do
    get_component("button-group")

    assert_select "#gallery-button-group-one[role='group'][aria-label='Single record action']" do
      assert_select "[data-slot='button-group-button']", count: 1
    end
    assert_select "#gallery-button-group-two[role='group'][aria-label='Form actions']" do
      assert_select "[data-slot='button-group-button']", count: 2
    end
    assert_select "#gallery-button-group-four[role='group'][aria-label='Document actions']" do
      assert_select "[data-slot='button-group-button']", count: 4
    end

    assert_select "#gallery-button-group-mixed-back[href='#audit-log'] [data-slot='button-icon-start']"
    assert_select "#gallery-button-group-mixed-export[href='#audit-export']", text: /comma-separated/
    assert_select "#gallery-button-group-mixed-archive[disabled] [data-slot='button-icon-end']"
    assert_select "#gallery-button-group-mixed-delete[aria-label='Delete selected audit records']" do
      assert_select "[data-slot='button-label']", count: 0
    end
    assert_select "#gallery-button-group-mixed-block", text: "Block-provided action"
  end

  test "button group page composes record and table toolbars" do
    get_component("button-group")

    assert_select "#gallery-button-group-record-card[data-nk='card']" do
      assert_select "#gallery-button-group-record-access[data-nk='badge']"
      assert_select "#gallery-button-group-record-actions[data-nk='button-group']" do
        assert_select "[data-slot='button-group-button'][data-nk='button']", count: 3
      end
    end
    assert_select "#gallery-button-group-table-actions[data-nk='button-group']" do
      assert_select "#gallery-button-group-table-deactivate[disabled]"
      assert_select "#gallery-button-group-table-remove[data-variant='destructive']"
    end
    assert_select "#gallery-button-group-members-table[data-nk='table']" do
      assert_select "th[scope='row']", count: 2
    end
  end

  test "pagination page covers first middle and last boundary semantics" do
    get_component("pagination")

    assert_select "#gallery-pagination-boundary-first" do
      assert_select "#gallery-pagination-boundary-first-previous[aria-disabled='true']:not([href])"
      assert_select "a#gallery-pagination-boundary-first-page-1[aria-current='page']" \
                    "[href='/gallery/search?page=1']:not([aria-disabled]):not([tabindex])"
      assert_select "#gallery-pagination-boundary-first-next[href='/gallery/search?page=2']"
    end
    assert_select "#gallery-pagination-boundary-middle" do
      assert_select "#gallery-pagination-boundary-middle-previous[href='/gallery/search?page=5']"
      assert_select "a#gallery-pagination-boundary-middle-page-6[aria-current='page']" \
                    "[href='/gallery/search?page=6']:not([aria-disabled]):not([tabindex])"
      assert_select "#gallery-pagination-boundary-middle-next[href='/gallery/search?page=7']"
    end
    assert_select "#gallery-pagination-boundary-last" do
      assert_select "#gallery-pagination-boundary-last-previous[href='/gallery/search?page=11']"
      assert_select "a#gallery-pagination-boundary-last-page-12[aria-current='page']" \
                    "[href='/gallery/search?page=12']:not([aria-disabled]):not([tabindex])"
      assert_select "#gallery-pagination-boundary-last-next[aria-disabled='true']:not([href])"
    end
  end

  test "pagination page builds navigation from real Pagy objects" do
    get_component("pagination")

    assert_select "#gallery-pagination-pagy-1" do
      assert_select "[data-slot='pagination-previous'][aria-disabled='true']:not([href])"
      assert_select "[data-slot='pagination-current'][aria-current='page']", text: "1"
      assert_select "[data-slot='pagination-next'][href='/gallery/records?status=active&page=2']"
    end
    assert_select "#gallery-pagination-pagy-6 [data-slot='pagination-item'][data-kind='ellipsis']", count: 2
    assert_select "#gallery-pagination-pagy-12" do
      assert_select "[data-slot='pagination-previous'][href='/gallery/records?status=active&page=11']"
      assert_select "[data-slot='pagination-next'][aria-disabled='true']:not([href])"
    end
  end

  test "pagination page covers compact long ellipsis label and pressure modes" do
    get_component("pagination")

    assert_select "#gallery-pagination-compact [data-slot='pagination-item'][data-kind='page']", count: 3
    assert_select "#gallery-pagination-long [data-slot='pagination-item'][data-kind='ellipsis']", count: 2
    assert_select "#gallery-pagination-long [data-slot='pagination-ellipsis'][aria-hidden]", count: 2
    assert_select "#gallery-pagination-long [data-slot='pagination-ellipsis-label']",
      text: /Pages 2 through 5 omitted/

    assert_select "#gallery-pagination-labels" do
      assert_select "[data-nk='icon']", count: 0
      assert_select "#gallery-pagination-labels-previous", text: /newer archived records/
      assert_select "#gallery-pagination-labels-page", text: "A custom page label"
      assert_select "#gallery-pagination-labels-next", text: /older archived records/
    end

    assert_select "#gallery-pagination-pressure [data-slot='pagination-item'][data-kind='page']", count: 12
    assert_select "#gallery-pagination-pressure [aria-current='page']", count: 1
    assert_select "a#gallery-pagination-pressure-page-6[aria-current='page']" \
                  "[href='/gallery/pressure?page=6']:not([aria-disabled]):not([tabindex])"
  end

  test "pagination page composes searchable paginated table results" do
    get_component("pagination")

    assert_select "#gallery-pagination-search-field[data-nk='field']" do
      assert_select "#gallery-pagination-search[data-nk='input'][type='search'][name='search[query]']"
    end
    assert_select "#gallery-pagination-results-table[data-nk='table']" do
      assert_select "th[scope='row']", count: Gallery::Data.members.size
      assert_select "[data-nk='badge']", count: Gallery::Data.members.size
    end
    assert_select "#gallery-pagination-results[aria-label='Member search result pages']" do
      assert_select "#gallery-pagination-results-previous[aria-disabled='true']:not([href])"
      assert_select "#gallery-pagination-results-page-1[aria-current='page']:not([href])"
      assert_select "#gallery-pagination-results-page-2[href='/gallery/members?query=engineering&page=2']"
      assert_select "[data-slot='pagination-ellipsis-label']", text: "Pages 3 through 15 omitted"
      assert_select "#gallery-pagination-results-next[href='/gallery/members?query=engineering&page=2']"
    end
  end

  private

  def get_component(slug)
    get gallery_component_path(slug)
    assert_response :success
  end
end
