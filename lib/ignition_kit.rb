# gemspec doesn't bundle require
require "tailwind_merge"
require "phlex/rails"

module IgnitionKit
  def merge(*args)
    @tailwind_merge ||= TailwindMerge::Merge.new
    @tailwind_merge.merge(*args)
  end

  module Helpers
  end
end
