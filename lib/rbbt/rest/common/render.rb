require 'rbbt/util/misc'
require 'rbbt/rest/common/cache'

module RbbtRESTHelpers
  def error_for(job, layout = nil)
    layout = @layout if layout.nil?
    layout_file = (layout ? locate_template('layout') : nil)
    template_file = locate_template('error')

    result = render template_file, {:job => job}, layout_file

    job.clean

    status 500
    result
  end

  def wait_on(job, layout = nil)
    3.times do
      sleep 1
      raise RbbtRESTHelpers::Retry if job.done? or job.error?
    end

    layout = @layout if layout.nil?

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

        pid = @step.child {
          begin
            res = capture_haml &block
            Open.write(fragment_file, res)
          rescue Exception
            Open.write(fragment_file + '.error', $!.message)
            Open.write(fragment_file + '.backtrace', $!.backtrace * "\n") if $!.backtrace
            raise $!.message
          end
        }

        url = request.fullpath
        url = remove_GET_param(url, "_update")
        fragment_url = add_GET_param(url, "_fragment", fragment_code)
        html_tag('a', " ", :href => fragment_url, :class => 'fragment')
      else
        yield
        nil
      end
    else
      if link =~ / class=/
        link.sub(/ class=('|")/,' class=\1fragment ')
      else
        link.sub(/<a /,'<a class="fragment" ')
      end
    end
  end

  def table(options = {})

    table_code = (rand * 100000).to_i.to_s
    table_file = @step.file(table_code)

    tsv = yield

    Open.write table_file, tsv.to_s

    partial_render('partials/table', {:rows => tsv_rows(tsv), :header => tsv.all_fields}.merge(options))
  end

  def resource(filename = nil, text = nil, type = nil, options = {})
    case
    when filename.nil?
      filename = File.basename(TmpFile.tmp_file)
    when filename[0] == "."[0]
      extension = filename
      filename = File.basename(TmpFile.tmp_file) + extension
    end

    text ||= filename

    filename = Misc.sanitize_filename(filename)
    f = File.join(settings.file_dir, filename)
    FileUtils.mkdir_p(File.dirname(f))
    yield(f)

    type ||= :link
    case type
    when :image
      "<img src='/files/#{ filename }' class='file_resource'/>"
    when :link
      "<a href='/files/#{ filename }' class='file_resource'>#{ text }</a>"
    when :linked_image
      "<a href='/files/#{ filename }' class='file_resource' target='_blank'><img src='/files/#{ filename }' class='file_resource'/></a>"
    when :zoomable_image
      id = options[:id] || Misc.digest(filename)
      width, height= [600, 600]
      "<div class='zoomable_image'><img id='#{id}' style='width:#{width}px; height:#{height}px' rel='/files/#{ filename }' src='/files/#{ filename }' class='file_resource'/></div>"
    when :mapped_image
      mapid = options[:mapid] || options[:id] + '_map'
      width, height= [300, 300]
      mapfile = f.sub(/\.[^.]+$/, '.html')
      "<div class='mapped_image'>#{Open.read(mapfile)}<img class='has_map' usemap='##{mapid}' rel='/files/#{ filename }' src='/files/#{ filename }' class='file_resource'/></div>"
    else
      raise "Type not understood: #{ type }"
    end
  end
end
 
