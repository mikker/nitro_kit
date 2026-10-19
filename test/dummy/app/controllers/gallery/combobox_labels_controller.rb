module Gallery
  class ComboboxLabelsController < ApplicationController
    # The search endpoint renders Combobox::Results for the `query` parameter.
    # `combobox` names the requesting control so result IDs stay unique.
    def index
      return head(:service_unavailable) if params[:unavailable].present?

      render ComboboxLabelResults.new(
        combobox: combobox_id,
        query: params[:query],
        labels: ComboboxLabels.search(params[:query])
      ), layout: false
    end

    # A result action posts here. The created (or already existing) label
    # comes back as the single option the Combobox then selects.
    def create
      label = ComboboxLabels.create(params.require(:label).fetch(:name, nil))
      return head(:unprocessable_entity) unless label

      render ComboboxLabelResults.new(combobox: combobox_id, query: nil, labels: [ label ]),
        status: :created, layout: false
    end

    private

    def combobox_id
      id = params[:combobox].to_s
      id.match?(/\A[A-Za-z0-9][A-Za-z0-9_-]*\z/) ? id : "gallery-combobox-labels"
    end
  end
end
