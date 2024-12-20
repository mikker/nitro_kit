# frozen_string_literal: true

class FlashesController < ApplicationController
  def create
    respond_to do |format|
      format.turbo_stream do
        flash.now[:notice] = "Hope it was good!"
      end
    end
  end

  def destroy
    respond_to do |format|
      format.turbo_stream do
        flash.now[:alert] = "That seems wasteful"
      end
    end
  end
end
