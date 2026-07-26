require "test_helper"

class LocaleTest < ActiveSupport::TestCase
  LOCALE_FILE = NitroKit::Engine.root.join("config/locales/en.yml")

  def with_locale(locale, translations)
    enforced = I18n.config.enforce_available_locales
    I18n.config.enforce_available_locales = false
    I18n.backend.store_translations(locale, translations)
    I18n.with_locale(locale) { yield }
  ensure
    I18n.config.enforce_available_locales = enforced
    I18n.backend.reload!
  end

  def render(component)
    Nokogiri::HTML.fragment(component.call).first_element_child
  end

  test "the engine ships one nitro_kit locale namespace and loads it" do
    assert_includes I18n.load_path, LOCALE_FILE.to_s

    translations = YAML.load_file(LOCALE_FILE)

    assert_equal %w[en], translations.keys
    assert_equal %w[nitro_kit], translations.fetch("en").keys
  end

  test "shipped defaults render English" do
    assert_equal "Pagination", I18n.t("nitro_kit.pagination.label")
    assert_equal "Image unavailable", I18n.t("nitro_kit.progressive_image.unavailable")
    assert_equal "2 options available.", I18n.t("nitro_kit.combobox.results", count: 2)
  end

  test "an application translation overrides every shipped string" do
    with_locale(
      :xx,
      nitro_kit: {
        pagination: { label: "Sidenavigation", previous: "Forrige", next: "Næste" },
        progressive_image: { unavailable: "Billedet er utilgængeligt" },
        details_table: { empty: "Ikke angivet", boolean_true: "Ja", boolean_false: "Nej" },
        dialog: { close: "Luk dialog" },
        toast: { label: "Beskeder", dismiss: "Afvis besked" },
        avatar_stack: { overflow: "%{count} flere" },
        dropzone: { label: "Vedhæft filer", prompt: "Slip filer her." },
        combobox: { no_results: "Ingen muligheder." }
      }
    ) do
      pagination = render(
        NitroKit::Pagination.new do |nav|
          nav.prev(href: "/?page=1")
          nav.page("2", current: true)
          nav.next(href: "/?page=3")
        end
      )

      assert_equal "Sidenavigation", pagination["aria-label"]
      assert_includes pagination.text, "Forrige"
      assert_includes pagination.text, "Næste"

      dropzone = render(NitroKit::Dropzone.new(id: "upload", name: "upload[file]"))

      assert_equal "Vedhæft filer", dropzone.at_css("[data-slot='dropzone-title']").text
      assert_equal "Slip filer her.", dropzone.at_css("[data-slot='dropzone-instruction']").text

      combobox = render(
        NitroKit::Combobox.new(
          id: "region",
          name: "region",
          label: "Region",
          options: [ [ "Europe", "eu" ] ]
        )
      )

      assert_equal "Ingen muligheder.", combobox["data-nk--combobox-no-results-value"]

      toast = render(NitroKit::Toast.new { |list| list.item(description: "Gemt") })

      assert_equal "Beskeder", toast["aria-label"]
      assert_equal "Afvis besked", toast.at_css("[data-slot='toast-item-dismiss']")["aria-label"]

      stack = render(
        NitroKit::AvatarStack.new(label: "Holdet", max: 1) do |group|
          group.avatar(fallback: "AB")
          group.avatar(fallback: "CD")
        end
      )

      assert_equal "1 flere", stack.at_css("[data-slot='avatar-stack-overflow']")["aria-label"]
    end
  end

  test "keyword overrides still win over the locale" do
    with_locale(:xx, nitro_kit: { pagination: { label: "Sidenavigation" } }) do
      pagination = render(
        NitroKit::Pagination.new(label: "Result pages") { |nav| nav.page("1", current: true) }
      )

      assert_equal "Result pages", pagination["aria-label"]
    end
  end
end
