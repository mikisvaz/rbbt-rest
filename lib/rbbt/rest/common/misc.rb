module RbbtRESTHelpers
  class Retry < Exception; end

  def process_common_parameters
    @ajax = request.xhr?

    @layout = consume_parameter(:_layout)
    @layout = false if @layout.nil? and     @ajax
    @layout = true  if @layout.nil? and not @ajax

    @format = consume_parameter(:_format)
    @format = :html if @format.nil?
    @format = @format.to_sym if String === @format


    @size = consume_parameter(:_size)
    @size = @size.to_sym if String === @size

    @update = consume_parameter(:_update)
    @update = @update.to_sym if String === @update

    @cache_type = consume_parameter(:_cache_type)
    @cache_type = @cache_type.to_sym if String === @cache_type

    @_ = consume_parameter(:_)
  end
 
  def consume_parameter(parameter, params = nil)
    params = self.params if params.nil?
    val = params.delete(parameter.to_sym) || params.delete(parameter.to_s)
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

  def hash_to_html_tag_attributes(hash)
    return "" if hash.nil? or hash.empty?
    hash.collect{|k,v| 
      case 
      when (k.nil? or v.nil? or (String === v and v.empty?))
        nil
      when String === v
        [k,"'" << v << "'"] * "="
      when Symbol === v
        [k,"'" << v.to_s << "'"] * "="
      when TrueClass === v
        [k,"'" << k.to_s << "'"] * "="
      else
        nil
      end
    }.compact * " "
  end

  def html_tag(tag, content = nil, params = {})
    attr_str = hash_to_html_tag_attributes(params)
    html = if content.nil?
      "<#{ tag } #{attr_str} />"
    else
      "<#{ tag } #{attr_str} >#{ content }</#{ tag }>"
    end

    html
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
      #tsv.collect{|id, values| values.unshift(id); values.fields = ([key_field].concat values.fields) if values.respond_to? :fields; values }
      tsv.collect{|id, values| [id, values]}
    when :double
      key_field = tsv.key_field
      tsv.collect{|id, value_lists| value_lists.unshift(id); value_lists.fields = ([key_field].concat value_lists.fields) if values.respond_to? :fields; value_lists }
    end
  end

  def table_value(value)
    value = value.link if value.respond_to? :link

    Array === value ? value * ", " : value
  end
end
