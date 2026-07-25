pin "@rails/activestorage", to: "activestorage.esm.js"
pin "nitro_kit", to: "nitro_kit.js"
pin_all_from File.expand_path("../app/javascript/controllers", __dir__), under: "controllers"
