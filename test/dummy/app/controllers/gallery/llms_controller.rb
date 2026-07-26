module Gallery
  # /llms.txt: the agent guide as plain text, rendered from the same sources as
  # the HTML page.
  class LlmsController < ::ApplicationController
    def show
      render plain: LlmsText.call(origin: request.base_url)
    end
  end
end
