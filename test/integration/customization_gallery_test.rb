require "test_helper"

class CustomizationGalleryTest < ActionDispatch::IntegrationTest
  test "serves the standalone customization studio from gallery navigation" do
    assert_routing(
      "/gallery/customize",
      controller: "gallery/customizations",
      action: "show"
    )

    get gallery_customize_path

    assert_response :success
    assert_select "link[rel='stylesheet'][href*='customize']"
    assert_select "[data-gallery='navigation'] a[aria-current='page'][href='/gallery/customize']", text: "Customize"
    assert_select "[data-gallery='page'][data-gallery-page='customize'][data-controller='gallery--customizer']"
    assert_select "h1", text: "Customize Nitro Kit"
    assert_select "[data-gallery='theme-preview'][data-theme='light'][data-preview-appearance='system']"
    assert_select "[data-gallery='theme-preview'] [data-nk='app-shell'][data-variant='sidebar']"
  end

  test "renders every labelled closed control with swatches and an isolated appearance choice" do
    get gallery_customize_path

    assert_response :success
    assert_select "form[data-gallery='customizer-controls'][data-action*='gallery--customizer#change']"

    Gallery::ThemePreset::CHOICES.each do |attribute, choices|
      assert_select "fieldset[data-gallery-control='#{attribute}']" do
        assert_select "legend", text: Gallery::CustomizePage::CONTROL_COPY.fetch(attribute).first
        assert_select "input[type='radio'][name='#{attribute}']", count: choices.length
        assert_select "[data-gallery-swatch-kind='#{attribute}'][aria-hidden='true']", count: choices.length
        assert_select "input[name='#{attribute}'][checked][value='#{Gallery::ThemePreset::DEFAULTS.fetch(attribute)}']"
      end
    end

    assert_select "fieldset[data-gallery-control='appearance']" do
      assert_select "input[type='radio'][name='appearance']", count: 3
      assert_select "input[name='appearance'][value='system'][checked]"
      assert_select "[data-gallery-swatch-kind='appearance'][aria-hidden='true']", count: 3
    end

    assert_select "[data-gallery='customizer-status'][role='status'][aria-live='polite'][aria-atomic='true']"
    assert_select "[data-gallery='customizer-errors'][role='alert'][hidden]"
  end

  test "renders selected preset CSS Ruby and rich real-component pressure" do
    preset = Gallery::ThemePreset.new(
      accent: :rose,
      neutral: :stone,
      radius: :lg,
      density: :compact,
      font: :serif,
      shell: :hybrid
    )

    get gallery_customize_path(preset.query_parameters)

    assert_response :success
    preset.query_parameters.except("v").each do |attribute, value|
      assert_select "input[name='#{attribute}'][value='#{value}'][checked]"
    end
    assert_select "[data-gallery='theme-preview'] [data-nk='app-shell'][data-variant='hybrid']"
    document = Nokogiri::HTML(response.body)
    assert_equal preset.preview_css, document.at_css("style[data-gallery--customizer-target='previewStyle']").text
    assert_equal preset.css, document.at_css("code[data-gallery--customizer-target='cssOutput']").text
    assert_equal preset.app_shell_ruby, document.at_css("code[data-gallery--customizer-target='rubyOutput']").text

    %w[
      app-navigation alert badge button card checkbox details-table dialog dropzone
      field progressive-image sortable-table stat-grid
    ].each do |component|
      assert_select "[data-gallery='theme-preview'] [data-nk='#{component}']", minimum: 1
    end
    assert_select "[data-gallery='customizer-exports'] [data-nk='tabs']", count: 1
  end

  test "reports invalid input without reflecting it and restores safe defaults" do
    get gallery_customize_path(
      v: Gallery::ThemePreset::VERSION,
      accent: '<script>alert("no")</script>',
      shell: "drawer",
      radius: "lg"
    )

    assert_response :success
    assert_select "[data-gallery='customizer-errors'][role='alert']:not([hidden])", text: /Accent is not supported.*Shell is not supported/
    assert_select "[data-gallery='customizer-errors']", text: /script/, count: 0
    assert_select "input[name='accent'][value='blue'][checked]"
    assert_select "input[name='shell'][value='sidebar'][checked]"
    assert_select "input[name='radius'][value='lg'][checked]"

    get gallery_customize_path(v: 99, accent: "rose", shell: "hybrid")

    assert_response :success
    assert_select "[data-gallery='customizer-errors']:not([hidden])", text: /Version 1 defaults were restored/
    assert_select "input[name='accent'][value='blue'][checked]"
    assert_select "input[name='shell'][value='sidebar'][checked]"
  end

  test "keeps gallery markup classless and exposes only public generated tokens" do
    get gallery_customize_path(accent: "violet", neutral: "slate", density: "compact")

    assert_response :success
    assert_select "[class]", count: 0
    assert_select "[style]", count: 0
    assert_select "style[data-gallery--customizer-target='previewStyle']", count: 1

    document = Nokogiri::HTML(response.body)
    css = document.at_css("code[data-gallery--customizer-target='cssOutput']").text
    assert_includes css, ':root, [data-theme="light"]'
    assert_includes css, "@media (prefers-color-scheme: dark)"
    assert_includes css, '[data-theme="dark"]'
    refute_includes css, "--_nk-"
  end
end
