class ActionController
  attr_accessor :entity, :id
  attr_accessor :actions

  def initialize(entity, id = nil)
    @entity, @id = entity, id
    @actions = []
  end

  def add(action, text = nil, params = {})
    text = action if text.nil?
    @actions << [action, text, params]
  end

end

module EntityRESTHelpers
  def action_controller_render(controller)
    partial_render('entity_partials/action_controller', :controller => controller)
  end
end
