module RbbtRESTHelpers
  
  def locate_template_from_resource(resource, template)
    path = resource[template + '.haml']
    raise "Template #{ template } not found" unless path.exists?

    path
  end   

  def locate_template(template)
    locate_template_from_resource(Rbbt.share.views.find(:lib), template)
  end
end
