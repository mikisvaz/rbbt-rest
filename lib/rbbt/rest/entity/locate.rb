module EntityRESTHelpers

  def self.entity_resources
    @entity_resources ||= []
  end

  def entity_resources
    [Rbbt.share.views.find(:lib)] +  EntityRESTHelpers.entity_resources
  end

  def resources_for_entity(entity)
    resources = entity_resources
    resources.unshift entity.dir.www.views if entity.respond_to? :dir and Path === entity.dir
    resources
  end
 
  #{{{ CHECKS
  
  def reject?(check_file, binding)
    return false if check_file.nil? or not check_file.exists?
    begin
      code = Open.read(check_file)
      accept = eval code, binding, check_file, 0
      action = File.basename(check_file).sub('.check', '')
      Log.debug{"Checking action template: #{action} - #{accept ? 'accepted' : 'rejected'}"}
      return ! accept
    rescue 
      Log.exception $!
      return true
    end
    false
  end

  def reject_template(path, binding)
    return false if path.nil?
    check_file = path.sub(/\.haml$/, '.check')

    if Path === path
      path.annotate check_file 
      return false unless check_file.exists?
    else
      return false unless File.exists?(check_file)
    end

    reject?(check_file, binding)
  end

  #{{{ ENTITY
  
  def locate_entity_template(entity)
    resources = resources_for_entity(entity)

    types = entity.annotation_types.collect{|e| e.to_s}
    types << "Default"

    path = nil
    types.each do |type|
      path ||= locate_server_file(["entity", type]*"/", resources, 'haml')
    end

    raise TemplateMissing, "Template not found for entity: #{ entity } (#{entity.annotation_types * ", "})" if path.nil?

    path
  end

  def locate_entity_action_template(entity, action)
    resources = resources_for_entity(entity)

    types = entity.annotation_types.collect{|e| e.to_s}
    types << "Default"

    path = nil
    types.each do |type|
      next if path
      path = locate_server_file(["entity", type, action]*"/", resources, 'haml')
      check_file = locate_server_file(["entity", type, action]*"/", resources, 'check')
      raise "This action was rejected: #{ action }" if reject?(check_file, binding)
    end

    raise TemplateMissing, "Template not found for entity action #{action}: #{ entity } (#{entity.annotation_types * ", "})" if path.nil?

    path
  end

  def find_all_entity_action_templates(entity, check = false)
    resources = resources_for_entity(entity)

    types = entity.annotation_types.collect{|e| e.to_s}
    types << "Default"

    paths = types.inject([]) do |acc,type|
      all_files  = glob_all_server_files(["entity", type, "*.haml"]*"/", resources)
      all_checks = glob_all_server_files(["entity", type, "*.check"]*"/", resources)
      rejected = []
      all_checks.each do |check_file|
        rejected << File.basename(check_file).sub('.check', '') if reject?(check_file, binding)
      end

      accepted = all_files.reject{|path|
        rejected.include? File.basename(path).sub('.haml', '')
      }

      acc += accepted
    end

    if check
      paths = paths.reject do |path|
        (path.basename == "edit.haml" or path.basename == 'new.haml') 
      end
    end

    actions = paths.collect{|file| file.basename.sub('.haml', '') }.uniq

    actions.select! do |action|
      begin
        locate_entity_action_template(entity, action)
      rescue Exception
        false
      end
    end if check
    
    actions
  end

  #{{{ ENTITY LIST
  
  def locate_entity_list_template(list)
    resources = resources_for_entity(list)

    types = list.annotation_types.collect{|e| e.to_s}
    types << "Default"

    path = nil
    types.each do |type|
      path ||= locate_server_file(["entity_list", type]*"/", resources, 'haml')
    end

    raise TemplateMissing, "Template not found for list (#{list.annotation_types * ", "})" if path.nil?

    path
  end

  def locate_entity_list_action_template(list, action)
    resources = resources_for_entity(list)

    types = list.annotation_types.collect{|e| e.to_s}
    types << "Default"

    path = nil
    types.each do |type|
      next if path
      path = locate_server_file(["entity_list", type, action]*"/", resources, 'haml')
      check_file = locate_server_file(["entity_list", type, action]*"/", resources, 'check')
      raise "This action was rejected: #{ action }" if reject?(check_file, binding)
    end

    raise TemplateMissing, "Template not found for entity list action #{action} (#{list.annotation_types * ", "})" if path.nil?

    path
  end

  def find_all_entity_list_action_templates(list, check = false)
    resources = resources_for_entity(list)

    types = list.annotation_types.collect{|e| e.to_s}
    types << "Default"

    paths = types.inject([]) do |acc,type|
      all_files  = glob_all_server_files(["entity_list", type, "*.haml"]*"/", resources)
      all_checks = glob_all_server_files(["entity_list", type, "*.check"]*"/", resources)
      rejected = []
      all_checks.each do |check_file|
        rejected << File.basename(check_file).sub('.check', '') if reject?(check_file, binding)
      end

      accepted = all_files.reject{|path|
        rejected.include? File.basename(path).sub('.haml', '')
      }

      acc += accepted
    end

    if check
      paths = paths.reject do |path|
        (path.basename == "edit.haml" or path.basename == 'new.haml') 
      end
    end

    actions = paths.collect{|file| file.basename.sub('.haml', '') }.uniq

    actions.select! do |action|
      begin
        locate_entity_list_action_template(list, action)
      rescue Exception
        false
      end
    end if check
    
    actions
  end


  #{{{ ENTITY MAP

  def locate_entity_map_template(type, column = nil)
    resources = entity_resources

    types = [type.to_s]
    types << "Default"

    path = nil
    types.each do |t|
      path ||= locate_server_file(["entity_map", t]*"/", resources, 'haml')
    end

    raise TemplateMissing, "Template not found for map (#{type}--#{column})" if path.nil?

    path
  end

  def locate_entity_map_action_template(map, action)
    resources = entity_resources

    field = map.key_field

    if map.entity_templates[field] 
      types = map.entity_templates[field].annotation_types
    else
      types = [Entity.formats[field]].compact
    end
    types += ["Default"]

    path = nil
    types.each do |type|
      next if path
      path = locate_server_file(["entity_map", type, action]*"/", resources, 'haml')
      check_file = locate_server_file(["entity_map", type, action]*"/", resources, 'check')
      raise "This action was rejected: #{ action }" if reject?(check_file, binding)
    end

    raise TemplateMissing, "Template not found for entity map action #{action} (#{field}--#{map.fields.first})" if path.nil?

    path
  end

  def find_all_entity_map_action_templates(map, check = false)
    resources = entity_resources

    field = map.key_field

    if map.entity_templates[field] 
      types = map.entity_templates[field].annotation_types
    else
      types = [Entity.formats[field]].compact
    end
    types += ["Default"]

    paths = types.inject([]) do |acc,type|
      all_files  = glob_all_server_files(["entity_map", type, "*.haml"]*"/", resources)
      all_checks = glob_all_server_files(["entity_map", type, "*.check"]*"/", resources)
      rejected = []
      all_checks.each do |check_file|
        rejected << File.basename(check_file).sub('.check', '') if reject?(check_file, binding)
      end

      accepted = all_files.reject{|path|
        rejected.include? File.basename(path).sub('.haml', '')
      }

      acc += accepted
    end

    if check
      paths = paths.reject do |path|
        (path.basename == "edit.haml" or path.basename == 'new.haml') 
      end
    end

    actions = paths.collect{|file| file.basename.sub('.haml', '') }.uniq

    actions.select! do |action|
      begin
        locate_entity_map_action_template(map, action)
      rescue Exception
        Log.exception $!
        false
      end
    end if check
    
    actions
  end
end
