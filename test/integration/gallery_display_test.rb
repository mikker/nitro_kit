require "test_helper"

class GalleryDisplayTest < ActionDispatch::IntegrationTest
  test "alert page covers every variant slot mode long content and notification composition" do
    get_component("alert")

    NitroKit::Alert::VARIANTS.each do |variant|
      assert_select "[data-nk='alert'][data-variant='#{variant}']", minimum: 1
    end

    assert_select "#gallery-alert-title-only [data-slot='alert-title']"
    assert_select "#gallery-alert-title-only [data-slot='alert-description']", count: 0
    assert_select "#gallery-alert-description-only [data-slot='alert-description']"
    assert_select "#gallery-alert-description-only [data-slot='alert-title']", count: 0
    assert_select "#gallery-alert-icon-title [data-slot='alert-icon'][data-nk='icon']"
    assert_select "#gallery-alert-nested-status [data-slot='alert-description'] [data-nk='badge']"
    assert_select "#gallery-alert-long [data-slot='alert-description']", text: /lock contention/
    assert_select "#gallery-alert-notification-card[data-nk='card']" do
      assert_select "#gallery-alert-notification-success[data-nk='alert']"
      assert_select "#gallery-alert-notification-badge[data-nk='badge']"
      assert_select "#gallery-alert-notification-reviewers[data-nk='avatar-stack']"
      assert_select "[data-nk='avatar']", minimum: 2
    end
  end

  test "avatar page covers every size image fallback long initials and accessible names" do
    get_component("avatar")

    NitroKit::Avatar::SIZES.each do |size|
      assert_select "[data-nk='avatar'][data-size='#{size}']", minimum: 1
    end

    assert_select "#gallery-avatar-image img[data-slot='avatar-image'][src='/gallery/avatars/ada.svg'][alt='Ada Lovelace']"
    assert_select "#gallery-avatar-image [data-slot='avatar-fallback'][aria-hidden='true']", text: "AL"
    assert_select "#gallery-avatar-generated[role='img'][aria-label='Alexandria Ocasio-Cortez']" do
      assert_select "[data-slot='avatar-fallback']", text: "AO"
    end
    assert_select "#gallery-avatar-long-fallback [data-slot='avatar-fallback']", text: "TEAM"
    assert_select "#gallery-avatar-anonymous:not([role]) [data-slot='avatar-fallback']", text: "?"
    assert_select "#gallery-avatar-labelled-image img[alt='Grace Hopper']"
  end

  test "avatar stack page covers every size overflow count mixed identity and labels" do
    get_component("avatar-stack")

    NitroKit::AvatarStack::SIZES.each do |size|
      assert_select "[data-nk='avatar-stack'][data-size='#{size}']", minimum: 1
      assert_select(
        "#gallery-avatar-stack-size-#{size} [data-nk='avatar'][data-size='#{size}']",
        minimum: 2
      )
    end

    assert_select "#gallery-avatar-stack-overflow-one [data-slot='avatar-stack-overflow'][aria-label='1 more avatar']",
      text: "+1"
    assert_select "#gallery-avatar-stack-overflow-nine [data-slot='avatar-stack-overflow'][aria-label='9 more avatars']",
      text: "+9"
    assert_select(
      "#gallery-avatar-stack-overflow-large " \
        "[data-slot='avatar-stack-overflow'][aria-label='128 additional deployment observers']",
      text: "+128"
    )
    assert_select "#gallery-avatar-stack-reviewers[role='group'][aria-label='Deployment reviewers']" do
      assert_select "img[data-slot='avatar-image']"
      assert_select "#gallery-avatar-stack-generated [data-slot='avatar-fallback']", text: "AL"
      assert_select "#gallery-avatar-stack-long-fallback [data-slot='avatar-fallback']", text: "TEAM"
      assert_select "[data-slot='avatar-stack-overflow'][aria-label='Three more deployment reviewers']"
    end
  end

  test "badge page covers every color variant size content mode and roster composition" do
    get_component("badge")

    NitroKit::Badge::COLORS.each do |color|
      assert_select "[data-nk='badge'][data-color='#{color}']", minimum: 1
    end
    NitroKit::Badge::VARIANTS.each do |variant|
      assert_select "[data-nk='badge'][data-variant='#{variant}']", minimum: 1
    end
    NitroKit::Badge::SIZES.each do |size|
      assert_select "[data-nk='badge'][data-size='#{size}']", minimum: 1
    end

    assert_select "#gallery-badge-block [data-slot='badge-label']", text: "Generated from a Phlex block"
    assert_select "#gallery-badge-numeric [data-slot='badge-label']", text: "128"
    assert_select "#gallery-badge-nested-icon [data-slot='badge-label'] [data-nk='icon']"
    assert_select "#gallery-badge-long-label [data-slot='badge-label']", text: /workspace administrator/
    assert_select "#gallery-badge-roster-table[data-nk='table']" do
      assert_select "[data-nk='avatar']", count: Gallery::Data.members.size
      assert_select "[data-nk='badge']", count: Gallery::Data.members.size
      assert_select "th[scope='row']", count: Gallery::Data.members.size
    end
  end

  test "icon page covers every size and both meaningful and decorative semantics" do
    get_component("icon")

    NitroKit::Icon::SIZES.each do |size|
      assert_select "[data-nk='icon'][data-size='#{size}']", minimum: 1
    end

    assert_select "#gallery-icon-meaningful[role='img'][aria-label='Deployment succeeded'][aria-hidden='false']"
    assert_select "#gallery-icon-decorative[aria-hidden='true']:not([role])"
  end

  private

  def get_component(slug)
    get gallery_component_path(slug)
    assert_response :success
  end
end
