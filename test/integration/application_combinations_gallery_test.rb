require "test_helper"

class ApplicationCombinationsGalleryTest < ActionDispatch::IntegrationTest
  APPLICATIONS = {
    "application-sidebar" => {
      layout: "sidebar",
      states: %w[populated empty error inset inset-collapsible],
      source: "sidebar_application_page.rb"
    },
    "application-topbar" => {
      layout: "topbar",
      states: %w[populated loading long],
      source: "topbar_application_page.rb"
    },
    "account-workspace" => {
      layout: "sidebar",
      states: %w[populated missing error],
      source: "account_workspace_page.rb"
    }
  }.freeze

  test "catalog exposes both layouts and the account workflow without synthetic state routes" do
    entries = Gallery::Catalog.entries(kind: :composition).select { |entry| APPLICATIONS.key?(entry.slug) }

    assert_equal APPLICATIONS.keys.sort, entries.map(&:slug).sort
    entries.each do |entry|
      assert_empty entry.states
      assert_equal(entry.slug == "account-workspace" ? "Workspace & organization" : "Complete applications", Gallery::Catalog.category_for(entry).title)
      assert_equal "/gallery/compositions/#{entry.slug}", Gallery::Catalog.path_for(
        entry,
        routes: Rails.application.routes.url_helpers
      )
    end
  end

  test "each application page renders themed executable shell examples with source parity" do
    APPLICATIONS.each do |slug, contract|
      get gallery_composition_path(slug:)

      assert_response :success
      assert_select "[data-gallery-page='#{slug}']"
      assert_select "[data-gallery='example']", count: contract.fetch(:states).size
      assert_select "[data-gallery-application='#{contract.fetch(:layout)}'][data-layout='#{contract.fetch(:layout)}']",
        count: contract.fetch(:states).size

      contract.fetch(:states).each do |state|
        shell = "[data-gallery-application='#{contract.fetch(:layout)}']" \
          "[data-gallery-application-state='#{state}']"
        assert_select "#{shell}[data-nk='app-shell'][id]", count: 1
        assert_select "#{shell} [data-nk='app-navigation']", count: 1
        if state.start_with?("inset")
          assert_select "#{shell} [data-slot='app-shell-topbar'] [data-nk='toolbar'] h1", text: "Release readiness"
        else
          assert_select "#{shell} > [data-slot='app-shell-main'] [data-nk='page-header']", count: 1
        end
      end

      assert_select "[data-gallery-application='#{contract.fetch(:layout)}']:not([data-theme])", count: contract.fetch(:states).size - 2
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
      assert_select "[data-slot='app-shell-sidebar-toggle']", count: 0
      assert_select "[data-slot='app-navigation-footer'] [data-nk='appearance-picker'][data-presentation='dropdown']", count: 1
      assert_select "[data-nk='stat-grid'] [data-slot='stat-grid-stat']", count: 3
      assert_select "[data-nk='data-section'] > [data-slot='data-section-table'][data-nk='table'][data-sort] tbody tr", count: 3
      assert_select "[data-nk='toast'] [data-slot='toast-item'][data-variant='success']", count: 1
    end
    assert_select "#gallery-sidebar-application-empty[data-theme='light']" do
      assert_select "[data-slot='app-shell-sidebar-toggle'][aria-pressed='true']", count: 1
      assert_select "> [data-slot='app-shell-main'] [data-nk='empty-state'][data-variant='default']", text: /No projects yet/
      assert_select "[data-nk='data-section'] [data-nk='empty-state']", count: 0
      assert_select "form[enctype='multipart/form-data'] [data-nk='dropzone'][data-state='idle']", count: 1
      assert_select "input[type='file'][name='project_import[files][]']:not([data-direct-upload-url])", count: 1
    end
    assert_select "#gallery-sidebar-application-error[data-theme='dark']" do
      assert_select "[data-slot='app-shell-sidebar-toggle'][aria-pressed='false']", count: 1
      assert_select "[data-slot='app-shell-brand-icon']", count: 1
      assert_select "[data-nk='alert'][data-variant='destructive']", count: 1
      assert_select "[data-nk='details-table'] [data-slot='details-table-empty']", count: 2
      assert_select "[data-nk='dialog']", count: 1
    end
    assert_select "#gallery-sidebar-application-populated[data-nk--app-shell-collapsible-value='false']", count: 1
    assert_select "#gallery-sidebar-application-empty[data-nk--app-shell-collapsible-value='true'][data-nk--app-shell-pinned-value='true']", count: 1
    assert_select "#gallery-sidebar-application-error[data-nk--app-shell-collapsible-value='true'][data-nk--app-shell-pinned-value='false']", count: 1
    assert_select "#example-sidebar-application-populated-code [data-gallery='code-source']", text: /collapsible: false/
    assert_select "#example-sidebar-application-empty-code [data-gallery='code-source']", text: /collapsible: true.*sidebar: :expanded/m
    assert_select "#example-sidebar-application-error-code [data-gallery='code-source']", text: /collapsible: true.*sidebar: :collapsed/m
    assert_select "#gallery-sidebar-application-inset[data-ui='inset-workspace']" do
      assert_select "[data-slot='app-shell-sidebar-toggle']", count: 0
      assert_select "> [data-slot='app-shell-main'] > [data-ui='workspace-content']", count: 1
      assert_select "[data-nk='stat-grid'] [data-slot='stat-grid-stat']", count: 3
      assert_select "[data-nk='table'] tbody tr", count: 3
    end
    assert_select "#example-sidebar-application-inset-code [data-gallery='code-source']", text: /ui: "inset-workspace"/
    assert_select "#gallery-sidebar-application-inset-collapsible[data-ui='inset-workspace'][data-nk--app-shell-collapsible-value='true']" do
      assert_select "[data-slot='app-shell-sidebar-toggle'][aria-pressed='true']", count: 1
      assert_select "[data-slot='app-shell-brand-icon']", count: 1
      assert_select "> [data-slot='app-shell-main'] > [data-ui='workspace-content']", count: 1
      assert_select "[data-nk='table'] tbody tr", count: 3
    end
    assert_select "#example-sidebar-application-inset-collapsible-code [data-gallery='code-source']", text: /collapsible: true.*sidebar: :expanded/m
  end

  test "topbar applications combine progressive media menus loading long data and overlays" do
    get gallery_composition_path(slug: "application-topbar")

    assert_response :success
    assert_select "#gallery-topbar-application-populated[data-theme='light']" do
      assert_select "[data-nk='progressive-image']", count: 3
      assert_select "[data-nk='dropdown']", count: 4
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

  test "sidebar applications combine synchronized appearance details forms missing data and policy failure" do
    get gallery_composition_path(slug: "account-workspace")

    assert_response :success
    assert_select "#gallery-account-workspace-populated" do
      assert_select "[data-nk='appearance-picker']", count: 2
      assert_select "[data-slot='app-navigation-footer'] [data-nk='appearance-picker'][data-presentation='dropdown']", count: 1
      assert_select "[data-nk='settings-layout']", count: 1
      assert_select "[data-nk='settings-layout'] [data-nk='grid'][data-cols='1 md:2']", count: 1
      assert_select "[data-nk='progressive-image']", count: 1
      assert_select "[data-nk='details-table']", count: 1
      assert_select "form#gallery-account-workspace-profile-form > [data-nk='field-group']" do
        assert_select "> [data-nk='field']", count: 3
        assert_select "> #gallery-account-workspace-profile-submit[data-nk='button']", count: 1
      end
      assert_select "form#gallery-account-workspace-profile-form [data-nk='fieldset']", count: 0
      assert_select "[data-nk='toast'] [data-slot='toast-item'][data-variant='success']", count: 1
    end
    assert_select "#gallery-account-workspace-missing[data-theme='light']" do
      assert_select "[data-nk='progressive-image'][data-state='empty']", count: 1
      assert_select "[data-slot='details-table-empty']", count: 4
      assert_select "[data-nk='empty-state']", text: /Profile setup has not started/
      assert_select "[data-slot='page-header-description']", count: 0
    end
    assert_select "#gallery-account-workspace-error[data-theme='dark']" do
      assert_select "[data-nk='alert'][data-variant='destructive']", count: 1
      assert_select "[data-nk='fieldset'][disabled]", count: 1
      assert_select "[data-nk='field'][data-state='invalid']", count: 2
      assert_select "#gallery-account-workspace-access-submit[disabled]", count: 1
      assert_select "[data-nk='dialog']", count: 1
      assert_select "[data-nk='toast'] [data-slot='toast-item'][data-variant='error']", count: 1
    end
  end
end
