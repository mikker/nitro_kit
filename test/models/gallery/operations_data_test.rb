require "test_helper"

class Gallery::OperationsDataTest < ActiveSupport::TestCase
  test "dense team and credential fixtures are fixed immutable inventories" do
    members = Gallery::Data.dense_members
    keys = Gallery::Data.dense_api_keys

    assert members.frozen?
    assert keys.frozen?
    assert_equal 9, members.length
    assert_equal 6, keys.length
    assert_equal %w[
      mem_ada mem_grace mem_katherine mem_dorothy mem_mary mem_annie mem_margaret mem_hedy mem_radia
    ], members.map(&:id)
    assert_equal "hedy.lamarr@example.test", members.fetch(7).email
    assert_equal :suspended, members.fetch(7).status
    assert_equal "European production deployments", keys.fetch(3).name
    assert_equal "Finance reconciliation and revenue recognition export", keys.last.name
    assert_nil keys.last.last_used_at
  end

  test "credential reveal and failure records preserve deterministic security facts" do
    reveal = Gallery::Data.api_key_reveal
    expired = Gallery::Data.expired_api_key_issue
    failed = Gallery::Data.failed_api_key_issue

    assert reveal.frozen?
    assert expired.frozen?
    assert failed.frozen?
    assert_equal "key_reporting", reveal.key_id
    assert_equal "nk_live_2M8Q_7uT9cK4dP6xR3vN8mL1sH5jF", reveal.secret
    assert_equal Time.utc(2026, 7, 13, 9, 18), reveal.revealed_at
    assert_equal Time.utc(2026, 10, 11, 9, 18), reveal.expires_at
    assert_equal :expired, expired.status
    assert_equal Time.utc(2026, 7, 1), expired.occurred_at
    assert_equal :error, failed.status
    assert_equal Time.utc(2026, 7, 13, 8, 33), failed.occurred_at
  end

  test "team member role and removal examples use real conditional validation" do
    role = Gallery::OperationsFormExamples.team_member_action(:role_valid)
    invalid_role = Gallery::OperationsFormExamples.team_member_action(:role_invalid)
    removal = Gallery::OperationsFormExamples.team_member_action(:remove_valid)
    invalid_removal = Gallery::OperationsFormExamples.team_member_action(:remove_invalid)

    assert role.valid?
    assert_equal Gallery::Data::CURRENT_TEAM_ID, role.team_id
    assert_equal "mem_grace", role.member.id
    assert_equal "grace@example.test", role.member.email
    assert_equal "viewer", role.role
    assert invalid_role.invalid?
    assert invalid_role.errors.of_kind?(:role, :inclusion)
    assert removal.valid?
    assert invalid_removal.invalid?
    assert_includes invalid_removal.errors[:confirmation], "must match the member email address"
  end

  test "team member ownership validation is scoped to one selected team" do
    analytical_last_owner = Gallery::OperationsFormExamples.team_member_action(:last_owner_invalid)
    promote_grace = Gallery::Forms::TeamMemberAction.new(
      team_id: Gallery::Data::CURRENT_TEAM_ID,
      action: "change_role",
      member_id: "mem_grace",
      role: "owner"
    )
    apollo_last_owner = Gallery::Forms::TeamMemberAction.new(
      team_id: "team_apollo",
      action: "change_role",
      member_id: "mem_grace",
      role: "member"
    )

    assert analytical_last_owner.invalid?
    assert promote_grace.valid?
    assert apollo_last_owner.invalid?
    assert_includes apollo_last_owner.errors[:role],
      "cannot be changed because every team must keep at least one owner"
  end

  test "credential revocation examples validate known keys and explicit acknowledgement" do
    revocation = Gallery::OperationsFormExamples.api_key_revocation
    invalid = Gallery::OperationsFormExamples.api_key_revocation(:invalid)

    assert revocation.valid?
    assert_equal "key_production", revocation.key_id
    assert invalid.invalid?
    assert invalid.errors.of_kind?(:key_id, :inclusion)
    assert invalid.errors.of_kind?(:acknowledged, :accepted)
  end

  test "operation factories reject unregistered states" do
    assert_raises(KeyError) { Gallery::OperationsFormExamples.team_member_action(:promote_owner) }
    assert_raises(KeyError) { Gallery::OperationsFormExamples.api_key_revocation(:expired) }
  end
end
