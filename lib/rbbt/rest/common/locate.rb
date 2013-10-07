module RbbtRESTHelpers
  attr_accessor :template_resources, :sass_resources, :javascript_resources, :plugin_resources

  class TemplateMissing < StandardError; end

  #{{{ TEMPLATE
  
  def self.template_resources
    @template_resources ||= [Rbbt.share.views.find(:lib)]
  end

  def template_resources
   [Rbbt.www.views.find(:lib)] + RbbtRESTHelpers.template_resources
  end
  
  def locate_template_from_resource(resource, template)
    resource[template + '.haml']
  end   

  def locate_template(template)
    template_resources.each do |resource|
      path = locate_template_from_resource(resource, template)
      return path if path.exists?
    end

    raise TemplateMissing, "Template #{ template } not found"
  end
 
  #{{{ SASS
  
  def self.add_sass_load_path(path)
    Sass::Engine::DEFAULT_OPTIONS[:load_paths].unshift path
  end
 
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

    raise TemplateMissing, "Sass template #{ template } not found"
  end

  #{{{ JAVASCRIPT

  def self.javascript_resources
    @javascript_resources ||= [Rbbt.share.views.public.find(:lib), Rbbt.share.views.public.js.find(:lib)]
  end

  def javascript_resources
    RbbtRESTHelpers.javascript_resources
  end


  def locate_javascript_from_resource(resource, script)
    path = resource[script + '.js']
    return path if path.exists?
    resource[script]
  end
 
  def locate_javascript(script)
    javascript_resources.each do |resource|
      path = locate_javascript_from_resource(resource, script)
      return path if path.exists?
    end

    raise TemplateMissing, "Script #{ script } not found"
  end
end
