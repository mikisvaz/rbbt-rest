class EntityListCard

  attr_accessor :list, :list_id
  attr_accessor :meta, :description
  attr_accessor :list_container, :action_controller

  def initialize(list, list_id)
    @list, @list_id = list, list_id
  end

  %w(meta description).each do |method|
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
  def entity_list_card_render(card)
    partial_render('entity_partials/entity_list_card', :card => card)
  end
end
