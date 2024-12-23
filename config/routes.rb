Rails.application.routes.draw do
  get("up" => "rails/health#show", :as => :rails_health_check)

  resource(:posts, only: %i[destroy])
  resource(:flash, only: %i[create destroy])

  get(":page" => "pages#show", :as => :page)
  root("pages#introduction")
end
