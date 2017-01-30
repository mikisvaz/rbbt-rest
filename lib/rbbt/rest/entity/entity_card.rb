class EntityCard

  attr_accessor :entity
  attr_accessor :name, :long_name, :description, :meta
  attr_accessor :list_container, :action_controller
  attr_accessor :sections

  def initialize(entity)
    @entity = entity
  end


  def sections
    @sections ||= IndiferentHash.setup({})
  end

  def add_section(name, &block)
    sections[name] = block
  end

  %w(name long_name description meta).each do |method|
    self.send(:define_method, method.to_sym) do |&block|
      if block
        instance_variable_set("@#{method}", block)
      else
        instance_variable_get("@#{method}")
      end
    end
  end
end

module EntityRESTHelpers
  def entity_card_render(card,&block)
    partial_render('entity_partials/entity_card', :card => card, :block => block)
  end
end

