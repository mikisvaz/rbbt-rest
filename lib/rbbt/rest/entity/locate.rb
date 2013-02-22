module EntityRESTHelpers

  def self.entity_resources
    @entity_resources ||= [Rbbt.share.views.find(:lib)]
  end

  def entity_resources
    EntityRESTHelpers.entity_resources
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

    if entity.respond_to? :dir and entity.dir === Path
      path = locate_entity_template_from_resource(entity.dir.www.views, entity)
      return path if path and path.exists?
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
      resource.entity["Default"].glob("*.haml").collect{|file| File.basename(file).sub('.haml') }
    else
      entity.annotation_types.collect do |annotation|
        resource.entity[annotation].glob('*.haml')
      end.compact.flatten.collect{|file| File.basename(file).sub('.haml', '') }
    end
  end   

  def find_all_entity_action_templates(entity)
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

    paths.uniq
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
