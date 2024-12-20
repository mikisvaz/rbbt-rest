require 'rbbt/util/misc'
require 'haml'

module RbbtRESTHelpers
  class Retry < Exception; end

  def persist(name, type = :marshal, options = {}, &block)
    options[:dir] = settings.cache_dir.find
    Persist.persist(name, type, options, &block)
  end

  def check_step(step)
    if File.exist?(step.info_file) and Time.now - File.atime(step.info_file) > 60
      done = step.done?
      running = done ? false : step.running?
      Log.debug{ "Checking on #{step.info_file} (done: #{done}; running: #{running})" }
      if FalseClass === running
        if step.done?
          Log.debug{ "Not aborting zombie #{step.info_file}: it is done" }
        else
          Log.debug{ "Aborting zombie #{step.info_file}" }
          step.abort 
          raise Aborted, "Zombie job aborted"
        end
      end
      FileUtils.touch(step.info_file)
    end
  end

  PAGE_SIZE = 20

  def log(status, message = nil)
    if @step
      @step.log(status, message)
    else
      Log.info{ "[#{ status }] #{ message }" }
    end
  end

  def traverse(items, msg = nil, max = nil, options = {}, &block)
    options[:msg] = msg if msg
    options[:max] = max if max
    msg, max = Misc.process_options options, :msg, :max
    max = TSV.guess_max max if max.nil?
    msg = "Processing" if msg.nil?
    bar = @step.progress_bar(msg, :max => max)
    TSV.traverse items, options.merge(:bar => bar), &block
  end

  def progress(msg = nil, max = nil, &block)
    msg = "Processing" if msg.nil?
    bar = @step.progress_bar(msg, :max => max)
    block.call(bar)
  end

  def development?
    ENV["RACK_ENV"] == "develoment"
  end

  def production?
    settings.environment && settings.environment.to_s == 'production'
  end

  def process_common_parameters
    process_request_and_params(request, params)
  end

  def process_request_and_params(request, params)
    @ajax = request.xhr?
    @params = params

    @uri = request.env["REQUEST_URI"]
    @uri = remove_GET_param(@uri, ["_update", "_", "_layout"])
    @request_method = request.env["REQUEST_METHOD"]
    @is_method_post = @request_method.to_s.downcase == 'post'

    @uri = post_uri if @is_method_post

    @path_info = request.env["PATH_INFO"]
    @query = request.env["QUERY_STRING"]
    @fullpath = (@query && ! @query.empty?) ? @path_info + "?" + @query : @path_info
    @fullpath = remove_GET_param(@fullpath, ["_update", "_", "_layout"])

    @ajax_url = @fullpath

    @layout = consume_parameter(:_layout)

    @layout = false if @layout.nil? and     @ajax
    @layout = true  if @layout.nil? and not @ajax
    @layout = false if @layout == "false"
    @layout = true  if @layout == "true"

    @format = consume_parameter(:_format)
    @format = :html if @format.nil?
    @format = @format.to_sym if String === @format


    @size = consume_parameter(:_size)
    @size = @size.to_sym if String === @size

    @update = consume_parameter(:_update) unless @update
    @update = @update.to_sym if String === @update

    @profile = consume_parameter(:_profile) unless @profile
    @profile = @profile.to_sym if String === @profile

    @cache_type = consume_parameter(:_cache_type)
    @cache_type = @cache_type.to_sym if String === @cache_type

    @debug_js = consume_parameter(:_debug_js)
    @debug_js = false if @debug_js.nil? or @debug_js == "false"

    @debug_css = consume_parameter(:_debug_css)
    @debug_css = false if @debug_css.nil? or @debug_css == "false"

    @_ = consume_parameter(:_)

    @fragment = consume_parameter(:_fragment)
    @file     = consume_parameter(:_file)

    @excel_use_name     = consume_parameter(:_excel_use_name)
    @excel_sort_by      = consume_parameter(:_excel_sort_by)
    @excel_sort_by_cast = consume_parameter(:_excel_sort_by_cast)
    @excel_use_name = true if @excel_use_name.nil?

    @splat = consume_parameter :splat
    @captures = consume_parameter :captures

    # TSV table pagination, filtering, and slicing
    @page = consume_parameter :_page
    @filter = consume_parameter :_filter
    @column = consume_parameter :_column

    # TSV table query
    @entity = consume_parameter :_entity

    # Fix boolean inputs sumbitted using checkboxes
    params.keys.each do |param|
      if param =~ /(.*)_checkbox_false$/
        params[$1] = false if params[$1].nil?
        params.delete param
      end
    end

    @array_separator = consume_parameter(:_array_separator) || ','

    @permalink = consume_parameter :_permalink

    @clean_params = {}
    params.each do |k,v|
      @clean_params[k] = v
    end
  end
 
  def consume_parameter(parameter, params = nil)
    params = @params ||= self.params if params.nil?

    val = params.delete(parameter.to_sym) 
    val = params.delete(parameter.to_s) if val.nil?

    val = nil if String === val and val.empty?

    val
  end

  def fix_input(type, value, param_file = nil)
    case type

    when nil, :string, :select
      value

    when :integer
      value.to_i

    when :float
      value.to_f

    when :multiple
      value.keys

    when :boolean
      param2boolean(value)

    when :text, :file
      if param_file and (value.nil? or (String === value and value.empty?))
        param_file[:tempfile].read
      else
        case value
        when String
          value.gsub(/\r\n/, "\n")
        when File, IO
          value
        when Hash
          value[:tempfile]
        else
          raise "Missing class for #{ type }: #{ Misc.fingerprint value }"
        end
      end

    when :array
      text = if param_file and (value.nil? or (String === value and value.empty?))
               param_file[:tempfile].read
             else
               value
             end

      case
      when Array === text
        text
      when text =~ /^list:([^:]+):(.+)$/
        Entity::List.load_list($1, $2, user)
      when text =~ /^\[.*\]$/sm
        JSON.parse(text)
      when text =~ /\n/
        text.split(/\r?\n/).collect{|l| l.strip}
      when text =~ /\|/
        text.split(/\|/).collect{|l| l.strip}
      when IO === text
        text
      when Hash === text
        io = text[:tempfile].open
        class << io
          attr_accessor :filename
        end
        io.filename = text[:filename]
        io
      when text == "EMPTY_ARRAY"
        []
      when text.nil?
        []
      else
        text.split(/,/).collect{|l| l.strip}
      end

    when :tsv
      if param_file and (value.nil? or (String === value and value.empty?))
        TSV.open(param_file[:tempfile].open)
      else
        TSV.open(StringIO.new(value), :sep=>/\t|,/)
      end
    when :directory
      param_file[:tempfile].close
      Path.setup(param_file[:tempfile].path)
    end
  end

  def prepare_input(params, input, type, stream = false)
    value = consume_parameter(input, params)
    param_file = consume_parameter(input.to_s + '__param_file', params)

    param_file, value = value, nil if Hash === value and value.include? :tempfile

    if stream and param_file
      filename = param_file[:head].match(/filename="(.*?)"\r\n/)[1]
      io = param_file[:tempfile].open
      return ConcurrentStream.setup(io, :filename => filename)
    end

    return nil if value.nil? and param_file.nil?

    fixed_value = fix_input(type, value, param_file)

    fixed_value
  end


  def param2boolean(value)
    case value
    when "true", "True", "TRUE", "T", "yes", "Yes", "y", "Y"
      true
    when "false", "False", "FALSE", "F", "no", "No", "N", "n"
      false
    else
      value
    end
  end

  def html_tag(*args)
    Misc.html_tag(*args)
  end

  def remove_GET_param(url, param)
    if Array === param
      param.each do |p|
        url = remove_GET_param(url, p)
      end
      url
    else
      url.gsub(/&?#{param}=[^&]+/,'').sub(/\?$/, '')
    end
  end

  def add_GET_param(url, param, value)
    url = remove_GET_param(url, param)
    if url =~ /\?.+=/
      url + "&#{ param }=#{ value }"
    else
      url + "?#{ param }=#{ value }"
    end
  end

  def hash2dl(hash, options = {})
    entries = hash.collect{|k,v|
      v = v * ", " if Array === v
      v = hash2dl(v) if Hash === v
      html_tag(:dt, k) + html_tag(:dd, v)
    } * "\n"
    html_tag(:dl, entries, options)
  end

  def permalink(path)
    id = Misc.digest(Time.now.to_s)
    dest = File.join(settings.permalink_dir, id)
    FileUtils.mkdir_p settings.permalink_dir unless File.exist? settings.permalink_dir
    FileUtils.ln_s(path, dest)
    "/permalink/#{ id }"
  end

  def fix_html(html)
    if html !~ /^\s*<html/i
      "<html><meta charset=#{html.encoding.to_s}/><body>" + html + "<body/><html/>"
    else
      html
    end
  end

  def halt_html(html, response = 200)
    content_type "text/html; charset=#{html.encoding.to_s}"
    html = fix_html html
    halt response, html
  end

  def capture(*args, &block)

    variables = block.binding.local_variables
    buff_var = variables.select{|v| v.to_s =~ /^_module\d+$/}.sort_by{|v| v.to_s.scan(/\d+/).first.to_i}.last
    buff_was = block.binding.local_variable_get(buff_var) if variables.include? buff_var
    block.binding.local_variable_set(buff_var,'') if buff_var
    begin
      raw = block.call(*args)
      captured = block.binding.local_variable_get(buff_var) if block.binding.local_variables.include?(buff_var)
      captured = "" if captured.nil?
      captured = raw if captured.empty? 
      captured
    ensure
      block.binding.local_variable_set(buff_var, buff_was) if buff_was
    end
  end
end

if $haml_6
  Haml::Template.options[:escape_html] = false

  class Haml::Filters::DeferJS < Haml::Filters::TiltBase

    def compile(node)
      text = node.value[:text]
      step_path = Thread.current["step_path"]
      text = "" if text.nil?
      defer_text =<<-EOF
%script
  :plain
    defer(function(step_path){

#{text.gsub(/^/,"      ")}
    }, '#{step_path}')
      EOF
      node.value[:text] = defer_text
      compile_with_tilt(node, 'haml')
    end
  end

  class Haml::Filters::Documentation < Haml::Filters::TiltBase

    def compile(node)
      text = node.value[:text]
      text = "<br/>" if text.strip.empty?

      doc_text =<<-EOF
%section.documentation#{ text.gsub(/\s/,'').length < 80 * 10 ? '.short' : ''}
  :markdown
#{text.gsub(/^/,"    ")}
      EOF

      node.value[:text] = doc_text
      compile_with_tilt(node, 'haml')
    end
  end

  class Haml::Filters
    register :deferjs, Haml::Filters::DeferJS
    register :documentation, Haml::Filters::Documentation
  end
else
	module Haml::Filters::DeferJS
		include Haml::Filters::Base

		def render(text)
			step_path = Thread.current["step_path"]
			text = "" if text.nil?
			defer_text =<<-EOF
%script
  :plain
    defer(function(step_path){
#{text.gsub(/^/,"      ")}
    }, '#{step_path}')
      EOF
			Haml::Engine.new(defer_text).to_html 
		end
	end

	module Haml::Filters::Documentation
		include Haml::Filters::Base

		def render(text)
			text = "<br/>" if text.strip.empty?

			doc_text =<<-EOF
%section.documentation#{ text.gsub(/\s/,'').length < 80 * 10 ? '.short' : ''}
  :markdown
#{text.gsub(/^/,"    ")}
      EOF

			Haml::Engine.new(doc_text).to_html  
		end

	end
end
