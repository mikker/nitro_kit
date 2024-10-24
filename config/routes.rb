Rails.application.routes.draw do
  get("up" => "rails/health#show", :as => :rails_health_check)

  resources(:components, only: [:index, :show])

  root("pages#index")
end
