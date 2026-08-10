require "test_helper"

class ApplicationCombinationsGalleryTest < ActionDispatch::IntegrationTest
  APPLICATIONS = {
    "application-sidebar" => {
      layout: "sidebar",
      states: %w[populated empty error],
      source: "sidebar_application_page.rb"
    },
    "application-topbar" => {
      layout: "topbar",
      states: %w[populated loading long],
      source: "topbar_application_page.rb"
    },
    "application-hybrid" => {
      layout: "hybrid",
      states: %w[populated missing error],
      source: "hybrid_application_page.rb"
    }
  }.freeze

  test "catalog exposes three complete application routes without synthetic state routes" do
    entries = Gallery::Catalog.entries(kind: :composition).select { |entry| APPLICATIONS.key?(entry.slug) }

    assert_equal APPLICATIONS.keys, entries.map(&:slug)
    entries.each do |entry|
      assert_empty entry.states
      assert_equal "Complete applications", Gallery::Catalog.category_for(entry).title
      assert_equal "/gallery/compositions/#{entry.slug}", Gallery::Catalog.path_for(
        entry,
        routes: Rails.application.routes.url_helpers
      )
    end
  end

  test "each application page renders three themed executable shell examples with source parity" do
    APPLICATIONS.each do |slug, contract|
      get gallery_composition_path(slug:)

      assert_response :success
      assert_select "[data-gallery-page='#{slug}']"
      assert_select "[data-gallery='example']", count: 3
      assert_select "[data-gallery-application='#{contract.fetch(:layout)}'][data-layout='#{contract.fetch(:layout)}']",
        count: 3

      contract.fetch(:states).each do |state|
        shell = "[data-gallery-application='#{contract.fetch(:layout)}']" \
          "[data-gallery-application-state='#{state}']"
        assert_select "#{shell}[data-nk='app-shell'][id]", count: 1
        assert_select "#{shell} [data-nk='app-navigation']", count: 1
        assert_select "#{shell} > [data-slot='app-shell-main'] [data-nk='page-header']", count: 1
      end

      assert_select "[data-gallery-application='#{contract.fetch(:layout)}']:not([data-theme])", count: 1
      assert_select "[data-gallery-application='#{contract.fetch(:layout)}'][data-theme='light']", count: 1
      assert_select "[data-gallery-application='#{contract.fetch(:layout)}'][data-theme='dark']", count: 1

      assert_select "[data-gallery='example']" do |examples|
        examples.each do |example|
          assert_select example, "[data-gallery='example-canvas'] [data-nk='app-shell']", count: 1
          assert_select example, "[data-gallery='code-path']", text: /#{contract.fetch(:source)}\z/, count: 1
          assert_select example, "[data-gallery='code-source']", text: /render NitroKit::AppShell\.new/, count: 1
          assert_select example, "[data-gallery='code-source']", text: /layout: :#{contract.fetch(:layout)}/, count: 1
        end
      end
    end
  end

  test "sidebar applications combine data uploads recovery and appearance states" do
    get gallery_composition_path(slug: "application-sidebar")

    assert_response :success
    assert_select "#gallery-sidebar-application-populated" do
      assert_select "[data-slot='app-navigation-footer'] [data-nk='appearance-picker'][data-presentation='dropdown']", count: 1
      assert_select "[data-nk='stat-grid'] [data-slot='stat-grid-stat']", count: 3
      assert_select "[data-nk='data-section'] > [data-slot='data-section-table'][data-nk='table'][data-sort] tbody tr", count: 3
      assert_select "[data-nk='toast'] [data-slot='toast-item'][data-variant='success']", count: 1
    end
    assert_select "#gallery-sidebar-application-empty[data-theme='light']" do
      assert_select "> [data-slot='app-shell-main'] [data-nk='empty-state'][data-variant='default']", text: /No projects yet/
      assert_select "[data-nk='data-section'] [data-nk='empty-state']", count: 0
      assert_select "form[enctype='multipart/form-data'] [data-nk='dropzone'][data-state='idle']", count: 1
      assert_select "input[type='file'][name='project_import[files][]']:not([data-direct-upload-url])", count: 1
    end
    assert_select "#gallery-sidebar-application-error[data-theme='dark']" do
      assert_select "[data-nk='alert'][data-variant='error']", count: 1
      assert_select "[data-nk='details-table'] [data-slot='details-table-empty']", count: 2
      assert_select "[data-nk='dialog']", count: 1
    end
  end

  test "topbar applications combine progressive media menus loading long data and overlays" do
    get gallery_composition_path(slug: "application-topbar")

    assert_response :success
    assert_select "#gallery-topbar-application-populated[data-theme='light']" do
      assert_select "[data-nk='progressive-image']", count: 3
      assert_select "[data-nk='dropdown']", count: 3
      assert_select "[data-nk='toast'] [data-slot='toast-item'][data-variant='success']", count: 1
    end
    assert_select "#gallery-topbar-application-loading[aria-busy='true']" do
      assert_select "[data-nk='progressive-image'][data-state='loading']", count: 3
      assert_select "[data-nk='button'][disabled]", minimum: 4
    end
    assert_select "#gallery-topbar-application-long[data-theme='dark']" do
      assert_select "[data-nk='table'][data-sort] tbody tr", count: 3
      assert_select "[data-nk='dialog']", count: 1
      assert_select "[data-slot='page-header-title']", text: /International analytical engine reliability/
    end
  end

  test "hybrid applications combine synchronized appearance details forms missing data and policy failure" do
    get gallery_composition_path(slug: "application-hybrid")

    assert_response :success
    assert_select "#gallery-hybrid-application-populated" do
      assert_select "[data-nk='appearance-picker']", count: 2
      assert_select "[data-slot='app-navigation-footer'] [data-nk='appearance-picker'][data-presentation='dropdown']", count: 1
      assert_select "[data-nk='settings-layout']", count: 1
      assert_select "[data-nk='settings-layout'] [data-nk='grid'][data-cols='1 md:2']", count: 1
      assert_select "[data-nk='progressive-image']", count: 1
      assert_select "[data-nk='details-table']", count: 1
      assert_select "form#gallery-hybrid-application-profile-form > [data-nk='field-group']" do
        assert_select "> [data-nk='field']", count: 3
        assert_select "> #gallery-hybrid-application-profile-submit[data-nk='button']", count: 1
      end
      assert_select "form#gallery-hybrid-application-profile-form [data-nk='fieldset']", count: 0
      assert_select "[data-nk='toast'] [data-slot='toast-item'][data-variant='success']", count: 1
    end
    assert_select "#gallery-hybrid-application-missing[data-theme='light']" do
      assert_select "[data-nk='progressive-image'][data-state='empty']", count: 1
      assert_select "[data-slot='details-table-empty']", count: 4
      assert_select "[data-nk='empty-state']", text: /Profile setup has not started/
      assert_select "[data-slot='page-header-description']", count: 0
    end
    assert_select "#gallery-hybrid-application-error[data-theme='dark']" do
      assert_select "[data-nk='alert'][data-variant='error']", count: 1
      assert_select "[data-nk='fieldset'][disabled]", count: 1
      assert_select "[data-nk='field'][data-state='invalid']", count: 2
      assert_select "#gallery-hybrid-application-access-submit[disabled]", count: 1
      assert_select "[data-nk='dialog']", count: 1
      assert_select "[data-nk='toast'] [data-slot='toast-item'][data-variant='error']", count: 1
    end
  end
end
