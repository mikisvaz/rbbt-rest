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
      cache_type = execution_type(workflow, task)
      server_key = $app_name
      html_dir = job.file('html')
      FileUtils.mkdir_p html_dir.find unless File.exists? html_dir.find
      cache_file = html_dir[server_key]
      render(template_file, locals, layout_file, [task,workflow,job.name] * "-", :cache_type => cache_type, :cache_file => cache_file)
    else
      render(template_file, locals, layout_file, [workflow, task, template_file].compact * "-", :cache_type => :async )
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
