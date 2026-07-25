require "test_helper"

class Gallery::SettingsFormExamplesTest < ActiveSupport::TestCase
  test "valid settings examples use fixed realistic values" do
    security = Gallery::SettingsFormExamples.security
    notifications = Gallery::SettingsFormExamples.notifications
    appearance = Gallery::SettingsFormExamples.appearance

    assert_predicate security, :valid?
    assert_equal 30, security.session_timeout
    assert security.two_factor
    assert_predicate notifications, :valid?
    assert_equal "immediately", notifications.delivery_frequency
    assert notifications.security_alerts
    assert_predicate appearance, :valid?
    assert_equal "system", appearance.theme
    assert_equal "comfortable", appearance.density
  end

  test "invalid settings examples expose real Active Model errors" do
    security = Gallery::SettingsFormExamples.security(:invalid)
    notifications = Gallery::SettingsFormExamples.notifications(:invalid)
    appearance = Gallery::SettingsFormExamples.appearance(:invalid)

    assert_predicate security, :invalid?
    assert security.errors.of_kind?(:current_password, :blank)
    assert security.errors.of_kind?(:new_password, :too_short)
    assert security.errors.of_kind?(:session_timeout, :inclusion)
    assert_predicate notifications, :invalid?
    assert notifications.errors.of_kind?(:delivery_frequency, :inclusion)
    assert_predicate appearance, :invalid?
    assert appearance.errors.of_kind?(:theme, :inclusion)
    assert appearance.errors.of_kind?(:density, :inclusion)
  end

  test "settings examples reject invented states" do
    assert_raises(KeyError) { Gallery::SettingsFormExamples.security(:loading) }
    assert_raises(KeyError) { Gallery::SettingsFormExamples.notifications(:loading) }
    assert_raises(KeyError) { Gallery::SettingsFormExamples.appearance(:loading) }
  end
end
