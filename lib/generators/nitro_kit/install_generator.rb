module NitroKit
  module Generators
    class InstallGenerator < Rails::Generators::Base
      def one
        puts("Maybe, maybe not. Seems complex. Maybe only support greenfield apps?")
        puts("Manual instructions: https://nitrokit.dev/getting_started")
      end
    end
  end
end
