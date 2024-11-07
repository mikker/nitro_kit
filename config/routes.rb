Rails.application.routes.draw do
  get("up" => "rails/health#show", :as => :rails_health_check)

  get(":page" => "pages#show", :as => :page)
  root("pages#introduction")
end
