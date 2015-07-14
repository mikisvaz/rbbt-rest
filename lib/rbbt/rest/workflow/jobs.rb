require 'rbbt/workflow'
require 'rbbt/rest/common/misc'

module WorkflowRESTHelpers

  def consume_task_parameters(workflow, task, params = nil)
    task_inputs = workflow.task_info(task.to_sym)[:inputs]

    task_parameters = {}
    task_inputs.each do |input|

      input_val = consume_parameter(input, params)
      task_parameters[input] = input_val unless input_val.nil?

      # Param files
      input_val = consume_parameter(input.to_s + '__param_file', params)
      task_parameters[input.to_s + '__param_file'] = input_val unless input_val.nil?
    end

    task_parameters
  end

  def complete_input_set(workflow, task, inputs)
    inputs.keys.sort === workflow.task_info(task.to_sym)[:inputs].sort
  end

  def type_of_export(workflow, task)
    task = task.to_sym
    case
    when workflow.exec_exports.include?(task)
      :exec
    when workflow.synchronous_exports.include?(task)
      :synchronous
    when workflow.asynchronous_exports.include?(task)
      :asynchronous
    else
      raise "No known export type for #{ workflow } #{ task }. Accesses denied"
    end
  end

  def execution_type(workflow, task)
    export = type_of_export(workflow, task)
    return cache_type if cache_type
    return :sync if export == :exec and format == :html
    return export if export == :exec 
    return :sync
  end
  
  def prepare_job_inputs(workflow, task, params)
    inputs = workflow.task_info(task)[:inputs]
    input_types = workflow.task_info(task)[:input_types]

    task_inputs = {}
    inputs.each do |input|
      task_inputs[input] = prepare_input(params, input, input_types[input])
    end

    task_inputs
  end

  def show_result_html(result, workflow, task, jobname = nil, job = nil)
    result_type = workflow.task_info(task)[:result_type]
    result_description = workflow.task_info(task)[:result_description]
    workflow_render('job_result', workflow, task, :result => result, :type => result_type, :description => result_description, :jobname => jobname, :job => job)
  end

  def show_exec_result(result, workflow, task)
    case format.to_sym
    when :html
      show_result_html result, workflow, task, nil
    when :json
      content_type "application/json"
      halt 200, result.to_json
    when :tsv
      content_type "text/tab-separated-values"
      halt 200, result.to_s
    when :literal, :raw
      content_type "text/plain"
      case workflow.task_info(task)[:result_type]
      when :array
        halt 200, result * "\n"
      else
        halt 200, result.to_s
      end
    when :binary
      content_type "application/octet-stream"
      halt 200, result.to_s
    when :jobname
      halt 200, nil
    else
      raise "Unsupported format: #{ format }"
    end
  end

  def show_result(job, workflow, task)
    return show_result_html nil, workflow, task, job.name, job if @fragment

    case format.to_sym
    when :html
      show_result_html job.load, workflow, task, job.name, job
    when :table
      halt 200, tsv2html(job.path, :url => "/" << [workflow.to_s, task, job.name] * "/")
    when :entities
      tsv = tsv_process(load_tsv(job.path).first)
      list = tsv.column_values(tsv.fields.first).flatten
      if not AnnotatedArray === list and Annotated === list.first
        list.first.annotate list 
        list.extend AnnotatedArray
      end
      type = list.annotation_types.last
      list_id = "TMP #{type} in #{ [workflow.to_s, task, job.name] * " - " }"
      Entity::List.save_list(type.to_s, list_id, list, user)
      redirect to(Entity::REST.entity_list_url(list_id, type))
    when :map
      tsv = tsv_process(load_tsv(job.path).first)
      type = tsv.keys.annotation_types.last
      column = tsv.fields.first
      map_id = "MAP #{type}-#{column} in #{ [workflow.to_s, task, job.name] * " - " }"
      Entity::Map.save_map(type.to_s, column, map_id, tsv, user)
      redirect to(Entity::REST.entity_map_url(map_id, type, column))
    when :json
      content_type "application/json"
      halt 200, job.load.to_json
    when :tsv
      content_type "text/tab-separated-values"
      job.path ? send_file(job.path) : halt(200, job.load.to_s)
    when :literal, :raw
      content_type "text/plain"
      job.path ? send_file(job.path) : halt(200, job.load.to_s)
    when :binary
      content_type "application/octet-stream"
      job.path ? send_file(job.path) : halt(200, job.load.to_s)
    when :excel
      require 'rbbt/tsv/excel'
      data = nil
      excel_file = TmpFile.tmp_file
      result = job.load
      result.excel(excel_file, :name => @excel_use_name,:sort_by => @excel_sort_by, :sort_by_cast => @excel_sort_by_cast)
      send_file excel_file, :type => 'application/vnd.ms-excel', :filename => job.clean_name + '.xls'
    else
      raise "Unsupported format: #{ format }"
    end
  end

  def issue_job(workflow, task, jobname = nil, params = {})
    inputs = prepare_job_inputs(workflow, task, params)
    job = workflow.job(task, jobname, inputs)

    job.clean if update == :clean
    job.recursive_clean if update == :recursive_clean

    execution_type = execution_type(workflow, task)
    case execution_type.to_sym
    when :exec
      show_exec_result job.exec, workflow, task
    when :synchronous, :sync
      if update == :reload
        job.abort
        job.clean 
      end

      begin
        job_url = to(File.join("/", workflow.to_s, task, job.name)) 
        job_url += "?_format=#{@format}" if @format

        if not job.started?
          job.run true 
          job.join
        end

        #halt 200, job.name if format == :jobname 
        if format == :jobname
          job.name
        else
          redirect job_url
        end
      rescue Exception
        Log.exception $!
        halt 500, $!.message
      end
    when :asynchronous, :async, nil
      if update == :reload
        job.abort
        job.clean 
      end

      begin
        job.fork unless job.started?

        job_url = to(File.join("/", workflow.to_s, task, job.name)) 
        job_url += "?_format=#{@format}" if @format
        if format == :jobname
          while not File.exists? job.info_file
            sleep 1
          end
          content_type :text
          job.name
        else
          job.soft_grace
          redirect job_url
        end
      rescue Exception
        Log.exception $!
      end
    else
      raise "Unsupported execution_type: #{ execution_type }"
    end
  end

  def recursive_clean_job(workflow, job)
    job.recursive_clean

    if ajax
      halt 200
    else
      redirect to(File.join("/", workflow.to_s, job.task_name.to_s))
    end
  end
  def clean_job(workflow, job)
    job.clean

    if ajax
      halt 200
    else
      redirect to(File.join("/", workflow.to_s, job.task_name.to_s))
    end
  end
end
