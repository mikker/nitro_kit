Rails.application.routes.draw do
  get("favicon.ico" => redirect("/favicon.svg"))

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get("up" => "rails/health#show", :as => :rails_health_check)
  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  resource(:registration, only: %i[ new create show ])

  namespace :gallery do
    root(to: "home#show")

    get("agent-guide" => "agent_guides#show", as: :agent_guide)
    get("guide" => "guides#show", as: :guide)
    resource(:button_submission, only: :create)
    resource(:destructive_action, only: :destroy)
    resources(:command_palette_results, only: :index)
    get("previews/:kind/:slug/:example" => "previews#show", as: :preview)
    resources(:components, only: :show, param: :slug)
    resources(:upload_submissions, only: :create)
    get("compositions/:slug(/:state)" => "compositions#show", :as => :composition)
  end

  get("llms.txt" => "gallery/llms#show", as: :llms_txt, format: false)

  root(to: "gallery/home#show")
end
