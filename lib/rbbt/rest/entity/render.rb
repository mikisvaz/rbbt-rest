require 'rbbt/util/open'

require 'haml'
module EntityRESTHelpers

  def setup_entity(type, entity, params)
    base_type, format = type.split ":"
    entity_class = case
                   when Entity.formats.include?(format)
                     Entity.formats[format] 
                   when Entity.formats.include?(base_type)
                     Entity.formats[base_type] 
                   else
                     nil
                   end

    raise "Unknown entity type: #{ type }" if entity_class.nil?

    entity_annotations = {}
    entity_class.annotations.each do |annotation|
      value = consume_parameter annotation, params
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
    if layout
      layout_file = locate_template("layout")
      Haml::Engine.new(Open.read(layout_file), :filename => layout_file).render(self) do
        Haml::Engine.new(Open.read(template_file), :filename => template_file).render(self, locals)
      end
    else
      Haml::Engine.new(Open.read(template_file), :filename => template_file).render(self, locals)
    end
  end

  def entity_action_render(entity, action, params = {})
    template_file = locate_entity_action_template(entity, action)

    locals = params.merge({:entity => entity})
    if layout
      layout_file = locate_template("layout")
      Haml::Engine.new(Open.read(layout_file), :filename => layout_file).render(self) do
        Haml::Engine.new(Open.read(template_file), :filename => template_file).render(self, locals)
      end
    else
      Haml::Engine.new(Open.read(template_file), :filename => template_file).render(self, locals)
    end
  end

  def entity_list_render(list)
    template_file = locate_entity_list_template(list)

    locals = {:list => list}
    if layout
      layout_file = locate_template("layout")
      Haml::Engine.new(Open.read(layout_file), :filename => layout_file).render(self) do
        Haml::Engine.new(Open.read(template_file), :filename => template_file).render(self, locals)
      end
    else
      Haml::Engine.new(Open.read(template_file), :filename => template_file).render(self, locals)
    end
  end

  def entity_list_action_render(list, action, params = {})
    template_file = locate_entity_list_action_template(list, action)

    locals = params.merge({:list => list})
    if layout
      layout_file = locate_template("layout")
      Haml::Engine.new(Open.read(layout_file), :filename => layout_file).render(self) do
        Haml::Engine.new(Open.read(template_file), :filename => template_file).render(self, locals)
      end
    else
      Haml::Engine.new(Open.read(template_file), :filename => template_file).render(self, locals)
    end
  end
end


