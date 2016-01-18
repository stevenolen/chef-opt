module OptCookbook
  module Helpers
    include Chef::DSL::IncludeRecipe
    def path_plus_bundler
      @path = ENV['PATH']
      @path = "#{new_resource.bundler_path}:#{ENV['PATH']}" if new_resource.bundler_path
      @path
    end
  end
end
