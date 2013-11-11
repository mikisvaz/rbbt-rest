require 'rbbt/entity'

module Link
  extend Entity

  def self.tsv_sort(v)
    value = v.last
    value = value.first if Array === value
    if value and value.match(/<a [^>]*>([^>]*)<\/a>/)
      val = $1
      if val =~ /^\s*\d/
        val.to_f
      else
        val
      end
    else
      ""
    end
  end
end

module NumericValue
  extend Entity

  self.format =(<<-EOF
p-value
p.value
P-value
P.value
p-values
p.values
P-values
P.values
score
scores
ratio
ratios
t.value
t.values
adjusted.p.value
adjusted.p.values
Rank
rank
                EOF
               ).split("\n")

  def <=>(other)
    if Float === self
      super(other.to_f)
    else
      self.to_f <=> other.to_f
    end
  end

  def self.tsv_sort(v)
    value = v.last
    if Array === value
      value.first.to_f
    else
      value.to_f
    end
  end

  def to_s
    "%.5g" % self.to_f
  end
end

module RbbtRESTHelpers
  def tsv_rows_full(tsv)
    case tsv.type 
    when :single
      tsv.collect{|id, value| [id, value]}
    when :list
      key_field = tsv.key_field
      tsv.collect{|id, values| new_values = [id].concat(values); begin NamedArray.setup(new_values, values.fields, id, values.entity_options, values.entity_templates); new_values.fields = [key_field].concat values.fields end if values.respond_to? :fields; new_values }
    when :flat
      key_field = tsv.key_field
      tsv.collect{|id, values| [id, values]}
    when :double
      key_field = tsv.key_field
      tsv.collect{|id, value_lists| new_value_lists = [id].concat(value_lists); begin NamedArray.setup(new_value_lists, value_lists.fields, id, value_lists.entity_options, value_lists.entity_templates); new_value_lists.fields = ([key_field].concat value_lists.fields) end if value_lists.respond_to? :fields; new_value_lists }
    end
  end

  def parse_page(page)
    num, size, field = page.split("~").values_at 0, 1, 2

    field, size = size, nil if field.nil?

    field = "key" if field.nil? or field.empty?
    size = PAGE_SIZE if size.nil? or size.empty?

    [num, size, field]
  end

  def paginate(object, page = nil, just_keys = false)
    return object unless TSV === object and not page.nil?

    return object if page == "all" or page.nil?
    num, size, field = parse_page(page)

    if field and field[0] == "-"[0]
      field = field[1..-1]
      reverse = true
    else
      reverse = false
    end

    if object.entity_templates[field]
      entity = object.entity_templates[field].annotation_types.last
    else
      entity = Entity.formats[field] 
    end

    num = num.to_i
    size = size.to_i
    max = object.size / size + 1

    num = max if num > max
    num = - max if num < - max

    if entity and entity.respond_to? :tsv_sort
      object.page(num, size, field, just_keys, reverse, &entity.method(:tsv_sort))
    else
      object.page(num, size, field, just_keys, reverse)
    end
  end

  def tsv_process(tsv, filter = nil, column = nil)
    filter = @filter if filter.nil?
    column = @column if column.nil?

    if filter and filter.to_s != "false"
      filter.split(";;").each do |f|
        key, value = f.split("~")
        next if value.nil? or value.empty?
        value =  Entity::REST.restore_element(value)

        #invert
        if value =~ /^!\s*(.*)/
          value = $1
          invert = true
        else
          invert = false
        end

        #name
        if value =~ /^:name:\s*(.*)/
          value = $1
          name = true
        else
          name = false
        end

        if name
          old_tsv = tsv
          tsv = tsv.reorder(:key, key).add_field "NAME" do |k,values|
            NamedArray === values ? values[key].name : values.name
          end
          key = "NAME"
        end
        
        case
        when value =~ /^([<>]=?)(.*)/
          tsv = tsv.select(key, invert){|k| k = k.first if Array === k; k.to_f.send($1, $2.to_f)}
        when value =~ /^\/(.+)\/.{0,2}\s*$/
          tsv = tsv.select({key => Regexp.new($1)}, invert)
        when (value =~ /^\d+$/ and tsv.type == :double or tsv.type == :flat)
          tsv = tsv.select({key => value.to_i}, invert)
        else
          tsv = tsv.select({key => value}, invert)
        end

        tsv = old_tsv.select(tsv.keys) if name
      end
    end


    tsv = tsv.column(column) if column and not column.empty?

    tsv
  end

  def tsv_rows(tsv, page = nil, filter = nil, column = nil)
    tsv = tsv_process(tsv, filter, column)
    length = tsv.size
    page = @page if page.nil?
    if page.nil? or page.to_s == "false"
      [tsv_rows_full(tsv), length]
    else
      [tsv_rows_full(paginate(tsv, page)), length]
    end
  end


  def table_value(value, type = nil, options = {})
    options = {} if options.nil?
    return value.list_link :length, options[:list_id] if Array === value and options[:list_id] and value.respond_to? :list_link

    entity_options = options[:entity_options]

    Misc.prepare_entity(value, type, entity_options) if Entity.formats.include? type and not options[:unnamed]

    value = value.link if value.respond_to? :link

    Array === value ? value.collect{|v| v.to_s} * ", " : value
  end

  def header(field, entity_type, entity_options = {})
    @table_headers ||= {}
    @table_headers[field] = [entity_type, entity_options]
  end

  def filter(field, type = :string)
    @table_filters ||= {}
    @table_filters[field] = type
  end

  def self.save_tsv(tsv, path)
    Open.write(path, tsv.to_s)
    table_options = {:tsv_entity_options => tsv.entity_options}
    if tsv.entity_templates and tsv.entity_templates.any?
      table_options[:headers] ||= {}
      tsv.entity_templates.each do |field,template|
        next if table_options[:headers].include? field
        info = template.info
        info.delete :format
        info.delete :annotation_types
        info.delete :annotated_array
        table_options[:headers][field] = [template.annotation_types.last.to_s, info]
      end
    end
    Open.write(path + '.table_options', table_options.to_yaml )
  end

  def self.load_tsv(file)
    tsv = TSV.open(Open.open(file))

    table_options = File.exists?(file + '.table_options') ? YAML.load_file(file + '.table_options') : {}
    tsv.entity_options = table_options[:tsv_entity_options]
    headers = table_options[:headers]
    headers.each{|field,p| tsv.entity_templates[field] = Misc.prepare_entity("TEMPLATE", p.first, (tsv.entity_options || {}).merge(p.last)) } unless headers.nil?

    [tsv, table_options]
  end

  def save_tsv(file)
    RbbtRESTHelpers.save_tsv(file)
  end


  def load_tsv(file)
    RbbtRESTHelpers.load_tsv(file)
  end

  def table(options = {})
    options = {} if options.nil?

    tsv = yield

    table_code = options[:table_id] || (rand * 100000).to_i.to_s
    table_code = Entity::REST.clean_element(table_code)
    table_code.sub!(/[^\w]/,'_')
    table_file = @step.file(table_code)

    url = add_GET_param(@fullpath, "_fragment", File.basename(table_file))
    url = remove_GET_param(url, "_update")
    url = remove_GET_param(url, "_")

    table_class = []
    table_class << 'wide responsive' if tsv.fields.length > 4

    options[:url] = url
    options[:table_class] = table_class
    options[:tsv_entity_options] = tsv.entity_options

    if @table_headers and @table_headers.any?
      options[:headers] = @table_headers
      @table_headers = {}
    end

    if tsv.entity_templates and tsv.entity_templates.any?
      options[:headers] ||= {}
      tsv.entity_templates.each do |field,template|
        next if options[:headers].include? field
        next if template.nil?

        info = template.info
        info.delete :format
        info.delete :annotation_types
        info.delete :annotated_array

        options[:headers][field] = [template.annotation_types.last.to_s, info]
      end
    end

    if @table_filters and @table_filters.any?
      options[:filters] = @table_filters
      @table_filters = {}
    end

    Open.write table_file, tsv.to_s
    Open.write table_file + '.table_options', options.to_yaml if defined? options.any?

    total_size = tsv.size
    if options[:page].nil?  and total_size > PAGE_SIZE * 1.2
      @page = "1"
    else
      @page = options[:page]
    end

    tsv2html(table_file, options)
  end


  def tsv2html(file, default_table_options = {})
    if TSV === file
      tsv, table_options = file, {}
      table_options[:unnamed] = tsv.unnamed
    else
      tsv, table_options = load_tsv(file)
    end

    content_type "text/html"
    rows, length = tsv_rows(tsv)

    table_options = default_table_options.merge(table_options)
    partial_render('partials/table', {:total_size => length, :rows => rows, :header => tsv.all_fields, :table_options => table_options})
  end
end
