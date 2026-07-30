require "test_helper"

class ApplicationComponentTest < ActiveSupport::TestCase
  test "merges application HTML data ARIA and classes with caller precedence" do
    rendered = render_status_html(
      html: {
        "id" => "registration-state",
        class: "receipt-state status-pill--quiet",
        "title" => "Caller-owned title"
      },
      data: {
        "application-component" => "caller-status-pill",
        state: "reviewed",
        turbo_method: "patch"
      },
      aria: { "LIVE" => "assertive", label: "Registration reviewed" }
    )
    node = Nokogiri::HTML.fragment(rendered).first_element_child

    assert_equal "registration-state", node["id"]
    assert_equal "Caller-owned title", node["title"]
    assert_equal "status-pill receipt-state status-pill--quiet", node["class"]
    assert_equal "caller-status-pill", node["data-application-component"]
    assert_equal "reviewed", node["data-state"]
    assert_equal "patch", node["data-turbo-method"]
    assert_equal "assertive", node["aria-live"]
    assert_equal "Registration reviewed", node["aria-label"]
    assert_equal "Received", node.at_css("[data-nk='badge']").text
    assert_equal 1, rendered.scan("data-application-component=").size
    assert_equal 1, rendered.downcase.scan("aria-live=").size
  end

  test "does not mutate defaults between component instances" do
    render_status(html: { class: "one-off" }, data: { state: "reviewed" })
    node = render_status

    assert_equal "status-pill status-pill--quiet", node["class"]
    assert_equal "received", node["data-state"]
    assert_nil node["data-source"]
    assert_equal "polite", node["aria-live"]
  end

  test "rejects nested and flattened data and ARIA attributes in html" do
    {
      { data: { source: "wrong boundary" } } => "Pass data through data:, not html:",
      { "data_turbo_method" => "delete" } => "Pass data-turbo-method through data:, not html:",
      { "aria-label" => "Wrong boundary" } => "Pass aria-label through aria:, not html:"
    }.each do |html, message|
      error = assert_raises(ArgumentError) { render_status(html:) }
      assert_equal message, error.message
    end
  end

  test "rejects aliases that would emit duplicate attributes within one bag" do
    error = assert_raises(ArgumentError) do
      render_status(data: { turbo_method: "patch", "turbo-method" => "delete" })
    end
    assert_equal "Duplicate data attribute data-turbo-method", error.message

    error = assert_raises(ArgumentError) do
      render_status(aria: { details_id: "one", "details-id" => "two" })
    end
    assert_equal "Duplicate ARIA attribute aria-details-id", error.message

    error = assert_raises(ArgumentError) do
      render_status(html: { title: "One", "TITLE" => "Two" })
    end
    assert_equal "Duplicate HTML attribute title", error.message
  end

  test "rejects invalid hashes classes keys and statuses with useful errors" do
    error = assert_raises(ArgumentError) { render_status(html: { class: { active: true } }) }
    assert_equal "class values must be Strings", error.message

    error = assert_raises(ArgumentError) { render_status(data: nil) }
    assert_equal "data must be a Hash", error.message

    error = assert_raises(ArgumentError) { render_status(data: { 1 => "invalid" }) }
    assert_equal "data attribute keys must be Strings or Symbols", error.message

    assert_raises(ArgumentError) { RailsIntegration::StatusPill.new(:unknown) }
  end

  private

  def render_status_html(**options)
    RailsIntegration::StatusPill.new(:received, **options).call
  end

  def render_status(**options)
    Nokogiri::HTML.fragment(render_status_html(**options)).first_element_child
  end
end
