require 'rbbt/util/misc'
require 'rbbt/rest/common/cache'

module RbbtRESTHelpers
  def error_for(job)
    layout_file = (layout ? locate_template('layout') : nil)
    template_file = locate_template('error')


    result = render template_file, {:job => job}, layout_file

    job.clean

    status 202
    result
  end

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
    Log.debug("Rendering #{template_file} #{layout_file ? layout_file : "No layout"}")
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

  def fragment(&block)
    if defined? @step and cache_type == :asynchronous or cache_type == :async
      fragment_code = (rand * 100000).to_i.to_s
      Process.fork {
        res = capture_haml &block
        fragment_file = @step.file(fragment_code)
        ddd fragment_file
        ddd res
        Open.write(fragment_file, res)
      }
      fragment_url = add_GET_param(request.url, "_fragment", fragment_code)
      html_tag('a', " ", :href => fragment_url, :class => 'fragment')
    else
      yield
    end
  end
end
 
