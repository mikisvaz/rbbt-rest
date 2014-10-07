require 'rbbt/util/misc'

module RbbtRESTHelpers
  class Retry < Exception; end

  PAGE_SIZE = 20

  def log(status, message = nil)
    if @step
      @step.log(status, message)
    else
      Log.info{ "[#{ status }] #{ message }" }
    end
  end

  def development?
    ENV["RACK_ENV"] == "develoment"
  end

  def production?
    settings.environment && settings.environment.to_s == 'production'
  end

  def process_common_parameters
    @ajax = request.xhr?
    @ajax_url = headers["AJAX-URL"]

    @fullpath = request.fullpath

    @layout = consume_parameter(:_layout)
    @layout = false if @layout.nil? and     @ajax
    @layout = true  if @layout.nil? and not @ajax
    @layout = false if @layout == "false"
    @layout = true if @layout == "true"

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

    # Fix boolean inputs sumbitted using checkboxes
    params.keys.each do |param|
      if param =~ /(.*)_checkbox_false$/
        params[$1] = false if params[$1].nil?
        params.delete param
      end
    end

    @array_separator = consume_parameter(:_array_separator) || ','

    @permalink = consume_parameter :_permalink

    @clean_params = params.dup
  end
 
  def consume_parameter(parameter, params = nil)
    params = self.params if params.nil?

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
      else
        text.split(/,/).collect{|l| l.strip}
      end

    when :tsv
      if param_file and (value.nil? or (String === value and value.empty?))
        TSV.open(param_file[:tempfile].open)
      else
        TSV.open(StringIO.new(value), :sep=>/\t|,/)
      end
    end
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
    url.gsub(/&?#{param}=[^&]+/,'').sub(/\?$/, '')
  end

  def add_GET_param(url, param, value)
    if url =~ /\?.+=/
      url + "&#{ param }=#{ value }"
    else
      url + "?#{ param }=#{ value }"
    end
  end

  def hash2dl(hash, options = {})
    entries = hash.collect{|k,v|
      v = v * ", " if Array === v
      html_tag(:dt, k) +
      html_tag(:dd, v)
    } * "\n"
    html_tag(:dl, entries, options)
  end

  def permalink(path)
    id = Misc.digest(Time.now.to_s)
    dest = File.join(settings.permalink_dir, id)
    FileUtils.mkdir_p settings.permalink_dir unless File.exists? settings.permalink_dir
    FileUtils.ln_s(path, dest)
    "/permalink/#{ id }"
  end
end

require 'haml'
module Haml::Filters::DefferJS
  include Haml::Filters::Base

  def render(text)
    deffer_text =<<-EOF
:javascript
  deffer(function(){
#{text.gsub(/^/,"    ")}
  })
EOF
    Haml::Engine.new(deffer_text).to_html  # gfm method defined elsewhere
  end
end
