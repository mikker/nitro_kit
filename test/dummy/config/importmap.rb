# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin "@github/combobox-nav", to: "@github--combobox-nav.js" # @3.0.1
pin "@floating-ui/core", to: "@floating-ui--core.js" # @1.6.9
pin "@floating-ui/dom", to: "@floating-ui--dom.js" # @1.6.13
pin "@floating-ui/utils", to: "@floating-ui--utils.js" # @0.2.9
pin "@floating-ui/utils/dom", to: "@floating-ui--utils--dom.js" # @0.2.9
pin_all_from "app/javascript/controllers", under: "controllers"
pin_all_from "../../app/javascript/controllers", under: "controllers"
