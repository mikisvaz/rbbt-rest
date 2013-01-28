module RbbtRESTHelpers
  attr_accessor :template_resources, :sass_resources, :javascript_resources, :plugin_resources

  #{{{ TEMPLATE
  
  def self.template_resources
    @template_resources ||= [Rbbt.share.views.find(:lib)]
  end

  def template_resources
    RbbtRESTHelpers.template_resources
  end
  
  def locate_template_from_resource(resource, template)
    resource[template + '.haml']
  end   

  def locate_template(template)
    template_resources.each do |resource|
      path = locate_template_from_resource(resource, template)
      return path if path.exists?
    end

    raise "Template #{ template } not found"
  end
 
  #{{{ SASS
  
  def self.sass_resources
    @sass_resources ||= [Rbbt.share.views.compass.find(:lib)]
  end

  def sass_resources
    RbbtRESTHelpers.sass_resources
  end

  def locate_sass_from_resource(resource, template)
    resource[template + '.sass']
  end
 
  def locate_sass(template)
    sass_resources.each do |resource|
      path = locate_sass_from_resource(resource, template)
      return path if path.exists?
    end

    raise "Sass template #{ template } not found"
  end

  #{{{ JAVASCRIPT

  def self.javascript_resources
    @javascript_resources ||= [Rbbt.share.views.js.find(:lib), Rbbt.share.views.public.find(:lib)]
  end

  def javascript_resources
    RbbtRESTHelpers.javascript_resources
  end


  def locate_javascript_from_resource(resource, script)
    resource[script + '.js']
  end
 
  def locate_javascript(script)
    javascript_resources.each do |resource|
      path = locate_javascript_from_resource(resource, script)
      return path if path.exists?
    end

    raise "Script #{ script } not found"
  end
end
