module Gallery
  class FaqsController < ApplicationController
    def show
      render FaqPage.new
    end
  end
end
