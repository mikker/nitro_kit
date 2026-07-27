require "test_helper"

class GalleryCompositionPrimitivesTest < ActionDispatch::IntegrationTest
  test "button-to page demonstrates Rails mutation forms" do
    get gallery_component_path("button-to")

    assert_response :success
    assert_select "form[data-nk='button-to'][id='gallery-button-to-archive'][method='post']" do
      assert_select "input[name='_method'][value='patch']"
      assert_select "button[data-nk='button'][type='submit']", text: /Archive project/
    end
    assert_select "form[data-turbo-confirm='Delete this project?'] input[name='_method'][value='delete']"
    assert_select "#gallery-button-to-revoke button[aria-label='Revoke API token']"
  end

  test "control-group page demonstrates mixed controls and addons" do
    get gallery_component_path("control-group")

    assert_response :success
    assert_select "#gallery-control-group-copy[data-nk='control-group'][role='group']" do
      assert_select "> input[data-nk='input'][readonly][aria-label='Webhook URL']", count: 1
      assert_select "> button[data-nk='button']", count: 1
    end
    assert_select "#gallery-control-group-url > [data-slot='control-group-addon']", count: 2
    assert_select "#gallery-control-group-filter > [data-nk='select'] select[aria-label='Activity period']"
  end

  test "sheet page demonstrates both native side-panel directions" do
    get gallery_component_path("sheet")

    assert_response :success
    assert_select "#gallery-sheet-prompts[data-nk='sheet'][data-side='left'][data-size='sm']" do
      assert_select "button[data-slot='sheet-trigger'][command='show-modal'][commandfor='gallery-sheet-prompts-panel']"
      assert_select "dialog#gallery-sheet-prompts-panel[data-slot='sheet-panel'][closedby='any']"
      assert_select "[data-slot='sheet-body'] [data-nk='app-navigation']"
    end
    assert_select "#gallery-sheet-details[data-side='right'][data-size='md'] [data-nk='details-table']"
  end

  test "tooltip page keeps relationships on links mutation buttons and dialog triggers" do
    get gallery_component_path("tooltip")

    assert_response :success
    assert_select "#gallery-tooltip-link-trigger[href='#runbook'][aria-describedby='gallery-tooltip-link-content']"
    assert_select "#gallery-tooltip-button-to-trigger[aria-describedby='gallery-tooltip-button-to-content']"
    assert_select "#gallery-tooltip-dialog-trigger[aria-describedby='gallery-tooltip-dialog-content'][command='show-modal']"
  end
end
