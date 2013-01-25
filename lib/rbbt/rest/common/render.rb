require 'rbbt/util/misc'
require 'rbbt/rest/common/cache'

module RbbtRESTHelpers
  def wait_on(job)
    7.times do
      sleep 1
      raise Retry if job.done?
    end
    layout_file = (layout ? locate_template('layout') : nil)
    template_file = locate_template('wait')

    status 202
    render template_file, {:job => job}, layout_file
  end

  def render(template_file, locals = {}, layout_file = nil, cache = nil, cache_options = {})
    if layout_file
      Haml::Engine.new(Open.read(layout_file), :filename => layout_file).render(self) do
        cache(cache, locals.merge(:_template_file => template_file, :user => user).merge(cache_options)) do
          Haml::Engine.new(Open.read(template_file), :filename => template_file).render(self, locals)
        end
      end
    else
      cache(cache, locals.merge(:_template_file => template_file, :user => user).merge(cache_options)) do
        Haml::Engine.new(Open.read(template_file), :filename => template_file).render(self, locals)
      end
    end
  end
end
 
