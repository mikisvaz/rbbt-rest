
module Sinatra
  module RbbtToolHelper
    def tool(toolname, options = {})
      options[:id] ||= toolname.to_s + "_#{rand(10000)}"
      partial_render("tools/#{toolname}", options)
    end
  end
end
