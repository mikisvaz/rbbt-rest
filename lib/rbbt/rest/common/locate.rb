
class TemplateMissing < StandardError; end

module RbbtRESTHelpers
  attr_accessor :template_resources, :sass_resources, :javascript_resources, :plugin_resources


  #{{{ Common

  def add_search_paths(path, resources)
    resources.reverse.each do |resource|
      name = Misc.snake_case(resource.to_s.gsub('/','_'))
      path.prepend_search_path(name, resource)
    end
  end

  def locate_server_file(template, resources, extension = nil)
    path = Path.setup(template)
    add_search_paths(path, resources)
    return path.find if path.exists? and not path.directory?
    path = path.set_extension(extension) if extension
    return path.find if path.exists?
  end

  def glob_all_server_files(file, resources)
    path = Path.setup(file)
    add_search_paths(path, resources)
    path.glob_all
  end

  def find_all_server_files(file, resource)
    path = Path.setup(file)
    add_search_paths(path, resources)
    path.find_all
  end

  #{{{ TEMPLATE
  
  def self.template_resources
    @template_resources ||= [Rbbt.share.views.find(:lib)]
  end

  def template_resources
   [Rbbt.www.views] + RbbtRESTHelpers.template_resources
  end

  def locate_template(template)
    path = locate_server_file(template, template_resources, 'haml')
    raise TemplateMissing, "Template #{ template } not found" if path.nil?
    path
  end

  # {{{ FILE

  def self.file_resources
    @file_resources ||= template_resources
  end

  def file_resources
   [Rbbt.www.views] + RbbtRESTHelpers.file_resources
  end

  def locate_file(file)
    path = locate_server_file(file, file_resources)
    raise TemplateMissing, "File #{ file } not found" if path.nil?
    path
  end

  def find_all(file)
    find_all_server_files(file, file_resources)
  end

  def glob_all(file)
    glob_all_server_files(file, file_resources)
  end

  #{{{ SASS
  
  def self.add_sass_load_path(path)
    sass_resources.unshift path
    sass_resources.uniq!
  end
 
  def self.sass_resources
    @sass_resources ||= [Rbbt.share.views.compass.find(:lib)]
  end

  def sass_resources
    [Rbbt.www.views.compass] + RbbtRESTHelpers.sass_resources
  end

  def locate_sass(template)
    path = locate_server_file(template, sass_resources, 'sass')
    raise TemplateMissing, "Sass file #{ template } not found" if path.nil?
    path
  end

  #{{{ JAVASCRIPT

  def self.javascript_resources
    @@javascript_resources ||= [Rbbt.share.views.public.find(:lib), Rbbt.share.views.public.js.find(:lib), Rbbt.share.views.public.plugins.find(:lib)]
  end

  def javascript_resources
    RbbtRESTHelpers.javascript_resources
  end

  def locate_javascript(template)
    path = locate_server_file(template, javascript_resources, 'js')
    raise TemplateMissing, "Javascript file #{ template } not found" if path.nil?
    path
  end

  #{{{ CSS

  def self.css_resources
    @css_resources ||= [Rbbt.share.views.public.find(:lib), Rbbt.share.views.public.css.find(:lib), Rbbt.share.views.public.plugins.find(:lib)]
  end

  def css_resources
    RbbtRESTHelpers.css_resources
  end

  def locate_css(template)
    path = locate_server_file(template, css_resources, 'css')
    raise TemplateMissing, "CSS file #{ template } not found" if path.nil?
    path
  end



  #def locate_template_from_resource(resource, template)
  #  resource[template + '.haml']
  #end   

  #def locate_template(template)
  #  return Path.setup(template) if Open.exists?(template)
  #  return Path.setup(template+'.haml') if Open.exists?(template+'.haml')
  #  template_resources.each do |resource|
  #    path = locate_template_from_resource(resource, template)
  #    return path if path.exists?
  #  end

  #  raise TemplateMissing, "Template #{ template } not found"
  #end

  #{{{ FILE
  
  #def locate_file_from_resource(resource, file)
  #  resource[file]
  #end   

  #def locate_file(file)
  #  file_resources.each do |resource|
  #    path = locate_file_from_resource(resource, file)
  #    return path if path.exists?
  #  end

  #  raise TemplateMissing, "File #{ file } not found"
  #end

  #def find_all_from_resource(resource, pattern)
  #  resource.glob(pattern)
  #end   
  #
  #def find_all(pattern)
  #  paths = []
  #  file_resources.each do |resource|
  #    paths.concat find_all_from_resource(resource, pattern)
  #  end

  #  paths
  #end

  #def locate_sass_from_resource(resource, template)
  #  resource[template + '.sass']
  #end
 
  #def locate_sass(template)
  #  sass_resources.each do |resource|
  #    path = locate_sass_from_resource(resource, template)
  #    return path if path.exists?
  #  end

  #  raise TemplateMissing, "Sass template #{ template } not found"
  #end

  #def locate_javascript_from_resource(resource, script)
  #  path = resource[script + '.js']
  #  return path if path.exists?
  #  resource[script]
  #end
 
  #def locate_javascript(script)
  #  javascript_resources.each do |resource|
  #    path = locate_javascript_from_resource(resource, script)
  #    return path if path.exists?
  #  end

  #  raise TemplateMissing, "Script #{ script } not found"
  #end

  #def locate_css_from_resource(resource, script)
  #  path = resource[script + '.css']
  #  return path if path.exists?
  #  resource[script]
  #end
 
  #def locate_css(script)
  #  css_resources.each do |resource|
  #    path = locate_css_from_resource(resource, script)
  #    return path if path.exists?
  #  end

  #  raise TemplateMissing, "Script #{ script } not found"
  #end
end
