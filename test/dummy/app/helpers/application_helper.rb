module ApplicationHelper
  def back_link
    tag.div { nk_button_link_to("Back", tests_path) }
  end
end
