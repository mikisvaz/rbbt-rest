require 'rbbt'
require 'rbbt/workflow'

require 'rbbt/rest/common/locate'
require 'rbbt/rest/common/misc'
require 'rbbt/rest/common/render'
require 'rbbt/rest/common/forms'
require 'rbbt/rest/common/users'

require 'rbbt/rest/workflow/locate'
require 'rbbt/rest/workflow/render'
require 'rbbt/rest/workflow/jobs'


require 'sinatra/base'
require 'json'

module Sinatra
  module RbbtRESTWorkflow
    WORKFLOWS = []


    def add_workflow_resource(workflow)
      views_dir = workflow.respond_to?(:libdir)? workflow.libdir.www.views.find(:lib) : nil
      if views_dir and views_dir.exists?
        Log.debug "Registering views for #{ workflow }: #{ views_dir.find }"
        RbbtRESTMain.add_resource_path(views_dir)
      end
    end

    def add_workflow(workflow, add_resource = false)
      raise "Provided workflow is not of type Workflow" unless  Workflow === workflow 
      RbbtRESTWorkflow::WORKFLOWS.push workflow unless RbbtRESTWorkflow::WORKFLOWS.include? workflow

      Log.debug "Adding #{ workflow } to REST server" 

      add_workflow_resource(workflow) if add_resource
      workflow.documentation


      self.instance_eval workflow.libdir.lib['sinatra.rb'].read, workflow.libdir.lib['sinatra.rb'].find if workflow.respond_to?(:libdir) and  File.exists? workflow.libdir.lib['sinatra.rb']

      get "/#{workflow.to_s}" do
        case format
        when :html
          workflow_render('tasks', workflow)
        when :json
          content_type "application/json"
          {:exec => workflow.exec_exports, :synchronous => workflow.synchronous_exports, :asynchronous => workflow.asynchronous_exports}.to_json
        else
          raise "Unsupported format specified: #{ format }"
        end
      end

      get "/#{workflow.to_s}/documentation" do
        case format
        when :html
          workflow_render('tasks', workflow)
        when :json
          content_type "application/json"
          workflow.documentation.to_json
        else
          raise "Unsupported format specified: #{ format }"
        end
      end
      get "/#{workflow.to_s}/:task/info" do
        task     = consume_parameter(:task)

        raise Workflow::TaskNotFoundException.new workflow, task unless workflow.tasks.include? task.to_sym

        case format
        when :html
          workflow_render('task_info', workflow)
        when :json
          content_type "application/json"
          workflow.task_info(task.to_sym).to_json
        else
          raise "Unsupported format specified: #{ format }"
        end
      end

      get "/#{workflow.to_s}/:task/dependencies" do
        task     = consume_parameter(:task)

        raise Workflow::TaskNotFoundException.new workflow, task unless workflow.tasks.include? task.to_sym

        case format
        when :html
          workflow_render('task_dependencies', workflow)
        when :json
          content_type "application/json"
          workflow.task_dependencies[task.to_sym].to_json
        else
          raise "Unsupported format specified: #{ format }"
        end
      end

      get "/#{workflow.to_s}/description" do
        halt 200, workflow.documentation[:description] || ""
      end


      get "/#{workflow.to_s}/:task" do
        task     = consume_parameter(:task)
        jobname  = consume_parameter(:jobname)

        raise Workflow::TaskNotFoundException.new workflow, task unless workflow.tasks.include? task.to_sym

        task_parameters = consume_task_parameters(workflow, task, params)

        if complete_input_set(workflow, task, task_parameters) or format != :html 
          issue_job(workflow, task, jobname, task_parameters)
        else
          workflow_render('form', workflow, task, task_parameters)
        end
      end

      post "/#{workflow.to_s}/:task" do
        task = consume_parameter(:task)
        jobname  = consume_parameter(:jobname)

        raise Workflow::TaskNotFoundException.new workflow, task unless workflow.tasks.include? task.to_sym

        task_parameters = consume_task_parameters(workflow, task, params)

        issue_job(workflow, task, jobname, task_parameters)
      end

      get "/#{workflow.to_s}/:task/:job" do
        task = consume_parameter(:task)
        job  = consume_parameter(:job)

        raise Workflow::TaskNotFoundException.new workflow, task unless workflow.tasks.include? task.to_sym

        job = workflow.load_id(File.join(task, job))

        clean_job(workflow, job) if update == :clean
        recursive_clean_job(workflow, job) if update == :recursive_clean

        begin
          started = job.started?
          done = job.done?
          error = job.error? || job.aborted?

          if done
            show_result job, workflow, task
          else
            if started
              case
              when error
                error_for job
              when execution_type(workflow, task) == :asynchronous
                wait_on job
              else
                job.join
                raise RbbtRESTHelpers::Retry
              end
            else
              halt 404, "Job not found"
            end
          end
        rescue RbbtRESTHelpers::Retry
          retry
        end
      end

      get "/#{workflow.to_s}/:task/:job/info" do
        task = consume_parameter(:task)
        job  = consume_parameter(:job)

        raise Workflow::TaskNotFoundException.new workflow, task unless workflow.tasks.include? task.to_sym

        job = workflow.load_id(File.join(task, job))

        case format
        when :html
          workflow_render('job_info', workflow, task, :info => job.info)
        when :json
          content_type "application/json"
          job.info.to_json
        else
          raise "Unsupported format specified: #{ format }"
        end
      end

      get "/#{workflow.to_s}/:task/:job/files" do
        task = consume_parameter(:task)
        job  = consume_parameter(:job)

        raise Workflow::TaskNotFoundException.new workflow, task unless workflow.tasks.include? task.to_sym

        job = workflow.load_id(File.join(task, job))

        case format
        when :html
          workflow_render('job_files', workflow, task, :info => job.info)
        when :json
          content_type "application/json"
          job.files.to_json
        else
          raise "Unsupported format specified: #{ format }"
        end
      end

      get "/#{workflow.to_s}/:task/:job/file/*" do
        task = consume_parameter(:task)
        job  = consume_parameter(:job)
        filename = params[:splat].first

        raise Workflow::TaskNotFoundException.new workflow, task unless workflow.tasks.include? task.to_sym

        job = workflow.load_id(File.join(task, job))

        require 'mimemagic'
        path = job.file(filename)
        mime = nil
        Open.open(path) do |io|
          begin
            mime = MimeMagic.by_path(io) 
            if mime.nil?
              io.rewind
              mime = MimeMagic.by_magic(io) 
            end
            if mime.nil?
              io.rewind
              mime = "text/tab-separated-values" if io.gets =~ /^#/ and io.gets.include? "\t"
            end
          rescue Exception
            Log.exception $!
          end
        end
        content_type mime if mime
        send_file path
      end

      delete "/#{workflow.to_s}/:task/:job" do
        task = consume_parameter(:task)
        job  = consume_parameter(:job)
        job  = workflow.load_id(File.join(task, job))

        raise Workflow::TaskNotFoundException.new workflow, task unless workflow.tasks.include? task.to_sym

        clean_job(workflow, job)
      end
    end

    def self.registered(base)
      base.module_eval do
        helpers WorkflowRESTHelpers
      end
    end
  end
end

