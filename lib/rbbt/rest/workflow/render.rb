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
      layout_file = locate_template("layout")
      Haml::Engine.new(Open.read(layout_file), :filename => layout_file).render(self, locals) do
        Haml::Engine.new(Open.read(template_file), :filename => template_file).render(self, locals)
      end
    else
      Haml::Engine.new(Open.read(template_file), :filename => template_file).render(self, locals)
    end
  end

  def workflow_partial(template, workflow = nil, task = nil, params = {})
    workflow = consume_parameter(:workflow, params) if workflow.nil?
    task     = consume_parameter(:task, params) if workflow.nil?

    template_file = locate_workflow_template(template, workflow, task)

    locals = params.dup
    locals[:workflow] = workflow if workflow
    locals[:task]     = task if task

    Haml::Engine.new(Open.read(template_file), :filename => template_file).render(self, locals)
  end
end
