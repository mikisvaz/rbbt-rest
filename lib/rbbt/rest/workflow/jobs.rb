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
      raise "No known export type for #{ workflow } #{ task }"
    end
  end

  def execution_type(workflow, task)
    export = type_of_export(workflow, task)
    return export if export == :exec or cache_type.nil?
    return cache_type if cache_type
  end
  
  def fix_input(type, value, param_file = nil)
    case type

    when nil, :string, :select
      value

    when :integer
      value.to_i

    when :float
      value.to_f

    when :boolean
      param2boolean(value)

    when :text
      if param_file and (value.nil? or (String === value and value.empty?))
        param_file[:tempfile].read
      else
        value.gsub(/\r\n/, "\n")
      end

    when :array
      text = if param_file and (value.nil? or (String === value and value.empty?))
               param_file[:tempfile].read
             else
               value
             end

      if Array === text
        text
      else
        text.split(/\r?\n/).collect{|l| l.strip}
      end

    when :tsv
      if param_file and (value.nil? or (String === value and value.empty?))
        TSV.open(param_file[:tempfile].open)
      else
        TSV.open(StringIO.new(value))
      end
    end
  end

  def prepare_job_inputs(workflow, task, params)
    inputs = workflow.task_info(task)[:inputs]
    input_types = workflow.task_info(task)[:input_types]

    task_inputs = {}
    inputs.each do |input|
      value = consume_parameter(input, params)
      param_file = consume_parameter(input.to_s + '__param_file', params)
      next if value.nil? and param_file.nil?
      type = input_types[input]

      fixed_value = fix_input(type, value, param_file)
      task_inputs[input] = fixed_value
    end

    task_inputs
  end

  def show_result_html(result, workflow, task, jobname = nil, job = nil)
    result_type = workflow.task_info(task)[:result_type]
    result_description = workflow.task_info(task)[:result_description]
    workflow_render('job_result', workflow, task, :result => result, :type => result_type, :description => result_description, :jobname => jobname, :job => job)
  end

  def show_exec_result(result, workflow, task)
    case format
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
      halt 200, result.to_s
    when :binary
      content_type "application/octet-stream"
      halt 200, result.to_s
    else
      raise "Unsupported format: #{ format }"
    end
  end

  def show_result(job, workflow, task)
    case format
    when :html
      show_result_html job.load, workflow, task, job.name, job
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

    execution_type = execution_type(workflow, task)
    case execution_type
    when :exec
      show_exec_result job.exec, workflow, task
    when :synchronous, :sync
      job.clean if update == :reload
      job.run
      job_url = to(File.join("/", workflow.to_s, task, job.name)) 
      halt 200, job.name if format === :jobname
      redirect job_url
    when :asynchronous, :async, nil
      job.clean if update == :reload
      job.fork
      job_url = to(File.join("/", workflow.to_s, task, job.name)) 
      halt 200, job.name if format === :jobname
      redirect job_url
    else
      raise "Unsupported execution_type: #{ execution_type }"
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
