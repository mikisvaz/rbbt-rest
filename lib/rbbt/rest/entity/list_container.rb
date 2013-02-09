class ListContainer
  attr_accessor :lists
  def initialize
    @lists = []
  end

  def add(list_id, list = nil, text = nil, options = {}, &block)
    text, options, list = list, text, block if  block_given?
    options, text = text, options if Hash === text

    if list and (Proc === list or list.any?)
      @lists << [list_id, list, text, options]
    end
  end

end

module EntityRESTHelpers
  def list_container_render(container)
    partial_render('entity_partials/list_container', :container => container)
  end
end
