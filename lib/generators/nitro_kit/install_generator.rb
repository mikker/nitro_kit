require "rails/generators"
require "nitro_kit/installation"

module NitroKit
  class InstallGenerator < Rails::Generators::Base
    class_option :prompt, type: :boolean, default: true,
      desc: "Offer to copy the initialization prompt"
    class_option :copy_prompt, type: :boolean, default: false,
      desc: "Copy the initialization prompt without asking"

    def install_agent_guidance
      changes = installation.install

      changes.each do |path, status|
        say_status(status == :written ? :create : :identical, path)
      end
    end

    def show_diagnostics
      say ""
      installation.checks.each do |check|
        color = { pass: :green, warn: :yellow, fail: :red }.fetch(check.status)
        say_status(check.status.to_s.upcase, "#{check.label}: #{check.detail}", color)
      end
    end

    def offer_initialization_prompt
      return copy_initialization_prompt if options[:copy_prompt]
      return unless options[:prompt] && $stdin.tty?
      return unless yes?("Copy the Nitro Kit 2 initialization prompt to the clipboard? [y/N]")

      copy_initialization_prompt
    end

    private
      def installation
        @installation ||= Installation.new(destination_root)
      end

      def copy_initialization_prompt
        command = installation.copy_prompt
        say_status :copy, "initialization prompt via #{command}", :green
      rescue RuntimeError => error
        say_status :warning, error.message, :yellow
        say "Run `bin/rails nitro_kit:prompt` to print the prompt instead."
      end
  end
end
