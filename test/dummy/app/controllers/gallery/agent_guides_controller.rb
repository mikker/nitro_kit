module Gallery
  class AgentGuidesController < ApplicationController
    def show
      render AgentGuide.new
    end
  end
end
