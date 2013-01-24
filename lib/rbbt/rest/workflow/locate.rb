module WorkflowRESTHelpers
  def locate_workflow_template_from_resource(resource, template, workflow = nil, task = nil)
    template += '.haml' unless template =~ /.+\..+/

    paths = []
    paths << resource[workflow][task][template] if task and workflow
    paths << resource[workflow][template] if workflow
    paths << resource[template]

    paths.each do |path|
      return path.find if path.exists?
    end 

    raise "Template not found: [#{ template }, #{workflow}, #{ task }]"
  end   

  def locate_workflow_template(template, workflow = nil, task = nil)
    locate_workflow_template_from_resource(Rbbt.share.views.find(:lib), template, workflow, task)
  end
end
