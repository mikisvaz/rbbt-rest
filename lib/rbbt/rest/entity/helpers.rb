require 'rbbt/util/misc/annotated_module'

module EntityRESTHelpers

  def list_hash(list)
    return {:entities => list} unless list.respond_to? :base_entity
    info = list.info
    info.delete :annotation_types
    info.delete :annotated_array
    {:entities => list, :info => list.info, :entity_type => list.base_entity}
  end

  def list_json(list)
    list_hash(list).to_json
  end

  def list(list, list_id = nil, text = nil)
    partial_render('entity_partials/entity_list', :list => list, :list_id => list_id, :text => text)
  end

  def action_parameters_id
    case
    when (params[:entity] and params[:action])
      ["action_params", params[:entity], params[:action]] * "__"
    else
      ["action_params", (rand * 1000).to_i] * "__"
    end
  end

  def action_parameters(values = nil, action_options = {}, form_options = {}, &block)
    o = Object.new
    o.extend InputModule

    if values.nil?
      values = @clean_params
    else
      values = @clean_params.merge(values)
    end

    o.instance_eval &block

    #description = o.description

    inputs = o.inputs || []
    input_types = o.input_types
    input_defaults = o.input_defaults
    input_options = o.input_options
    input_descriptions = o.input_descriptions

    hidden_inputs = []
    inputs.each do |input|
      values[input] = values.delete input.to_s unless values.include? input
      input_value = values[input]
      input_default = input_defaults[input]
      input_option = input_options[input]
      input_option ||= {}
      if form_options[:method] != 'POST' && ! input_option.include?(:no_file)
        input_option[:no_file] = true 
        input_options[input] = input_option
      end
    end

    locals = {}
    info = {:inputs => inputs, :input_descriptions => input_descriptions, :input_defaults => input_defaults, :input_options => input_options, :input_types => input_types, :values => values}
    locals[:id] = action_parameters_id
    locals[:action] = @fullpath
    locals[:klass] = 'action_parameter_form'
    locals[:info] = info
    #locals[:description] = description
    locals[:method] = 'GET'
    locals = locals.merge(form_options)

    html_tag :div, partial_render('partials/form', locals), {:class => 'action_parameters ui raised segment'}.merge(action_options)
  end

  def page_type(path = nil)
    path = request.path_info if path.nil?

    case
    when path.match(/^\/entity\//)
      return "entity"; 
    when path.match(/^\/entity_action\//)
      return "entity_action"; 
    when path.match(/^\/entity_list\//)
      return "entity_list"; 
    when path.match(/^\/entity_list_action\//)
      return "entity_list_action"; 
    when path.match(/^\/entity_map\//)
      return "entity_map"; 
    when path.match(/^\/entity_map_action\//)
      return "entity_map_action"; 
    else
      return nil;
    end
  end

 def page_entity(path = nil)
   path = request.path_info if path.nil?
 
   case page_type
   when "entity"
     return Entity::REST.restore_element(path.split("/")[3])
   when "entity_action"
     return Entity::REST.restore_element(path.split("/")[4])
   else
     return nil
   end
 end

 def page_action(path = nil)
   path = request.path_info if path.nil?
 
   case page_type
   when "entity_action", "entity_list_action"
     return Entity::REST.restore_element(path.split("/")[3])
   else
     return nil
   end
 end
 
 def page_entity_list(path = nil)
   path = request.path_info if path.nil?
 
   case page_type
   when "entity_list"
     return Entity::REST.restore_element(path.split("/")[3])
   when "entity_list_action"
     return Entity::REST.restore_element(path.split("/")[4])
   else
     return nil
   end
 end

 def page_entity_map(path = nil)
   path = request.path_info if path.nil?
 
   case page_type
   when "entity_map"
     return Entity::REST.restore_element(path.split("/")[4])
   when "entity_map_action"
     return Entity::REST.restore_element(path.split("/")[5])
   else
     return nil
   end
 end
 
 def page_entity_type(path = nil)
   path = request.path_info if path.nil?
 
   case page_type
   when "entity", "entity_list", "entity_action", "entity_list_action", "entity_map"
     return Entity::REST.restore_element(path.split("/")[2])
   else
     return nil
   end
 end

 def page_entity_base_type(path = nil)
   page_entity_type.split(":").first
 end

 def page_entity_map_column(path = nil)
   path = request.path_info if path.nil?
 
   case page_type
   when  "entity_map"
     return Entity::REST.restore_element(path.split("/")[3])
   else
     return nil
   end
 end


 #
 #
 #function page_entity_base_type(){
 #  return page_entity_type().split(":")[0]
 #}
 #
 #
 #function page_entity_format(){
 #  return page_entity_type().split(":")[1]
 #}


end
