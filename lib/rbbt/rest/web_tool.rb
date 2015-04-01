
module Sinatra
  module RbbtToolHelper
    def tool(toolname, options = {})
      options[:id] ||= toolname.to_s + "_#{rand(10000)}"

      template_file = locate_template("tools/#{toolname}")
      Log.debug "Loading tool #{toolname} from: #{template_file}"
      content = Tilt::HamlTemplate.new(template_file, :filename => template_file, :ugly => production?).render(self, options)

      styles = begin
                 path = locate_sass("tools/#{toolname}")
                 link_css "/stylesheets/tools/#{toolname}" if path.exists?
               rescue Exception
                 ""
               end

      javascript = begin
                     path = locate_javascript("tools/#{toolname}")
                     link_js "/js-find/tools/#{toolname}" if path.exists?
                   rescue Exception
                     ""
                   end

      styles + content + javascript
    end
  end
end
