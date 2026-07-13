require "test_helper"

class Gallery::BillingUsersFormsTest < ActiveSupport::TestCase
  test "payment method validates card address and receipt data" do
    payment_method = Gallery::Forms::PaymentMethod.new(
      cardholder_name: "Ada Lovelace",
      card_number: "4242424242424242",
      expiry: "08/28",
      billing_email: "accounts-payable@example.test",
      postal_code: "SW1A 1AA"
    )

    assert_predicate payment_method, :valid?

    payment_method.assign_attributes(
      cardholder_name: "",
      card_number: "4242",
      expiry: "8/28",
      billing_email: "invalid",
      postal_code: ""
    )

    assert_not payment_method.valid?
    assert_equal %i[cardholder_name card_number expiry billing_email postal_code], payment_method.errors.attribute_names
  end

  test "subscription cancellation requires a known reason and explicit confirmation" do
    cancellation = Gallery::Forms::SubscriptionCancellation.new(
      reason: "temporary_pause",
      feedback: "We will return next quarter.",
      confirmed: true
    )

    assert_predicate cancellation, :valid?

    cancellation.assign_attributes(reason: "unknown", feedback: "x" * 501, confirmed: false)

    assert_not cancellation.valid?
    assert_equal %i[reason feedback confirmed], cancellation.errors.attribute_names
  end

  test "user search constrains status and bulk action keeps selection isolated" do
    assert_predicate Gallery::Forms::UserSearch.new(query: "Ada", status: "active"), :valid?
    assert_not Gallery::Forms::UserSearch.new(query: "Ada", status: "unknown").valid?

    first_action = Gallery::Forms::BulkUserAction.new(member_ids: [ "mem_grace" ], action: "remind")
    second_action = Gallery::Forms::BulkUserAction.new(action: "remove", confirmed: false)

    assert_predicate first_action, :valid?
    assert_empty second_action.member_ids
    assert_not second_action.valid?
    assert_includes second_action.errors.attribute_names, :member_ids
    assert_includes second_action.errors.attribute_names, :confirmed
  end
end
