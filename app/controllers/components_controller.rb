class ComponentsController < ApplicationController
  def show
    render(params[:id])
  end
end
