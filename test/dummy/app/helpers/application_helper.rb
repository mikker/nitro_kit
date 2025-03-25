module ApplicationHelper
  def back_link
    tag.div { nk_button_link_to("Back", tests_path) }
  end

  def box
    tag.div(class: "px-5 mt-5") { yield }
  end
end
