require "application_system_test_case"

class CatalogSmokeTest < ApplicationSystemTestCase
  CatalogVisit = Data.define(:entry, :state, :path)

  CATALOG_VISITS = Gallery::Catalog.entries.flat_map do |entry|
    states = entry.states.any? ? entry.states : [ nil ]

    states.map do |state|
      CatalogVisit.new(
        entry:,
        state:,
        path: Gallery::Catalog.path_for(
          entry,
          routes: Rails.application.routes.url_helpers,
          state:
        )
      )
    end
  end.freeze

  raise "Expected 335 catalog URLs, found #{CATALOG_VISITS.size}" unless CATALOG_VISITS.size == 335

  CATALOG_VISITS.each do |visit|
    state_label = visit.state ? " in #{visit.state}" : ""

    test "browser renders #{visit.entry.kind} #{visit.entry.slug}#{state_label}" do
      visit visit.path

      assert_current_path visit.path
      assert_selector "html[data-gallery='document'][data-theme='light']"
      assert_selector page_marker(visit)

      if visit.entry.kind == :home
        assert_selector "[data-gallery='index']"
        assert_selector "[data-gallery='index-group']", count: Gallery::Catalog.navigation_groups.size
      else
        assert_catalog_roots(visit.entry)
      end

      assert_no_severe_console_errors(context: visit.path)
    end
  end

  private

  def page_marker(visit)
    marker = "div[data-gallery='page'][data-gallery-page='#{visit.entry.slug}']"
    visit.state ? "#{marker}[data-gallery-state='#{visit.state}']" : marker
  end

  def assert_catalog_roots(entry)
    canvas = "[data-gallery='example-canvas']"
    assert_selector "#{canvas} [data-nk='#{entry.expected_roots.first}'][id]"

    entry.expected_roots.each do |root|
      assert_selector "#{canvas} [data-nk='#{root}']", visible: :all
    end
  end
end
