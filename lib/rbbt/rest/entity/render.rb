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

  def entity_render(entity)
    template_file = locate_entity_template(entity)

    locals = {:entity => entity}

    layout_file = layout ? locate_template("layout") : nil

    render(template_file, locals, layout_file, "Entity: #{ entity }")
  end

  def entity_action_render(entity, action, params = {})
    template_file = locate_entity_action_template(entity, action)

    locals = params.merge({:entity => entity})

    layout_file = layout ? locate_template("layout") : nil

    render(template_file, locals, layout_file, "Entity #{ action }: #{ entity }")
  end

  def entity_list_render(list, id)
    template_file = locate_entity_list_template(list)

    locals = {:list => list, :list_id => id}

    layout_file = layout ? locate_template("layout") : nil

    render(template_file, locals, layout_file, "Entity list: #{ id }")
  end

  def entity_list_action_render(list, action, id, params = {})
    template_file = locate_entity_list_action_template(list, action)

    locals = params.merge({:list => list, :list_id => id})

    layout_file = layout ? locate_template("layout") : nil

    render(template_file, locals, layout_file, "Entity list #{ action }: #{ id }")
  end

  def entity_map_render(map_id, type, column)
    template_file = locate_entity_map_template(type, column)

    map = Entity::Map.load_map(type, column, map_id, user)
    locals = {:map => map, :map_id => map_id}

    layout_file = layout ? locate_template("layout") : nil

    render(template_file, locals, layout_file, "Entity map: #{ map_id }")
  end

  def entity_map_action_render(map, action, id, params = {})
    template_file = locate_entity_map_action_template(map, action)

    locals = params.merge({:map => map, :map_id => id})

    layout_file = layout ? locate_template("layout") : nil

    render(template_file, locals, layout_file, "Entity map #{ action }: #{ id }")
  end



end


