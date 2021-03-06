require 'rbbt/util/open'

require 'haml'
module WorkflowRESTHelpers

  def workflow_render(template, workflow = nil, task = nil, params = {})
    workflow = consume_parameter(:workflow, params) if workflow.nil?
    task     = consume_parameter(:task, params) if workflow.nil?
    job      = consume_parameter(:job, params) if job.nil?

    template_file = locate_workflow_template(template, workflow, task)

    locals = params.dup
    locals[:workflow] = workflow if workflow
    locals[:task]     = task if task

    if layout
      layout_file = workflow.libdir.www.views[workflow.to_s]["layout.haml"] if workflow.libdir
      layout_file = locate_template("layout") unless layout_file and layout_file.exists?
    else
      layout_file = nil
    end

    if job 
      locals[:job] = job 
      @step = job
      @title = [[workflow.to_s,task] * "#", job.clean_name] * " "
      cache_type = execution_type(workflow, task)
      server_key = $app_name
      html_dir = job.file('.html')
      other_params = params.dup
      other_params.delete_if{|k,v| k[0] == "_"}
      other_params.delete :result
      other_params[:template_file] = template_file
      cache_file = html_dir[server_key + "_" << Misc.obj2digest(other_params)]
      cache_type = false if params[:cache] == FalseClass
      render(template_file, locals, layout_file, [task,workflow,job.name] * "-", :cache_type => cache_type, :cache_file => cache_file)
    else
      cache_type = :async
      cache_type = false if params[:cache] == FalseClass
      render(template_file, locals, layout_file, [workflow.to_s, task, template_file.to_s].compact * "-", :cache_type => :async )
    end
  end

  def workflow_partial(template, workflow = nil, task = nil, params = {})
    workflow = consume_parameter(:workflow, params) if workflow.nil?
    task     = consume_parameter(:task, params) if workflow.nil?

    template_file = locate_workflow_template(template, workflow, task)

    locals = params.dup
    locals[:workflow] = workflow if workflow
    locals[:task]     = task if task

    render_partial(template_file, locals)
  end
end
