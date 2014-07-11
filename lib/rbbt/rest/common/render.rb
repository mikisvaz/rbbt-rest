require 'rbbt/util/misc'
require 'rbbt/rest/common/cache'
require 'tilt'

module RbbtRESTHelpers
  def error_for(job, layout = nil)
    if ex = job.info[:exception]
      klass = ex[:class]
      msg = ex[:message]
      bkt = ex[:backtrace]
    else
      klass = "Exception"
      msg = job.messages[-1]
      bkt = []
    end

    code = klass.to_s == "ParameterException" ? 400 : 500
    case @format
    when :json
      halt code, {"message" => msg, "backtrace" => bkt}.to_json
    when :html
      layout = @layout if layout.nil?
      layout_file = (layout ? locate_template('layout') : nil)
      template_file = locate_template('error')

      result = render template_file, {:job => job}, layout_file

      halt code, result
    else
      content_type :text
      halt code, "#{klass}: " << msg << "\nBacktrace: " << bkt * "\n"
    end
  end

  def wait_on(job, layout = nil)
    3.times do
      sleep 1
    end

    raise RbbtRESTHelpers::Retry if job.done? or job.error?

    layout = @layout if layout.nil?

    layout_file = (layout ? locate_template('layout') : nil)
    template_file = locate_template('wait')

    status 202
    render template_file, {:job => job}, layout_file
  end

  def render(template_file, locals = {}, layout_file = nil, cache = nil, cache_options = {})
    raise TemplateMissing, "Template #{ template_file } not found" unless template_file.exists?
    raise TemplateMissing, "Template #{ layout_file } not found" unless layout_file.nil? or layout_file.exists?
    layout_file = layout_file.find if layout_file.respond_to? :find
    template_file = template_file.find if layout_file.respond_to? :find
    if layout_file
      #Haml::Engine.new(Open.read(layout_file), :filename => layout_file, :ugly => production?).render(self, locals) do
      Tilt::HamlTemplate.new(layout_file, :filename => layout_file, :ugly => production?).render(self, locals) do
        cache(cache, locals.merge(:_template_file => template_file, :user => user).merge(cache_options)) do
          Log.debug{ "Rendering #{template_file} with layout" }
          #Haml::Engine.new(Open.read(template_file), :filename => template_file, :ugly => production?).render(self, locals)
          Tilt::HamlTemplate.new(template_file, :filename => template_file, :ugly => production?).render(self, locals)
        end
      end
    else
      cache(cache, locals.merge(:_template_file => template_file, :user => user).merge(cache_options)) do
        Log.debug{ "Rendering #{template_file} without layout" }
        #Haml::Engine.new(Open.read(template_file), :filename => template_file, :ugly => production?).render(self, locals)
        Tilt::HamlTemplate.new(template_file, :filename => template_file, :ugly => production?).render(self, locals)
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

  def fragment(link = nil, &block)
    fragment_code, link = [link.to_s, nil] if link and not link.to_s[0] == '<'
    if block_given?
      if defined? @step and (@cache_type == :asynchronous or @cache_type == :async)
        fragment_code ||= (rand * 100000).to_i.to_s
        fragment_file = @step.file(fragment_code)

        pid = @step.child{
          begin
            res = capture_haml &block
            Open.write(fragment_file, res)
          rescue Exception
            Open.write(fragment_file + '.error', $!.message)
            Open.write(fragment_file + '.backtrace', $!.backtrace * "\n") if $!.backtrace
            Log.error("Error in fragment: #{ fragment_file }")
            raise $!
          end
        }

        url = request.fullpath
        url = remove_GET_param(url, "_update")
        url = remove_GET_param(url, "_")
        fragment_url = add_GET_param(url, "_fragment", fragment_code)
        if link.nil?
          html_tag('a', "", :href => fragment_url, :class => 'fragment')
        else
          if link =~ / href=/
            link.sub(/ href=('|")/," href='#{fragment_url}'")
          else
            link.sub(/<a /,"<a href='#{fragment_url}' ")
          end
        end
      else
        capture_haml &block
      end
    else
      if link =~ / class=/
        link.sub(/ class=('|")/,' class=\1fragment ')
      else
        link.sub(/<a /,'<a class="fragment" ')
      end
    end
  end

  def modal_fragment(text, &block)
    link = "<a class='modal_fragment'>#{text}</a>"
    fragment(link, &block)
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

  def reveal(text, id = nil, &block)
    id ||= "rbbt_reveal_" << (rand * 10000).to_i.to_s

    content_html = capture_haml(&block)

    str = html_tag('a', text.to_s, :href => "#", "data-reveal-id" => 'modal1', 'attr-reveal_id' => id, 'class' => 'rbbt_reveal_trigger') << 
          "\n" <<
          html_tag('div', "\n" << content_html << "\n", :id => id, 'class' => 'rbbt_reveal_content') << 
          "\n"

    str
  end
end
 
