class ActionCard

  attr_accessor :action_parameters, :requires, :description
  def initialize(&block)
    @action_parameters = block
    @requires = []
  end

  def description(value = nil, &block)
    if block_given?
      @description = block
    else
      @description
    end
  end

  def require(*inputs, &block)
    if block_given?
      @requires << [inputs, block]
    else
      @requires.concat inputs
    end
  end
end

module EntityRESTHelpers
  def action_card_render(card, &block)
    partial_render('entity_partials/action_card', :card => card, :block => block)
  end
end
