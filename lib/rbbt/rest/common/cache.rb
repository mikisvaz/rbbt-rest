
require 'rbbt/rest/common/users'
require 'rbbt/rest/common/table'

module RbbtRESTHelpers

  MEMORY_CACHE = {}

  def old_cache(path, check)
    return false if production?
    return false if check.nil? or check.empty?
    return false if not File.exists? path
    check = [check] unless Array === check
    check.each do |file|
      if not File.exists?(file)
        return true 
      end
      if File.mtime(file) > File.mtime(path)
        return true 
      end
    end
    return false
  end

  def cache(name, params = {}, &block)
    @cache_type ||= params.delete :cache_type if params[:cache_type]
    return yield if name.nil? or @cache_type.nil? or @cache_type == :none

    send_file = consume_parameter(:_send_file, params)

    # Setup Step
    
    check = [params[:_template_file]].compact
    check += consume_parameter(:_cache_check, params) || []
    check.flatten!
    
    orig_name = name
    name += "_" << Misc.hash2md5(params) if params.any?

    path = params[:cache_file] || settings.cache_dir[name].find
    task = Task.setup(:name => orig_name, :result_type => :string, &block)

    step = Step.new(path, task, nil, nil, self)

    halt 200, step.info.to_json if @format == :info

    self.instance_variable_set("@step", step)

    if @file
      send_file step.file(@file), :filename => @file
    end

    # Clean/update job

    if not @fragment and (old_cache(step.path, check) or update == :reload)
      begin
        pid = step.info[:pid] 
        step.abort if pid and Misc.pid_exists?(pid) and not pid == Process.pid
        step.pid = nil
      rescue Exception
        Log.medium{$!.message}
      end
      step.clean 
    end

    clean_url = request.url
    clean_url = remove_GET_param(clean_url, :_update)
    clean_url = remove_GET_param(clean_url, :_)

    class << step
      def url
        @url
      end

      def knowledge_base(organism = Organism.default_code("Hsa"))
        @_kb ||= begin
                   kb_dir = self.file('knowledge_base')
                   KnowledgeBase.new kb_dir, organism
                 end
      end
    end

    step.instance_variable_set(:@url, clean_url)
    step.instance_variable_set(:@url_path, URI(clean_url).path)

    Thread.current["step_path"] = step.path
    # Issue
    if not step.started?
      if cache_type == :synchronous or cache_type == :sync
        step.run 
      else
        step.fork
        step.soft_grace
      end
      step.set_info :template_file, params[:_template_file]
    end

    # Return fragment

    if @fragment
      fragment_file = step.file(@fragment)
      if File.exists?(fragment_file)
        case @format.to_s
        when "query-entity"
          tsv, table_options = load_tsv(fragment_file, true)
          begin
            res = tsv[@entity].to_json
            content_type "application/json" 
          rescue
            res = nil.to_json
          end
          halt 200, res 
        when "query-entity-field"
          tsv, table_options = load_tsv(fragment_file, true)
          begin
            res = tsv[@entity]
            res = [res] if tsv.type == :single or tsv.type == :flat
          rescue
            res = nil.to_json
          end

          fields = tsv.fields
          content_type "application/json" 
          hash = {}
          fields.each_with_index do |f,i|
            hash[f] = res.nil? ? nil : res[i]
          end

          halt 200, hash.to_json 
        when "table"
          halt 200, tsv2html(fragment_file)
        when "json"
          halt 200, tsv_process(load_tsv(fragment_file).first).to_json
        when "tsv"
          content_type "text/tab-separated-values"
          halt 200, tsv_process(load_tsv(fragment_file).first).to_s
        when "values"
          tsv = tsv_process(load_tsv(fragment_file).first)
          list = tsv.values.flatten
          content_type "application/json" 
          halt 200, list.compact.to_json
        when "entities"
          raw_tsv, tsv_options = load_tsv(fragment_file)
          tsv = tsv_process(raw_tsv)

          list = tsv.values.flatten
          tsv.prepare_entity(list, tsv.fields.first, tsv.entity_options)
          type = list.annotation_types.last
          list_id = "List of #{type} in table #{ @fragment }"
          list_id << " (#{ @filter })" if @filter
          Entity::List.save_list(type.to_s, list_id, list, user)
          header "Location", Entity::REST.entity_list_url(list_id, type)
          url = Entity::REST.entity_list_url(list_id, type)
          url = url + '?_layout=false' unless @layout
          redirect to(url)
        when "map"
          raw_tsv, tsv_options = load_tsv(fragment_file)
          raw_tsv.unnamed = true
          Log.tsv raw_tsv
          tsv = tsv_process(raw_tsv)

          field = tsv.key_field
          column = tsv.fields.first

          if tsv.entity_templates[field] 
            type = tsv.entity_templates[field].annotation_types.first
          else
            type = [Entity.formats[field]].compact.first || field
          end

          map_id = "Map #{type}-#{column} in #{ @fragment }"
          map_id << " (#{ @filter.gsub(';','|') })" if @filter
          Entity::Map.save_map(type.to_s, column, map_id, tsv, user)
          url = Entity::REST.entity_map_url(map_id, type, column)
          url = url + '?_layout=false' unless @layout
          redirect to(url)
        when "excel"
          require 'rbbt/tsv/excel'
          tsv, tsv_options = load_tsv(fragment_file)
          content_type "text/html"
          data = nil
          excel_file = TmpFile.tmp_file
          tsv.excel(excel_file, :sort_by => @excel_sort_by, :sort_by_cast => @excel_sort_by_cast, :name => true, :remove_links => true)
          send_file excel_file, :type => 'application/vnd.ms-excel', :filename => 'table.xls'
        else
          content_type "text/html"
          send_file fragment_file
        end
      elsif Open.exists?(fragment_file + '.error') 
        klass, _sep, message = Open.read(fragment_file + '.error').partition(": ")
        backtrace = Open.read(fragment_file + '.backtrace').split("\n")
        exception =  Kernel.const_get(klass).new message || "no message"
        exception.set_backtrace backtrace
        raise exception
        #halt 500, html_tag(:span, File.read(fragment_file + '.error'), :class => "message") + 
        #  html_tag(:ul, File.read(fragment_file + '.backtrace').split("\n").collect{|l| html_tag(:li, l)} * "\n", :class => "backtrace") 
      elsif Open.exists?(fragment_file + '.pid') 
        pid = Open.read(fragment_file + '.pid')
        if Misc.pid_exists?(pid.to_i)
          halt 202, "Fragment not completed"
        else
          halt 500, "Fragment aborted"
        end
      else
        halt 500, "Fragment not completed and no pid file"
      end
    end

    if update == :reload
      redirect to(clean_url)
    end

    # Monitor
    
    begin

      if step.done?
        case
        when @permalink
          redirect to(permalink(step.path))
        when send_file
          send_file step.path
        else
          step.load
        end
      else

        case step.status
        when :error, :aborted
          error_for step, !@ajax

        else
          # check for problems
          begin
            check_step step
          rescue Aborted
            step.clean
            raise RbbtRESTHelpers::Retry
          end

          #if File.exists?(step.info_file) and Time.now - File.atime(step.info_file) > 60
          #  Log.debug{ "Checking on #{step.info_file}" }
          #  running = (not step.done?) and step.running?
          #  if FalseClass === running
          #    Log.debug{ "Aborting zombie #{step.info_file}" }
          #    step.abort unless step.done?
          #    raise RbbtRESTHelpers::Retry
          #  end
          #  FileUtils.touch(step.info_file)
          #end

          wait_on step, false
        end
      end
    rescue RbbtRESTHelpers::Retry
      retry
    end
  end
end

