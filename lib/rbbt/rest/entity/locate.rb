module EntityRESTHelpers

  def self.entity_resources
    @entity_resources ||= [Rbbt.share.views.find(:lib)]
  end

  def entity_resources
    [Rbbt.www.views.find(:lib)] +  EntityRESTHelpers.entity_resources
  end
 
  #{{{ ENTITY

  def locate_entity_template_from_resource(resource, entity)
    if entity == "Default" 
      path = resource.entity["Default.haml"]
      if path.exists?
        return path
      else
        return nil
      end
    end

    entity.annotation_types.each do |annotation|
      path = resource.entity[annotation.to_s + ".haml"]
      return path if path.exists?
    end

    nil
  end   

  def locate_entity_template(entity)

    if entity.respond_to? :dir and Path === entity.dir
      entity_views = entity.dir.www.views

      entity.annotation_types.each do |annotation|
        path = entity_views.entity[annotation.to_s + ".haml"]
        return path if path.exists?
      end
    end

    entity_resources.each do |resource|
      path = locate_entity_template_from_resource(resource, entity)
      return path if path and path.exists?
    end

    entity_resources.each do |resource|
      path = locate_entity_template_from_resource(resource, "Default")
      return path if path and path.exists?
    end

    raise "Template not found for entity: #{ entity } (#{entity.annotation_types * ", "})"
  end

  #{{{ ENTITY ACTION

  def find_all_entity_action_templates_from_resource(resource, entity)
    if entity == "Default" 
      resource.entity["Default"].glob("*.haml")
    else
      entity.annotation_types.collect do |annotation|
        resource.entity[annotation].glob('*.haml')
      end.compact.flatten
    end
  end   

  def find_all_entity_action_templates(entity, check = false)
    paths = []

    if entity.respond_to? :dir and Path === entity.dir
      paths.concat find_all_entity_action_templates_from_resource(entity.dir.www.views, entity)
    end

    entity_resources.each do |resource|
      paths.concat find_all_entity_action_templates_from_resource(resource, entity)
    end

    entity_resources.each do |resource|
      paths.concat find_all_entity_action_templates_from_resource(resource, "Default")
    end

    if check
      paths = paths.reject do |path|
        check_file = path.sub(/\.haml$/, '.check')
        case
        when path.basename == "edit.haml"
          true
        when File.exists?(check_file)
          begin
            Log.debug("Checking action template: #{path}")
            code = File.read(check_file)
            accept = eval code
            not accept
          rescue
            Log.debug("Error Checking action template #{path}: #{$!.message}")
            true
          end
        else
          false
        end
      end
    end

    paths.collect{|file| file.basename.sub('.haml', '') }.uniq
  end

  def locate_entity_action_template_from_resource(resource, entity, action)
    if entity == "Default" 
      path = resource.entity["Default"][action.to_s + ".haml"]
      if path.exists?
        return path
      else
        return nil
      end
    end

    entity.annotation_types.each do |annotation|
      path = resource.entity[annotation][action.to_s + ".haml"]
      return path if path.exists?
    end

    nil
  end   

  def locate_entity_action_template(entity, action)

    if entity.respond_to? :dir and Path === entity.dir
      path = locate_entity_action_template_from_resource(entity.dir.www.views, entity, action)
      return path if path and path.exists?
    end

    entity_resources.each do |resource|
      path = locate_entity_action_template_from_resource(resource, entity, action)
      return path if path and path.exists?
    end

    entity_resources.each do |resource|
      path = locate_entity_action_template_from_resource(resource, "Default", action)
      return path if path and path.exists?
    end

    raise "Template not found for action #{action}: #{ entity } (#{entity.annotation_types * ", "})"
  end

  #{{{ ENTITY LIST

  def locate_entity_list_template_from_resource(resource, list)
    if list == "Default" 
      path = resource.entity_list["Default.haml"]
      if path.exists?
        return path
      else
        return nil
      end
    end

    list.annotation_types.each do |annotation|
      path = resource.entity_list[annotation.to_s + ".haml"]
      return path if path.exists?
    end

    nil
  end   

  def locate_entity_list_template(list)

    if list.respond_to? :dir and Path === list.dir
      list_views = list.dir.www.views

      list.annotation_types.each do |annotation|
        path = list_views.entity_list[annotation.to_s + ".haml"]
        return path if path.exists?
      end
    end

    entity_resources.each do |resource|
      path = locate_entity_list_template_from_resource(resource, list)
      return path if path and path.exists?
    end

    entity_resources.each do |resource|
      path = locate_entity_list_template_from_resource(resource, "Default")
      return path if path and path.exists?
    end

    raise "Template not found for list (#{list.annotation_types * ", "})"
  end


  #{{{ ENTITY LIST ACTION
 
  def find_all_entity_list_action_templates_from_resource(resource, entity)

    if entity == "Default" 
      resource.entity_list["Default"].glob("*.haml")
    else
      entity.annotation_types.collect do |annotation|
        resource.entity_list[annotation].glob('*.haml')
      end.compact.flatten
    end
  end   

  def find_all_entity_list_action_templates(list, check = false)
    paths = []

    if list.respond_to? :dir and Path === list.dir
      paths.concat find_all_entity_list_action_templates_from_resource(list.dir.www.views, list)
    end

    entity_resources.each do |resource|
      paths.concat find_all_entity_list_action_templates_from_resource(resource, list)
    end

    entity_resources.each do |resource|
      paths.concat find_all_entity_list_action_templates_from_resource(resource, "Default")
    end

    if check
      paths = paths.reject do |path|
        check_file = path.sub(/\.haml$/, '.check')
        case
        when path.basename == "edit.haml"
          true
        when File.exists?(check_file)
          begin
            Log.debug("Checking action template: #{path}")
            code = File.read(check_file)
            accept = eval code
            not accept
          rescue
            Log.debug("Error Checking action template #{path}: #{$!.message}")
            true
          end
        else
          false
        end
      end
    end

    paths.collect{|file| file.basename.sub('.haml', '') }.uniq
  end

 
  def locate_entity_list_action_template_from_resource(resource, list, action)
    if list == "Default" 
      path = resource.entity_list["Default"][action.to_s + ".haml"]
      if path.exists?
        return path
      else
        return nil
      end
    end

    list.annotation_types.each do |annotation|
      path = resource.entity_list[annotation][action.to_s + ".haml"]
      return path if path.exists?
    end

    nil
  end   

  def locate_entity_list_action_template(list, action)

    if list.respond_to? :dir and Path === list.dir
      path = locate_entity_list_action_template_from_resource(list.dir.www.views, list, action)
      return path if path and path.exists?
    end

    entity_resources.each do |resource|
      path = locate_entity_list_action_template_from_resource(resource, list, action)
      return path if path and path.exists?
    end

    entity_resources.each do |resource|
      path = locate_entity_list_action_template_from_resource(resource, "Default", action)
      return path if path and path.exists?
    end

    raise "Template not found for list #{ action } (#{list.annotation_types * ", "})"
  end
end
