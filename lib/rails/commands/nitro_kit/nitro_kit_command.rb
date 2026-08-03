require "json"
require "rails/command"

module Rails
  module Command
    class NitroKitCommand < Base
      desc "doctor", "Verify the Nitro Kit 2 application and agent integration"
      option :format, type: :string, default: "text", enum: %w[text json],
        desc: "Output human-readable text or structured JSON"
      def doctor
        checks = installation.checks
        if options[:format] == "json"
          say JSON.pretty_generate(checks.map { { status: _1.status, label: _1.label, detail: _1.detail } })
        else
          checks.each do |check|
            color = { pass: :green, warn: :yellow, fail: :red }.fetch(check.status)
            say_status(check.status.to_s.upcase, "#{check.label}: #{check.detail}", color)
          end
        end

        exit 1 if checks.any? { _1.status == :fail }
      end

      desc "prompt", "Print the Nitro Kit 2 initialization prompt"
      option :copy, type: :boolean, default: false,
        desc: "Copy the prompt to the clipboard"
      def prompt
        if options[:copy]
          command = installation.copy_prompt
          say "Copied the Nitro Kit 2 initialization prompt via #{command}."
        else
          say installation.prompt
        end
      rescue RuntimeError => error
        say_error error.message
        exit 1
      end

      private
        def installation
          @installation ||= begin
            boot_application!
            require "nitro_kit/installation"
            NitroKit::Installation.new(Rails.root)
          end
        end
    end
  end
end
