require 'rbbt/entity'

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
                EOF
               ).split("\n")

  def <=>(other)
    self.to_f <=> other.to_f
  end

  def self.tsv_sort(v)
    value = v.last
    if Array === value
      value.first.to_f
    else
      value.to_f
    end
  end
end

module RbbtRESTHelpers
  def tsv_rows_full(tsv)
    case tsv.type 
    when :single
      tsv.collect{|id, value| [id, value]}
    when :list
      key_field = tsv.key_field
      tsv.collect{|id, values| values = NamedArray.setup([id].concat(values), values.fields, id, values.entity_options, values.entity_templates); values.fields = [key_field].concat values.fields if values.respond_to? :fields; values }
    when :flat
      key_field = tsv.key_field
      tsv.collect{|id, values| [id, values]}
    when :double
      key_field = tsv.key_field
      tsv.collect{|id, value_lists|  value_lists = NamedArray.setup([id].concat(value_lists), value_lists.fields, id, value_lists.entity_options, value_list.entity_templates); value_lists.fields = ([key_field].concat value_lists.fields) if value_lists.respond_to? :fields; value_lists }
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

    entity = Entity.formats[field]

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

  def tsv_rows(tsv, page = nil)
    page = @page if page.nil?
    if page.nil? or page.to_s == "false"
      tsv_rows_full(tsv)
    else
      tsv_rows_full(paginate(tsv, page))
    end
  end


  def table_value(value, type = nil, options = {})
    options = {} if options.nil?
    return value.list_link :length, options[:list_id] if Array === value and options[:list_id] 

    entity_options = options[:entity_options]

    Misc.prepare_entity(value, type, entity_options) if Entity.formats.include? type

    value = value.link if value.respond_to? :link

    Array === value ? value * ", " : value
  end

  def header(field, entity_type, entity_options = {})
    @table_headers ||= {}
    @table_headers[field] = [entity_type, entity_options]
  end

  def table(options = {})
    options = {} if options.nil?

    tsv = yield

    table_code = (rand * 100000).to_i.to_s
    table_file = @step.file(table_code)

    url = add_GET_param(@fullpath, "_fragment", File.basename(table_file))
    url = remove_GET_param(url, "_update")
    url = remove_GET_param(url, "_")

    table_class = []
    table_class << 'wide' if tsv.fields.length > 4

    options[:url] = url
    options[:table_class] = table_class
    options[:tsv_entity_options] = tsv.entity_options

    if @table_headers and @table_headers.any?
      options[:headers] = @table_headers
      @table_headers = {}
    end

    Open.write table_file, tsv.to_s
    Open.write table_file + '.table_options', options.to_yaml if defined? options.any?

    total_size = tsv.size
    if options[:page].nil?  and total_size > PAGE_SIZE * 1.2
        page = "1"
    end

    partial_render('partials/table', {:page => page, :total_size => total_size, :rows => tsv_rows(tsv, page), :header => tsv.all_fields, :url => url, :table_class => table_class * " ", :table_options => options.dup})
  end

  def tsv2html(file)
    tsv = TSV.open(Open.open(file))
    table_options = YAML.load_file(file + '.table_options') if File.exists? file + '.table_options'
    tsv.entity_options = table_options[:tsv_entity_options]
    headers = table_options[:headers]
    headers.each{|field,p| tsv.entity_templates[field] = Misc.prepare_entity("TEMPLATE", p.first, p.last) } unless headers.nil?
    content_type "text/html"
    halt 200, partial_render('partials/table', {:total_size => tsv.size, :rows => tsv_rows(tsv), :header => tsv.all_fields, :table_options => table_options})
  end
end
