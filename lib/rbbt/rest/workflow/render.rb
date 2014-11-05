require 'rbbt/util/open'

require 'haml'
module WorkflowRESTHelpers

  def workflow_render(template, workflow = nil, task = nil, params = {})
    workflow = consume_parameter(:workflow, params) if workflow.nil?
    task     = consume_parameter(:task, params) if workflow.nil?

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

    render(template_file, locals, layout_file)
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
