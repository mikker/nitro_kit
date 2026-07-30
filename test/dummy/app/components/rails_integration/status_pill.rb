module RailsIntegration
  class StatusPill < ApplicationComponent
    STATUSES = %i[received reviewed].freeze

    def initialize(status, html: {}, data: {}, aria: {})
      @status = status.respond_to?(:to_sym) ? status.to_sym : status
      raise ArgumentError, "Unknown status #{status.inspect}" unless STATUSES.include?(@status)

      @attributes = merge_attributes(
        {
          class: "status-pill status-pill--quiet",
          title: "Submission status",
          data: { application_component: "status-pill", state: @status },
          aria: { live: "polite" }
        },
        html:,
        data:,
        aria:
      )
    end

    def view_template
      span(**attributes) do
        Badge(status.to_s.humanize, color: :success, size: :sm)
      end
    end

    private

    attr_reader :attributes, :status
  end
end
