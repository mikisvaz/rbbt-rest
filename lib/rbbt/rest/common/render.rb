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
    if layout_file
      Haml::Engine.new(Open.read(layout_file), :filename => layout_file).render(self) do
        cache(cache, locals.merge(:_template_file => template_file, :user => user).merge(cache_options)) do
          Log.debug("Rendering #{template_file} with layout")
          Haml::Engine.new(Open.read(template_file), :filename => template_file).render(self, locals)
        end
      end
    else
      cache(cache, locals.merge(:_template_file => template_file, :user => user).merge(cache_options)) do
        Log.debug("Rendering #{template_file} without layout")
        Haml::Engine.new(Open.read(template_file), :filename => template_file).render(self, locals)
      end
    end
  end

  def render_partial(template_file, locals = {}, cache = nil, cache_options = {})
    render(template_file, locals, nil, cache, cache_options)
  end

  def template_render(template, locals = {}, cache = nil, cache_options = {})
    template_file = locate_template(template)
    layout_file = layout ? locate_template("layout") : nil

    render(template_file, locals, layout_file, cache, cache_options)
  end

  def partial_render(template, locals = {}, cache = nil, cache_options = {})
    template_file = locate_template(template)
    render(template_file, locals, nil, cache, cache_options)
  end

  def fragment(link = nil,&block)
    if block_given?
      if defined? @step and cache_type == :asynchronous or cache_type == :async
        fragment_code = (rand * 100000).to_i.to_s
        fragment_file = @step.file(fragment_code)
        Process.fork {
          begin
            res = capture_haml &block
            Open.write(fragment_file, res)
          rescue Exception
            Open.write(fragment_file + '.error', $!.message)
            raise $!.message
          end
        }
        fragment_url = add_GET_param(request.url, "_fragment", fragment_code)
        html_tag('a', " ", :href => fragment_url, :class => 'fragment')
      else
        yield
      end
    else
      if link =~ / class=/
        link.sub(/ class=('|")/,' class=\1fragment ')
      else
        link.sub(/<a /,'<a class="fragment" ')
      end
    end
  end
end
 
