class ActionController
  attr_accessor :entity, :id
  attr_accessor :actions

  def initialize(entity, id = nil)
    @entity, @id = entity, id
    @actions = []
  end

  def add(action, text = nil, resource = nil, params = {})
    text = action if text.nil?
    resource = action.respond_to?(:resource) ? action.resource : nil
    resource ||= "Rbbt"
    @actions << [action, text, resource, params]
  end

end

module EntityRESTHelpers
  def default_action_controller(entity, list_id = nil)
    action_controller = ActionController.new(entity, list_id)

    if Array === entity
      find_all_entity_list_action_templates(entity).each do |action|
        action_controller.add action, Misc.humanize(action, :format => :sentence), :reuse => true
      end
    else
      find_all_entity_action_templates(entity).each do |action|
        action_controller.add action, Misc.humanize(action, :format => :sentence)
      end
    end
    action_controller
  end

  def action_controller_render(controller)
    partial_render('entity_partials/action_controller', :controller => controller)
  end
end
