require "test_helper"

class Gallery::PublicDataTest < ActiveSupport::TestCase
  test "public plans features and proof are fixed unique caller records" do
    assert_equal %w[starter team scale], Gallery::PublicData.plans.map(&:id)
    assert_equal 6, Gallery::PublicData.features.size
    assert_equal Gallery::PublicData.features.map(&:id).uniq, Gallery::PublicData.features.map(&:id)
    assert_equal 3, Gallery::PublicData.proof.size
    assert Gallery::PublicData::PLANS.frozen?
    assert Gallery::PublicData::FEATURES.frozen?
    assert Gallery::PublicData::PROOF.frozen?
    assert Gallery::PublicData.plans.all? { |plan| plan.features.frozen? }
    assert_equal "Team", Gallery::PublicData.plans.find(&:highlighted).name
  end

  test "system status records preserve exact application response semantics" do
    assert_equal %w[403 404 422 500 maintenance offline rate-limited degraded long mobile],
      Gallery::PublicData::SYSTEM_STATUSES.keys
    assert_equal "403", Gallery::PublicData.system_status("403").code
    assert_equal "429", Gallery::PublicData.system_status("rate-limited").code
    assert_equal "42 seconds", Gallery::PublicData.system_status("rate-limited").retry_after
    assert_equal :destructive, Gallery::PublicData.system_status("500").variant
    assert_equal :warning, Gallery::PublicData.system_status("degraded").variant
    assert_raises(KeyError) { Gallery::PublicData.system_status("invented") }
  end

  test "checkout result records add outcomes not duplicated by checkout" do
    states = Gallery::PublicData::CHECKOUT_OUTCOMES.keys

    assert_equal %w[invoice-issued bank-transfer-pending trial-started credit-applied manual-review long mobile], states
    assert_empty states & %w[succeeded failed requires-action cancelled refunded]
    assert_equal "INV-3049", Gallery::PublicData.checkout_outcome("invoice-issued").reference
    assert_equal "$0.00 today", Gallery::PublicData.checkout_outcome("trial-started").amount
    assert_equal :warning, Gallery::PublicData.checkout_outcome("manual-review").variant
    assert_raises(KeyError) { Gallery::PublicData.checkout_outcome("succeeded") }
  end

  test "contact inquiry validates durable routing fields" do
    inquiry = Gallery::Forms::ContactInquiry.new(
      name: "Ada Lovelace",
      email: "ada@example.test",
      company: "Analytical Engines",
      topic: "enterprise",
      message: "We need pricing and security review details for a production Rails application."
    )

    assert_predicate inquiry, :valid?

    inquiry.assign_attributes(name: "", email: "invalid", topic: "unknown", message: "Too short")

    assert_predicate inquiry, :invalid?
    assert_equal %i[name email topic message], inquiry.errors.attribute_names
    assert inquiry.errors.of_kind?(:email, :invalid)
    assert inquiry.errors.of_kind?(:topic, :inclusion)
    assert inquiry.errors.of_kind?(:message, :too_short)
  end
end
