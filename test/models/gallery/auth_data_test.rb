require "test_helper"

class Gallery::AuthDataTest < ActiveSupport::TestCase
  test "authentication and onboarding data is fixed and immutable" do
    identity = Gallery::Data.auth_identity
    steps = Gallery::Data.onboarding_steps

    assert_equal "Katherine Johnson", identity.name
    assert_equal "katherine.johnson+analytical-engines@example.test", identity.email
    assert_equal "Analytical Engines — Research and Production", identity.workspace
    assert_equal Time.utc(2026, 7, 12, 16, 18), identity.invited_at
    assert identity.frozen?
    assert steps.frozen?
    assert_equal %w[workspace team integrations review], steps.map(&:slug)
    assert_equal [ 1, 2, 3, 4 ], steps.map(&:position)
  end

  test "valid auth and onboarding examples pass real model validation" do
    assert Gallery::AuthFormExamples.sign_in.valid?
    assert Gallery::AuthFormExamples.password_reset(:request).valid?
    assert Gallery::AuthFormExamples.password_reset(:update).valid?
    assert Gallery::AuthFormExamples.email_verification.valid?
    assert Gallery::AuthFormExamples.invitation.valid?
    assert Gallery::AuthFormExamples.account_creation.valid?
    assert Gallery::AuthFormExamples.onboarding.valid?
  end

  test "invalid examples expose field and token errors" do
    sign_in = Gallery::AuthFormExamples.sign_in(:invalid)
    reset = Gallery::AuthFormExamples.password_reset(:request_invalid)
    expired_reset = Gallery::AuthFormExamples.password_reset(:expired)
    verification = Gallery::AuthFormExamples.email_verification(:invalid)
    invitation = Gallery::AuthFormExamples.invitation(:invalid)
    expired_invitation = Gallery::AuthFormExamples.invitation(:expired)
    account = Gallery::AuthFormExamples.account_creation(:invalid)
    onboarding = Gallery::AuthFormExamples.onboarding(:invalid)

    assert sign_in.errors.of_kind?(:email, :invalid)
    assert sign_in.errors.of_kind?(:password, :too_short)
    assert reset.errors.of_kind?(:email, :invalid)
    assert_includes expired_reset.errors[:token], "has expired"
    assert_includes verification.errors[:token], "is invalid"
    assert invitation.errors.of_kind?(:name, :blank)
    assert invitation.errors.of_kind?(:terms, :accepted)
    assert_includes expired_invitation.errors[:token], "has expired"
    assert account.errors.of_kind?(:email, :invalid)
    assert account.errors.of_kind?(:terms, :accepted)
    assert onboarding.errors.of_kind?(:workspace_name, :blank)
    assert onboarding.errors.of_kind?(:team_size, :inclusion)
    assert onboarding.errors.of_kind?(:integration, :inclusion)
    assert onboarding.errors.of_kind?(:terms, :accepted)
    assert_includes onboarding.errors[:invitees], "must contain one email address per line"
  end

  test "example factories reject unregistered state invention" do
    assert_raises(KeyError) { Gallery::AuthFormExamples.sign_in(:locked) }
    assert_raises(KeyError) { Gallery::AuthFormExamples.password_reset(:unknown) }
    assert_raises(KeyError) { Gallery::AuthFormExamples.invitation(:revoked) }
    assert_raises(KeyError) { Gallery::AuthFormExamples.account_creation(:pending) }
    assert_raises(KeyError) { Gallery::AuthFormExamples.onboarding(:partial) }
  end
end
