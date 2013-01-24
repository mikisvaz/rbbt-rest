module EntityRESTHelpers

  #{{{ ENTITY

  def locate_entity_template_from_resource(resource, entity)
    paths = []
    entity.annotation_types.each do |annotation|
      paths << resource.entity[annotation.to_s + ".haml"]
    end

    paths.each do |path|
      return path.find if path.exists?
    end 

    raise "Template not found for #{ entity } (#{entity.annotation_types * ", "})"
  end   

  def locate_entity_template(entity)
    locate_entity_template_from_resource(Rbbt.share.views.find(:lib), entity)
  end

  #{{{ ENTITY ACTION

  def locate_entity_action_template_from_resource(resource, entity, action)
    paths = []
    entity.annotation_types.each do |annotation|
      paths << resource.entity[annotation][action.to_s + ".haml"]
    end

    paths.each do |path|
      return path.find if path.exists?
    end 

    raise "Template not found for action #{action}: #{ entity } (#{entity.annotation_types * ", "})"
  end   

  def locate_entity_action_template(entity, action)
    locate_entity_action_template_from_resource(Rbbt.share.views.find(:lib), entity, action)
  end

  #{{{ ENTITY LIST

  def locate_entity_list_template_from_resource(resource, list)
    paths = []
    list.annotation_types.each do |annotation|
      paths << resource.entity_list[annotation.to_s + ".haml"]
    end

    paths.each do |path|
      return path.find if path.exists?
    end 

    raise "Template not found for list (#{list.annotation_types * ", "})"
  end   

  def locate_entity_list_template(list)
    locate_entity_list_template_from_resource(Rbbt.share.views.find(:lib), list)
  end


  #{{{ ENTITY LIST ACTION
  
  def locate_entity_list_action_template_from_resource(resource, list, action)
    paths = []
    list.annotation_types.each do |annotation|
      paths << resource.entity_list[annotation][action.to_s + ".haml"]
    end

    paths.each do |path|
      return path.find if path.exists?
    end 

    raise "Template not found for list #{ action } (#{list.annotation_types * ", "})"
  end   

  def locate_entity_list_action_template(list, action)
    locate_entity_list_action_template_from_resource(Rbbt.share.views.find(:lib), list, action)
  end


end
