Rails.application.routes.draw do
  resources(:tests)
  root(to: "tests#index")
end
