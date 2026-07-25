require "test_helper"

class Gallery::DataTest < ActiveSupport::TestCase
  test "records are fixed realistic values" do
    assert_equal %w[mem_ada mem_grace mem_katherine], Gallery::Data.members.map(&:id)
    assert_equal Date.new(2024, 2, 12), Gallery::Data.members.first.joined_on
    assert_equal Time.utc(2026, 7, 13, 8, 42), Gallery::Data.activities.first.occurred_at
    assert_equal 4_900, Gallery::Data.invoices.first.amount_cents
    assert_equal "plan_team", Gallery::Data.plans.find(&:current).id
    assert_equal "nk_live_7P3F", Gallery::Data.api_keys.first.prefix
    assert_equal :action_required, Gallery::Data.integrations.fetch(1).status
    assert_equal "192.0.2.42", Gallery::Data.audit_events.first.ip_address
    assert_equal NitroKit::Button::VARIANTS, Gallery::Data.button_variants.map(&:variant)
    assert_equal NitroKit::Button::SIZES, Gallery::Data.button_sizes.map(&:size)
    assert_equal NitroKit::Icon::SIZES, Gallery::Data.icon_sizes.map(&:size)
    assert_equal NitroKit::Alert::VARIANTS, Gallery::Data.alert_variants.map(&:variant)
    assert_equal NitroKit::Avatar::SIZES, Gallery::Data.avatar_sizes.map(&:size)
    assert_equal NitroKit::AvatarStack::SIZES, Gallery::Data.avatar_stack_sizes.map(&:size)
    assert_equal NitroKit::Badge::COLORS, Gallery::Data.badge_colors.map(&:color)
    assert_equal NitroKit::Badge::VARIANTS, Gallery::Data.badge_variants.map(&:variant)
    assert_equal NitroKit::Badge::SIZES, Gallery::Data.badge_sizes.map(&:size)
    assert_equal %w[first middle last], Gallery::Data.pagination_boundaries.map(&:slug)
    assert_equal [ 1, 6, 12 ], Gallery::Data.pagination_boundaries.map(&:current_page)
    assert_includes Gallery::Data.input_examples.map(&:type), :email
  end

  test "record collections and nested feature lists are immutable" do
    assert Gallery::Data.members.frozen?
    assert Gallery::Data.activities.frozen?
    assert Gallery::Data.invoices.frozen?
    assert Gallery::Data.plans.frozen?
    assert Gallery::Data.plans.all? { |plan| plan.features.frozen? }
    assert Gallery::Data.api_keys.frozen?
    assert Gallery::Data.integrations.frozen?
    assert Gallery::Data.audit_events.frozen?
    assert Gallery::Data.button_variants.frozen?
    assert Gallery::Data.button_sizes.frozen?
    assert Gallery::Data.icon_sizes.frozen?
    assert Gallery::Data.alert_variants.frozen?
    assert Gallery::Data.avatar_sizes.frozen?
    assert Gallery::Data.avatar_stack_sizes.frozen?
    assert Gallery::Data.badge_colors.frozen?
    assert Gallery::Data.badge_variants.frozen?
    assert Gallery::Data.badge_sizes.frozen?
    assert Gallery::Data.pagination_boundaries.frozen?
    assert Gallery::Data.pagination_boundaries.all? { |pagination| pagination.pages.frozen? }
    assert Gallery::Data.input_examples.frozen?
  end

  test "valid form examples pass real Active Model validations" do
    assert Gallery::FormExamples.profile.valid?
    assert Gallery::FormExamples.team_invitation.valid?
    assert Gallery::FormExamples.api_key.valid?
    assert Gallery::FormExamples.billing_contact.valid?
  end

  test "invalid form examples expose useful validation states" do
    profile = Gallery::FormExamples.profile(:invalid)
    invitation = Gallery::FormExamples.team_invitation(:invalid)
    api_key = Gallery::FormExamples.api_key(:invalid)
    billing_contact = Gallery::FormExamples.billing_contact(:invalid)

    assert profile.invalid?
    assert profile.errors.of_kind?(:name, :blank)
    assert profile.errors.of_kind?(:email, :invalid)
    assert profile.errors.of_kind?(:time_zone, :inclusion)
    assert profile.errors.of_kind?(:bio, :too_long)

    assert invitation.invalid?
    assert invitation.errors.of_kind?(:email, :invalid)
    assert invitation.errors.of_kind?(:role, :inclusion)

    assert api_key.invalid?
    assert api_key.errors.of_kind?(:name, :blank)
    assert api_key.errors.of_kind?(:access, :inclusion)
    assert api_key.errors.of_kind?(:expires_in_days, :inclusion)

    assert billing_contact.invalid?
    assert billing_contact.errors.of_kind?(:company_name, :blank)
    assert billing_contact.errors.of_kind?(:billing_email, :invalid)
    assert billing_contact.errors.of_kind?(:country, :inclusion)
  end

  test "form example states reject accidental invention" do
    assert_raises(KeyError) { Gallery::FormExamples.profile(:loading) }
  end
end
