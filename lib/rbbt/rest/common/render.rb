require 'rbbt/util/misc'
require 'rbbt/rest/common/cache'
require 'tilt'

Tilt::SYMBOL_ARRAY_SORTABLE = false
module RbbtRESTHelpers
  def error_for(job, layout = nil)
    if ex = job.info[:exception]
      klass = ex[:class]
      msg = ex[:message]
      bkt = ex[:backtrace]
    elsif job.dirty?
      klass = "Exception"
      msg = "Job dirty"
      bkt = []
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

      reset_js_css 

      result = render template_file, {:job => job}, layout_file

      content_type :html
      halt code, result
    else
      content_type :text
      halt code, "#{klass}: " << msg << "\nBacktrace: " << bkt * "\n"
    end
  end

  def wait_on(job, layout = nil)
    layout = @layout if layout.nil?

    3.times do |rep|
      raise RbbtRESTHelpers::Retry if job.done? or job.error?
      sleep 1
    end if layout

    raise RbbtRESTHelpers::Retry if job.done? or job.error?

    layout_file = (layout ? locate_template('layout') : nil)
    template_file = locate_template('wait')

    status 202
    render template_file, {:job => job}, layout_file
  end

  def render(template_file, locals = {}, layout_file = nil, cache = nil, cache_options = {})
    raise TemplateMissing, "Template #{ template_file } not found" unless template_file.exists?
    raise TemplateMissing, "Template #{ layout_file } not found" unless layout_file.nil? or layout_file.exists?
    layout_file = layout_file.find if layout_file.respond_to? :find
    
    if Path === template_file
      documentation_file = template_file.annotate((template_file.original || template_file).sub(/haml$/, 'md'))
      template_file = template_file.find 
      documentation_file = documentation_file.find
    else
      documentation_file = template_file.sub(/haml$/, 'md')
    end

    if layout_file
      Tilt::HamlTemplate.new(layout_file, :filename => layout_file).render(self, locals) do
        Log.debug{ "Rendering #{template_file} with layout #{Misc.fingerprint cache_options}" }
        cache(cache, locals.merge(:_template_file => template_file, :user => user).merge(cache_options)) do
          if locals[:result] == :load && Step === locals[:job]
            res = locals[:job].load
            locals[:result] = res
          end
          if Open.exists?(documentation_file)
            documentation_layout_file = locate_template('documented_section').find
            markdown = Open.read(documentation_file)
            Tilt::HamlTemplate.new(documentation_layout_file, :filename => documentation_layout_file).render(self, :markdown => markdown) do
              Tilt::HamlTemplate.new(template_file, :filename => template_file).render(self, locals)
            end
          else
            Tilt::HamlTemplate.new(template_file, :filename => template_file).render(self, locals)
          end
        end
      end
    else
      Log.debug{ "Rendering #{template_file} without layout #{Misc.fingerprint cache_options}" }
      cache(cache, locals.merge(:_template_file => template_file, :user => user).merge(cache_options)) do
        if locals[:result] == :load && Step === locals[:job]
          res = locals[:job].load
            locals[:result] = res
        end
        if Open.exists?(documentation_file)
          markdown = Open.read(documentation_file)
          documentation_layout_file = locate_template('documented_section').find
          Tilt::HamlTemplate.new(documentation_layout_file, :filename => documentation_layout_file).render(self, :markdown => markdown) do
            Tilt::HamlTemplate.new(template_file, :filename => template_file).render(self, locals)
          end
        else
          Tilt::HamlTemplate.new(template_file, :filename => template_file).render(self, locals)
        end
      end
    end

  end

  def render_sass(file)
    renderer = SassC::Engine.new(Open.read(file), :filename => file, :syntax => :sass,
                                :style => production? ? :compressed : :nested, :include_paths => RbbtRESTHelpers.sass_resources * ":",
                                :debug_info => development? ? true : false)
    renderer.render
  end

  def render_partial(template_file, locals = {}, cache = nil, cache_options = {})
    render(template_file, locals, nil, cache, cache_options)
  end

  def template_render(template, locals = {}, cache = nil, cache_options = {})
    template_file = locate_template(template)
    layout_file = @layout ? locate_template("layout") : nil

    render(template_file, locals, layout_file, cache, cache_options)
  end

  def partial_render(template, locals = {}, cache = nil, cache_options = {})
    template_file = locate_template(template)
    render(template_file, locals, nil, cache, cache_options)
  end

  def fragment(link = nil, &block)
    fragment_code, link = [link.to_s, nil] if link and not link.to_s[0] == '<'
    text = fragment_code if fragment_code

    if block_given?
      if defined? @step and (@cache_type == :asynchronous or @cache_type == :async)

        fragment_code ||= (rand * 100000).to_i.to_s
        fragment_file = @step.file(fragment_code)
        pid_file = fragment_file + '.pid'

        pid = @step.child{
          begin
            class << @step
              def status=(message)
                nil
              end
            end
            Log.low("Fragment started: #{ fragment_file } - #{Process.pid}")
            #res = capture_haml fragment_code, &block
            res = $haml_6 ? capture(&block) : capture_haml(&block)
            Log.low("Fragment writing: #{ fragment_file } - #{Process.pid}")
            Open.write(fragment_file, res)
            Log.low("Fragment done: #{ fragment_file } - #{Process.pid}")
          rescue Exception
            Open.write(fragment_file + '.error', [$!.class.to_s, $!.message] * ": ")
            Open.write(fragment_file + '.backtrace', $!.backtrace * "\n") if $!.backtrace
            Log.error("Error in fragment: #{ fragment_file }")
            Log.exception $!
            Open.rm pid_file if Open.exists? pid_file
            Kernel.exit! -1
          ensure
            Open.rm pid_file if Open.exists? pid_file
          end
          Kernel.exit! 0
        }
        Open.write(pid_file, pid.to_s)

        url = @fullpath 
        url = remove_GET_param(url, "_update")
        url = remove_GET_param(url, "_")

        fragment_url = add_GET_param(url, "_fragment", fragment_code)
        if link.nil?
          html_tag('a', "", :href => fragment_url, :class => 'fragment', "data-text" => text)
        else
          if FalseClass === link
            return fragment_code
          elsif TrueClass === link
            return fragment_url
          elsif link =~ / href=/
            link = link.sub(/ href=('|")/," href='#{fragment_url}'")
          else
            link = link.sub(/<a /,"<a href='#{fragment_url}' ")
          end

          if text
            link.sub(/<a /,"<a data-text='#{text}' ")
          else
            link
          end
        end
      else
        $haml_6 ? capture(&block) : capture_haml(&block)
      end
    else
      if link =~ / class=/
        link = link.sub(/ class=('|")/,' class=\1fragment ')
      else
        link = link.sub(/<a /,'<a class="fragment" ')
      end
      
      if text
        link.sub(/<a /,"<a data-text='#{text}' ")
      else
        link
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

    filename = Misc.sanitize_filename(Misc.name2basename(filename))

    if @step
      url = add_GET_param(remove_GET_param(@uri, ["_update", "_"]), "_fragment", "html_resources/#{ filename }")
      f = @step.file(:html_resources)[filename].find
    else
      url = "/files/#{ filename }"
      f = settings.file_dir[filename].find
    end

    Open.mkdir(File.dirname(f))

    yield(f)


    type ||= :link
    case type
    when :image
      "<img src='#{url}' alt='#{text}' class='file_resource'/>"
    when :link
      "<a href='#{url}' class='file_resource' download='#{filename}'>#{ text }</a>"
    when :linked_image
      "<a href='#{url}' class='file_resource' target='_blank'><img src='#{url}' class='file_resource'/></a>"
    when :zoomable_image
      id = options[:id] || Misc.digest(filename)
      width, height= [600, 600]
      "<div class='zoomable_image'><img id='#{id}' style='width:#{width}px; height:#{height}px' rel='#{url}' src='#{url}' class='file_resource'/></div>"
    when :mapped_image
      mapid = options[:mapid] || options[:id] + '_map'
      width, height= [300, 300]
      mapfile = f.sub(/\.[^.]+$/, '.html')
      "<div class='mapped_image'>#{Open.read(mapfile)}<img class='has_map' usemap='##{mapid}' rel='#{url}' src='#{url}' class='file_resource'/></div>"
    else
      raise "Type not understood: #{ type }"
    end
  end

  def json_resource(object, filename = nil, promise = true)
    filename = File.basename(TmpFile.tmp_file) if filename.nil?

    if @step
      url = add_GET_param(remove_GET_param(@uri, ["_update", "_"]), "_fragment", "json_resources/#{ filename }")
      f = @step.file(:json_resources)[filename].find
    else
      url = "/files/#{ filename }"
      f = settings.file_dir[filename].find
    end

    Open.write(f, object.to_json)

    if promise
      "rbbt.get('#{url}')"
    else
      url
    end
  end

  def sync_json_resources(objects)
    gets = objects.collect{|object| json_resource(object) }
    "m.sync([#{gets * ", "}])"
  end

  def reveal(text, id = nil, options = nil, &block)
    id ||= "rbbt_reveal_" << (rand * 10000).to_i.to_s

    #content_html = capture_haml(&block)
    content_html = $haml_6 ? capture(&block) : capture_haml(&block)

    options = {} if options.nil?
    options = {:href => "#", "data-reveal-id" => 'modal1', 'attr-reveal_id' => id}.merge(options)
    options[:class] ||= ''
    options[:class] << ' rbbt_reveal_trigger'
    str = html_tag('a', text.to_s, options) << 
          "\n" <<
          html_tag('div', "\n" << content_html << "\n", :id => id, 'class' => 'rbbt_reveal_content') << 
          "\n"

    str
  end
end
 
