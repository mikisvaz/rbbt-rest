require 'rbbt'
require 'rbbt/workflow'

require 'rbbt/rest/common/locate'
require 'rbbt/rest/common/misc'
require 'rbbt/rest/common/render'

require 'rbbt/rest/workflow/locate'
require 'rbbt/rest/workflow/render'
require 'rbbt/rest/workflow/forms'
require 'rbbt/rest/workflow/jobs'

require 'sinatra/base'
require 'json'

class WorkflowREST < Sinatra::Base
  helpers WorkflowRESTHelpers
  helpers RbbtRESTHelpers
 
  set :cache_dir, Rbbt.var.cache.sinatra.find unless settings.respond_to? :cache_dir and settings.cache_dir != nil

  attr_accessor :ajax, :layout, :format, :size, :update, :cache_type, :_

  before do
    process_common_parameters
    @cache_type ||= :async
  end

  WORKFLOWS = []


  def self.add_workflow(workflow)
    raise "Provided workflow is not of type Workflow" unless  Workflow === workflow or WorkflowRESTClient === workflow

    Log.debug("Adding #{ workflow } to REST server")

    WORKFLOWS << workflow

    get "/#{workflow.to_s}" do
      case format
      when :html
        workflow_render('tasks', workflow)
      when :json
        {:exec => workflow.exec_exports, :synchronous => workflow.synchronous_exports, :asynchronous => workflow.asynchronous_exports}.to_json
      else
        raise "Unsupported format specified: #{ format }"
      end
    end

    get "/#{workflow.to_s}/:task/info" do
      task     = consume_parameter(:task)
      jobname  = consume_parameter(:jobname)

      case format
      when :html
        workflow_render('task_info', workflow)
      when :json
        workflow.task_info(task).to_json
      else
        raise "Unsupported format specified: #{ format }"
      end
 
    end

    get "/#{workflow.to_s}/:task" do
      task     = consume_parameter(:task)
      jobname  = consume_parameter(:jobname)

      task_parameters = consume_task_parameters(workflow, task, params)

      if complete_input_set(workflow, task, task_parameters)
        issue_job(workflow, task, jobname, task_parameters)
      else
        workflow_render('form', workflow, task, task_parameters)
      end
    end

    post "/#{workflow.to_s}/:task" do
      task = consume_parameter(:task)
      jobname  = consume_parameter(:jobname)

      task_parameters = consume_task_parameters(workflow, task, params)

      issue_job(workflow, task, jobname, task_parameters)
    end

    get "/#{workflow.to_s}/:task/:job" do
      task = consume_parameter(:task)
      job  = consume_parameter(:job)

      job = workflow.load_id(File.join(task, job))

      clean_job(workflow, job) if update == :clean

      begin
        done = job.done?
        started = job.info.any?

        if done
          show_result job, workflow, task
        else
          if started
            if cache_type == :asynchronous
              wait_on job
            else
              job.join
              raise Retry
            end
          else
            halt 404, "Job not found"
          end
        end
      rescue Retry
        retry
      end
    end

    get "/#{workflow.to_s}/:task/:job/info" do
      task = consume_parameter(:task)
      job  = consume_parameter(:job)

      job = workflow.load_id(File.join(task, job))

      case format
      when :html
        workflow_render('job_info', workflow, task, :info => job.info)
      when :json
        job.info.to_json
      else
        raise "Unsupported format specified: #{ format }"
      end
    end

    get "/#{workflow.to_s}/:task/:job/files" do
      task = consume_parameter(:task)
      job  = consume_parameter(:job)

      job = workflow.load_id(File.join(task, job))

      case format
      when :html
        workflow_render('job_files', workflow, task, :info => job.info)
      when :json
        job.files.to_json
      else
        raise "Unsupported format specified: #{ format }"
      end
    end

    get "/#{workflow.to_s}/:task/:job/file/*" do
      task = consume_parameter(:task)
      job  = consume_parameter(:job)
      filename = params[:splat].first

      job = workflow.load_id(File.join(task, job))

      send_file job.file(filename)
    end

    delete "/#{workflow.to_s}/:task/:job" do
      task = consume_parameter(:task)
      job  = consume_parameter(:job)
      job  = workflow.load_id(File.join(task, job))

      clean_job(workflow, job) if update == :clean
    end
  end
end

