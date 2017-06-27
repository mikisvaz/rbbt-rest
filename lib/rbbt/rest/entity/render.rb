require 'rbbt/util/open'
require 'rbbt/rest/common/render'

require 'haml'
module EntityRESTHelpers

  def setup_entity(type, entity, params)
    base_type, format = type.split ":"
    entity_class = case
                   when Entity.formats.include?(base_type)
                     Entity.formats[base_type] 
                   when Entity.formats.include?(format)
                     Entity.formats[format] 
                   else
                     nil
                   end

    raise "Unknown entity type: #{ type }" if entity_class.nil?

    raise "Entity type not supported in REST: #{ type }" unless entity_class.include? Entity::REST

    entity_annotations = {}
    entity_class.annotations.each do |annotation|
      value = consume_parameter annotation, params
      value = Entity::REST.restore_element(value) if String === value
      value = false if value == "false"
      value = true if value == "true"
      entity_annotations[annotation] = value
    end

    entity.extend entity_class
    entity_class.setup_hash(entity, entity_annotations)
    entity.format = format if format and entity.respond_to? :format

    entity
  end

  def entity_render(entity, params = {})
    template_file = locate_entity_template(entity)

    params = {} if params.nil?
    locals = {:entity => entity}.merge(params)

    name = entity.respond_to?(:name)? entity.name : entity
    @title = "#{name} [#{$title}]"

    Log.low "Rendering #{ entity }: #{ template_file }"
    layout_file = layout ? locate_template("layout") : nil

    render(template_file, locals, layout_file, "Entity: #{ entity }")
  end

  def entity_action_render(entity, action, params = {})
    template_file = locate_entity_action_template(entity, action)

    locals = params.merge({:entity => entity})

    name = entity.respond_to?(:name)? entity.name : entity
    @title = "#{action} #{name} [#{$title}]"

    Log.low "Rendering #{ entity } #{ action }: #{ template_file }"
    layout_file = layout ? locate_template("layout") : nil

    render(template_file, locals, layout_file, "Action #{ action }: #{ entity }")
  end

  def entity_list_render(list, id)
    template_file = locate_entity_list_template(list)

    locals = {:list => list, :list_id => id}

    name = id
    @title = "#{name} [#{$title}]"

    Log.low "Rendering #{list.base_type.to_s} list: #{ template_file }"
    layout_file = layout ? locate_template("layout") : nil

    render(template_file, locals, layout_file, "Entity list: #{ id }")
  end

  def entity_list_action_render(list, action, id, params = {})
    template_file = locate_entity_list_action_template(list, action)

    locals = params.merge({:list => list, :list_id => id})

    name = id
    @title = "#{action} #{name} [#{$title}]"

    Log.low "Rendering #{list.base_type.to_s} list #{ action }: #{ template_file }"
    layout_file = layout ? locate_template("layout") : nil

    render(template_file, locals, layout_file, "Action #{ action } for list: #{ id }")
  end

  def entity_map_render(map_id, type, column)
    template_file = locate_entity_map_template(type, column)

    map = Entity::Map.load_map(type, column, map_id, user)
    locals = {:map => map, :map_id => map_id}

    name = map_id
    @title = "#{name} [#{$title}]"

    Log.low "Rendering #{type} map: #{ template_file }"
    layout_file = layout ? locate_template("layout") : nil

    render(template_file, locals, layout_file, "Entity map: #{ map_id }")
  end

  def entity_map_action_render(map, action, id, params = {})
    template_file = locate_entity_map_action_template(map, action)

    locals = params.merge({:map => map, :map_id => id})

    name = id
    @title = "#{action} #{name} [#{$title}]"

    Log.low "Rendering '#{map.key_field} - #{map.fields.first}' map #{ action }: #{ template_file }"
    layout_file = layout ? locate_template("layout") : nil

    render(template_file, locals, layout_file, "Action #{ action } for map: #{ id }")
  end
end


