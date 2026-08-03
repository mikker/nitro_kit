require "active_model"
require "nitro_kit"
require "set"

unless Rails.env.test?
  raise "nitro_kit/upgrade_smoke_test may only be loaded in Rails test environment"
end

unless defined?(::ApplicationController)
  raise "Nitro Kit upgrade smoke tests require the host ApplicationController"
end

module NitroKit
  module UpgradeSmoke
    PATH = "/_nitro_kit/upgrade_smoke"
    FRAME_ID = "nitro-kit-upgrade-smoke"
    SESSION_KEY = "nitro_kit_upgrade_smoke"

    class Profile
      include ActiveModel::Model
      include ActiveModel::Attributes

      attribute :name, :string

      validates :name, presence: true, length: { minimum: 3 }

      def persisted? = false
    end

    class Surface < Phlex::HTML
      include Phlex::Rails::Helpers::FormWith
      include Phlex::Rails::Helpers::TurboFrameTag

      def initialize(profile:, revision:)
        @profile = profile
        @revision = revision
      end

      def view_template
        section(data: { nitro_kit_upgrade_smoke: "surface" }) do
          turbo_frame_tag(FRAME_ID) do
            render_summary
            render_form
            render_dialog
            render_sheet
          end
        end
      end

      private
        attr_reader :profile, :revision

        def render_summary
          render NitroKit::Card.new(id: "nitro-kit-upgrade-smoke-summary") do |card|
            card.title("Post-mutation component", level: 2)
            card.body do
              p(data: { nitro_kit_upgrade_smoke_value: "name" }) { profile.name }
              render NitroKit::Badge.new("Revision #{revision}", color: :info)
            end
          end
        end

        def render_form
          form_with(
            model: profile,
            scope: :profile,
            url: PATH,
            method: :patch,
            builder: NitroKit::FormBuilder,
            id: "nitro-kit-upgrade-smoke-form",
            data: { turbo_frame: "_top" }
          ) do |form|
            form.group do
              form.field(:name, required: true, description: "This value must survive the mutation.")
              form.submit("Save smoke-test profile", data: { turbo_submits_with: "Saving…" })
            end
          end
        end

        def render_dialog
          render NitroKit::Dialog.new(id: "nitro-kit-upgrade-smoke-dialog") do |dialog|
            dialog.trigger("Review dialog")
            dialog.panel(
              title: "Upgrade dialog",
              description: "The native dialog contract rendered through the host application."
            ) do
              p { "Dialog content remains available after the upgrade." }
            end
          end
        end

        def render_sheet
          render NitroKit::Sheet.new(id: "nitro-kit-upgrade-smoke-sheet", side: :right) do |sheet|
            sheet.trigger("Review sheet")
            sheet.panel(
              title: "Upgrade sheet",
              description: "The native sheet contract rendered through the host application."
            ) do
              p { "Sheet content remains available after the upgrade." }
            end
          end
        end
    end

    class Controller < ::ApplicationController
      def show
        render_surface(profile: current_profile, revision: current_revision)
      end

      def update
        profile = Profile.new(profile_params)

        if profile.valid?
          session[SESSION_KEY] = { "name" => profile.name, "revision" => current_revision + 1 }
          redirect_to PATH, status: :see_other, notice: "Smoke-test profile saved"
        else
          flash.now[:alert] = "Smoke-test profile needs attention"
          render_surface(profile:, revision: current_revision, status: :unprocessable_entity)
        end
      end

      private
        def current_state
          session.fetch(SESSION_KEY, { "name" => "Original workspace", "revision" => 0 })
        end

        def current_profile
          Profile.new(name: current_state.fetch("name"))
        end

        def current_revision
          current_state.fetch("revision")
        end

        def profile_params
          params.require(:profile).permit(:name)
        end

        def render_surface(profile:, revision:, status: :ok)
          render Surface.new(profile:, revision:), status:
        end
    end

    module RouteLifecycle
      ROUTE_BLOCK = proc do
        get PATH, to: Controller.action(:show)
        patch PATH, to: Controller.action(:update)
      end

      @lock = Mutex.new
      @owners = Set.new

      class << self
        def install!(owner)
          ensure_test_environment!

          @lock.synchronize do
            return if @owners.include?(owner)

            install_routes! if @owners.empty?
            @owners.add(owner)
          end
        end

        def uninstall!(owner)
          @lock.synchronize do
            @owners.delete(owner)
            uninstall_routes! if @owners.empty? && route_block_installed?
          end
        end

        private
          def install_routes!
            collisions = %w[GET PATCH].select { |method| exact_route_matches?(method) }
            if collisions.any?
              raise "Nitro Kit upgrade smoke route #{PATH} collides with host #{collisions.join("/")} routing"
            end

            Rails.application.routes.prepend(&ROUTE_BLOCK)
            Rails.application.reload_routes!
          end

          def uninstall_routes!
            prepend_blocks.delete(ROUTE_BLOCK)
            Rails.application.reload_routes!
          end

          def exact_route_matches?(method)
            Rails.application.routes.routes.any? do |route|
              route.verb.to_s.match?(method) && route.path.spec.to_s.split("(", 2).first == PATH
            end
          end

          def route_block_installed?
            prepend_blocks.include?(ROUTE_BLOCK)
          end

          def prepend_blocks
            Rails.application.routes.instance_variable_get(:@prepend)
          end

          def ensure_test_environment!
            return if Rails.env.test?

            raise "Nitro Kit upgrade smoke routes may only be installed in Rails test environment"
          end
      end
    end
  end

  class UpgradeSmokeTest < ActionDispatch::IntegrationTest
    setup { UpgradeSmoke::RouteLifecycle.install!(self) }
    setup :prepare_nitro_kit_upgrade_smoke_test
    teardown { UpgradeSmoke::RouteLifecycle.uninstall!(self) }

    def self.runnable_methods
      self == UpgradeSmokeTest ? [] : super
    end

    test "renders forms overlays flash and one stable Turbo Frame through Rails" do
      get UpgradeSmoke::PATH

      assert_response :success
      assert_host_installation
      assert_select "body section[data-nk='toast']", count: 1
      assert_select "section[data-nitro-kit-upgrade-smoke='surface'] > turbo-frame##{UpgradeSmoke::FRAME_ID}", count: 1 do
        assert_select "form#nitro-kit-upgrade-smoke-form[action='#{UpgradeSmoke::PATH}'][method='post'][data-turbo-frame='_top']" do
          assert_select "input[name='_method'][value='patch']"
          assert_select "input#profile_name[name='profile[name]'][required][data-nk='input']"
          assert_select "label[data-slot='field-label'][for='profile_name']"
          assert_select "button[type='submit'][data-turbo-submits-with='Saving…']"
        end
        assert_native_overlay("dialog", title: "Upgrade dialog")
        assert_native_overlay("sheet", title: "Upgrade sheet")
      end
    end

    test "keeps submitted values errors feedback and the frame boundary on an invalid mutation" do
      patch UpgradeSmoke::PATH,
        params: { profile: { name: "x" } }

      assert_response :unprocessable_entity
      assert_select "turbo-frame##{UpgradeSmoke::FRAME_ID}", count: 1 do
        assert_select "input#profile_name[value='x'][aria-invalid='true'][aria-describedby~='profile_name-errors']"
        assert_select "ul#profile_name-errors[data-slot='field-error'][aria-live='assertive']:not([role]) > li", count: 1
      end
      assert_select "section[data-nk='toast'] [data-nk='toast-item'][data-variant='error']"
    end

    test "redirects after mutation then renders the changed value and flash from Phlex" do
      patch UpgradeSmoke::PATH, params: { profile: { name: "Migrated workspace" } }

      assert_response :see_other
      assert_redirected_to UpgradeSmoke::PATH

      follow_redirect!

      assert_response :success
      assert_select "turbo-frame##{UpgradeSmoke::FRAME_ID}", count: 1 do
        assert_select "article#nitro-kit-upgrade-smoke-summary[data-nk='card']" do
          assert_select "[data-nitro-kit-upgrade-smoke-value='name']", text: "Migrated workspace"
          assert_select "[data-nk='badge']", text: "Revision 1"
        end
        assert_select "input#profile_name[value='Migrated workspace']"
      end
      assert_select "section[data-nk='toast'] [data-nk='toast-item'][data-variant='default']"
    end

    private
      def prepare_nitro_kit_upgrade_smoke_test
      end

      def assert_host_installation
        assert_operator UpgradeSmoke::Controller, :<, ::ApplicationController
        assert_select "html > head link[rel='stylesheet'][href*='nitro_kit']", minimum: 1
        assert_select "html > head script[data-nk-appearance-default]", count: 1
        assert_select "html > head script[type='importmap'], html > head script[type='module'][src], html > head script[defer][src]",
          minimum: 1

        bootstrap = css_select("html > head script[data-nk-appearance-default]").first
        nonced_entrypoint = css_select("html > head script[nonce]").find { |script| script != bootstrap }
        return unless nonced_entrypoint

        assert_equal nonced_entrypoint["nonce"], bootstrap["nonce"]
      end

      def assert_native_overlay(component, title:)
        root = "[data-nk='#{component}']"
        panel_id = "nitro-kit-upgrade-smoke-#{component}-panel"

        assert_select "#{root} [data-slot='#{component}-trigger'][command='show-modal'][commandfor='#{panel_id}']"
        assert_select "#{root} dialog##{panel_id}[data-slot='#{component}-panel']" do
          assert_select "[data-slot='#{component}-title']", text: title
          assert_select "[data-slot='#{component}-close'][command='close'][commandfor='#{panel_id}']"
        end
      end
  end

  module UpgradeSmokeSystemTests
    extend ActiveSupport::Concern

    included do
      setup { UpgradeSmoke::RouteLifecycle.install!(self) }
      setup :prepare_nitro_kit_upgrade_smoke_test
      teardown { UpgradeSmoke::RouteLifecycle.uninstall!(self) }

      test "submits invalid and valid mutations through Turbo in the host application" do
        visit UpgradeSmoke::PATH

        assert_host_installation
        track_turbo_submissions

        find("#profile_name").set("x")
        find("#nitro-kit-upgrade-smoke-form button[type='submit']").click

        assert_selector "#profile_name[value='x'][aria-invalid='true'][aria-describedby~='profile_name-errors']"
        assert_selector "ul#profile_name-errors[data-slot='field-error'][aria-live='assertive']:not([role]) > li", count: 1
        assert_selector "body section[data-nk='toast'] [data-nk='toast-item'][data-variant='error']"
        assert_stable_frame

        find("#profile_name").set("Migrated workspace")
        find("#nitro-kit-upgrade-smoke-form button[type='submit']").click

        assert_selector "[data-nitro-kit-upgrade-smoke-value='name']", text: "Migrated workspace"
        assert_selector "[data-nk='badge']", text: "Revision 1"
        assert_selector "#profile_name[value='Migrated workspace']"
        assert_selector "body section[data-nk='toast'] [data-nk='toast-item'][data-variant='default']"
        assert_stable_frame
        assert_equal 2, evaluate_script("window.__nitroKitUpgradeSmokeTurboSubmissions")
        assert_no_unexpected_console_errors
      end

      test "opens and closes the native Dialog and Sheet in the host browser" do
        visit UpgradeSmoke::PATH

        exercise_overlay("dialog")
        exercise_overlay("sheet")
      end
    end

    private
      def prepare_nitro_kit_upgrade_smoke_test
      end

      def assert_host_installation
        assert_selector "html head link[rel='stylesheet'][href*='nitro_kit']", visible: :all
        assert_selector "html head script[data-nk-appearance-default]", visible: :all
        assert evaluate_script("typeof window.Turbo !== 'undefined'"), "Turbo did not load through the host JavaScript entrypoint"
      end

      def track_turbo_submissions
        execute_script <<~JAVASCRIPT
          window.__nitroKitUpgradeSmokeTurboSubmissions = 0
          document.addEventListener("turbo:submit-end", () => {
            window.__nitroKitUpgradeSmokeTurboSubmissions += 1
          })
        JAVASCRIPT
      end

      def assert_stable_frame
        assert_selector "turbo-frame##{UpgradeSmoke::FRAME_ID}", count: 1
      end

      def assert_no_unexpected_console_errors
        browser = page.driver.browser
        return unless browser.respond_to?(:logs)

        logs = browser.logs
        return unless logs.available_types.map(&:to_s).include?("browser")

        unexpected = logs.get(:browser).select { |entry| entry.level.to_s == "SEVERE" }.reject do |entry|
          entry.message.include?(UpgradeSmoke::PATH) && entry.message.include?("422")
        end
        assert_empty unexpected, "Unexpected severe browser console errors: #{unexpected.map(&:message).join("\n")}"
      rescue StandardError
        # Browser log collection is driver-specific; interaction assertions remain authoritative.
      end

      def exercise_overlay(component)
        root = "#nitro-kit-upgrade-smoke-#{component}"
        panel = "#{root} [data-slot='#{component}-panel']"

        find("#{root} [data-slot='#{component}-trigger']").click
        assert_selector "#{panel}[open]"
        assert_selector "#{panel} [data-slot='#{component}-title']", text: "Upgrade #{component}"

        find("#{panel} [data-slot='#{component}-close']").click
        assert_no_selector "#{panel}[open]"

        find("#{root} [data-slot='#{component}-trigger']").click
        execute_script <<~JAVASCRIPT, find(panel)
          arguments[0].dispatchEvent(new MouseEvent("click", {
            bubbles: true,
            clientX: -1,
            clientY: -1
          }))
        JAVASCRIPT
        assert_no_selector "#{panel}[open]"
      end
  end
end
