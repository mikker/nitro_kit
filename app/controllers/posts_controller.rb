class PostsController < ApplicationController
  def destroy
    render(turbo_stream: turbo_stream.update("test-result", "Post deleted!"))
  end
end
