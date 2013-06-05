class EntityMapCard

  attr_accessor :map, :map_id

  def initialize(map, map_id)
    @map, @map_id = map, map_id
  end
end

module EntityRESTHelpers
  def entity_map_card_render(card)
    partial_render('entity_partials/entity_map_card', :card => card)
  end
end
