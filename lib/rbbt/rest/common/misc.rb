require 'rbbt/util/misc'

module RbbtRESTHelpers
  class Retry < Exception; end

  def production?
    ENV["RACK_ENV"] == "production"
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

    @update = consume_parameter(:_update)
    @update = @update.to_sym if String === @update

    @profile = consume_parameter(:_profile)
    @profile = @profile.to_sym if String === @profile

    @cache_type = consume_parameter(:_cache_type)
    @cache_type = @cache_type.to_sym if String === @cache_type

    @debug_js = consume_parameter(:_debug_js)
    @debug_js = false if @debug_js.nil? or @debug_js == "false"

    @_ = consume_parameter(:_)

    @fragment = consume_parameter(:_fragment)

    @excel_use_name     = consume_parameter(:_excel_use_name)
    @excel_sort_by      = consume_parameter(:_excel_sort_by)
    @excel_sort_by_cast = consume_parameter(:_excel_sort_by_cast)

    @splat = consume_parameter :splat
    @captures = consume_parameter :captures

    params.keys.each do |param|
      if param =~ /(.*)_checkbox_false$/
        params[$1] = false if params[$1].nil?
        params.delete param
      end
    end

    @clean_params = params.dup
  end
 
  def consume_parameter(parameter, params = nil)
    params = self.params if params.nil?

    val = params.delete(parameter.to_sym) 
    val = params.delete(parameter.to_s) if val.nil?

    val = nil if String === val and val.empty?

    val
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

  def tsv_rows(tsv)

    case tsv.type 
    when :single
      tsv.collect{|id, value| [id, value]}
    when :list
      key_field = tsv.key_field
      tsv.collect{|id, values| values.unshift(id); values.fields = [key_field].concat values.fields if values.respond_to? :fields; values }
    when :flat
      key_field = tsv.key_field
      tsv.collect{|id, values| [id, values]}
    when :double
      key_field = tsv.key_field
      tsv.collect{|id, value_lists| value_lists.unshift(id); value_lists.fields = ([key_field].concat value_lists.fields) if value_lists.respond_to? :fields; value_lists }
    end
  end

  def table_value(value, options = {})
    return value.list_link :length, options[:list_id] if Array === value and options[:list_id] 
    value = value.link if value.respond_to? :link

    Array === value ? value * ", " : value
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
end
