require "test_helper"

# The gallery's three top-level pages are audience-oriented: Introduction says
# what this is, the agent guide is the machine entry point (also served as
# /llms.txt), and the human guide explains how to read the test bed.
class GalleryGuidesTest < ActionDispatch::IntegrationTest
  test "the top navigation offers exactly the three audience entry points" do
    get gallery_root_path

    assert_response :success
    assert_select "#gallery-navigation > [data-slot='app-navigation-body'] > [data-slot='app-navigation-item']", count: 3
    assert_select "#gallery-navigation a[href='/gallery']", text: "Introduction"
    assert_select "#gallery-navigation a[href='/gallery/agent-guide']", text: "Agent guide"
    assert_select "#gallery-navigation a[href='/gallery/guide']", text: "Human guide"
    assert_select "[data-gallery='navigation'] a", text: "FAQ", count: 0
    assert_select "[data-gallery='navigation'] a", text: "Customize", count: 0
  end

  test "the introduction frames the gallery and points at each surface" do
    get gallery_root_path

    assert_response :success
    assert_select "[data-gallery-page='home'] h1", text: "Nitro Kit"
    assert_select "[data-gallery='introduction'] h2", text: "What this is"
    assert_select "[data-gallery='introduction'] h2", text: "Who each surface serves"
    assert_select "[data-gallery='introduction'] a[href='https://nitrokit.dev']", text: "nitrokit.dev"
    assert_select "[data-gallery='introduction'] a[href='/gallery/agent-guide']"
    assert_select "[data-gallery='introduction'] a[href='/gallery/guide']"
    assert_select "[data-gallery='introduction'] a[href='/llms.txt']"
  end

  test "the agent guide carries the composition model and the live system rules" do
    assert_routing(
      { path: "/gallery/agent-guide", method: :get },
      { controller: "gallery/agent_guides", action: "show" }
    )

    get gallery_agent_guide_path

    assert_response :success
    assert_select "[data-gallery='navigation'] a[aria-current='page'][href='/gallery/agent-guide']"
    assert_select "[data-gallery='page'][data-gallery-page='agent-guide']"
    assert_select "h1", text: "Agent guide"
    assert_select "h2", text: "The composition model"
    assert_select "h2", text: "Every component page is self-contained"
    assert_select "a[href='/llms.txt']"

    assert_select "[data-gallery-reference='system-rules'] [data-gallery='reference-rules'] li",
      count: Gallery::AgentRules.rules.size
    assert_select "[data-gallery-reference='contract']", count: 0

    rules = css_select("[data-gallery='reference-rules'] li").map(&:text).join(" ")
    NitroKit::Component::RESERVED_DATA_ATTRIBUTES.each { |name| assert_includes rules, "data-#{name}" }
    NitroKit::Component::ADDITIVE_DATA_ATTRIBUTES.each { |name| assert_includes rules, "data-#{name}" }
    NitroKit::Component::FORBIDDEN_ATTRIBUTES.each { |name| assert_includes rules, name }
    assert_includes rules, "desperately_need_a_class:"
  end

  test "the agent guide absorbs the retired FAQ rationale" do
    get gallery_agent_guide_path

    assert_response :success
    assert_select "h2", text: "Why the system refuses things"
    assert_select "[data-gallery='guide-question']", count: Gallery::AgentGuide::QUESTIONS.size
    assert_select "[data-gallery-question='no-class'] h3", text: "Why is there no class: prop?"
    assert_select "[data-gallery-question='why-not-tailwind'] h3", text: "Why not Tailwind?"
    assert_select "[data-gallery-question='ownership']"
    assert_select "[data-gallery-question='rails-and-turbo']"
    assert_select "code", text: "desperately_need_a_class:"
  end

  test "llms.txt serves the same guide as plain text" do
    get llms_txt_path

    assert_response :success
    assert_equal "text/plain", response.media_type

    body = response.body
    assert_includes body, "# Nitro Kit 2.0 — Agent guide"
    assert_includes body, Gallery::AgentGuide::INTRO
    assert_includes body, "## The composition model"
    assert_includes body, "## Why the system refuses things"
    assert_includes body, "## System rules"
    Gallery::AgentRules.rules.each { |rule| assert_includes body, rule }
    assert_includes body, "http://www.example.com/gallery/components/button"
    assert_includes body, "http://www.example.com/gallery/compositions/sign-in/default"
  end

  test "the human guide explains the test bed and points at the documentation site" do
    assert_routing(
      { path: "/gallery/guide", method: :get },
      { controller: "gallery/guides", action: "show" }
    )

    get gallery_guide_path

    assert_response :success
    assert_select "[data-gallery='navigation'] a[aria-current='page'][href='/gallery/guide']"
    assert_select "[data-gallery='page'][data-gallery-page='guide']"
    assert_select "h1", text: "Human guide"
    assert_select "h2", text: "Reading a component page"
    assert_select "h2", text: "What the compositions are"
    assert_select "h2", text: "Theming basics"
    assert_select "li", text: /Preview shows the rendered example/
    assert_select "a[href='https://nitrokit.dev']", text: "nitrokit.dev"
    assert_select "a[href='https://nitrokit.dev/customize']", minimum: 1
    assert_select "a[href='https://nitrokit.dev/pro']"
    assert_select "a[href='/gallery/agent-guide']", text: "agent guide"
    assert_select "code", text: "--nk-*"
  end

  test "the retired FAQ and customizer routes are gone" do
    get "/gallery/faq"
    assert_response :not_found

    get "/gallery/customize"
    assert_response :not_found
  end

  test "guide markup does not rely on classes or inline styles" do
    [ gallery_agent_guide_path, gallery_guide_path ].each do |path|
      get path

      assert_response :success
      assert_select "[class]", count: 0
      assert_select "[style]", count: 0
    end
  end
end
