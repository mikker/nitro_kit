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

    get("faq" => "faqs#show", as: :faq)
    get("customize" => "customizations#show", as: :customize)
    get("previews/:kind/:slug/:example" => "previews#show", as: :preview)
    resources(:components, only: :show, param: :slug)
    resources(:blocks, only: :show, param: :slug)
    resources(:upload_submissions, only: :create)
    get("flows/:slug(/:state)" => "flows#show", :as => :flow)
  end

  root(to: "gallery/home#show")
end
