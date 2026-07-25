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

  raise "Expected at least one catalog URL" if CATALOG_VISITS.empty?

  duplicate_paths = CATALOG_VISITS.map(&:path).tally.select { |_path, count| count > 1 }.keys
  raise "Catalog URLs must be unique: #{duplicate_paths.join(', ')}" if duplicate_paths.any?

  CATALOG_VISITS.each do |visit|
    state_label = visit.state ? " in #{visit.state}" : ""

    test "browser renders #{visit.entry.kind} #{visit.entry.slug}#{state_label}" do
      visit visit.path

      assert_current_path visit.path
      assert_selector "html[data-gallery='document'][data-theme-preference='system'][data-theme]"
      assert_includes %w[light dark], find("html")["data-theme"]
      assert_selector page_marker(visit)

      if visit.entry.kind == :home
        assert_selector "[data-gallery='introduction']"
        assert_selector "[data-gallery='introduction'] li", count: 4
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
