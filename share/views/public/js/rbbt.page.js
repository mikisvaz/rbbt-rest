
rbbt.page = {};
rbbt.page.entity = function(){
 var card = $('.entity_card')
 if (card.length == 0) return false
 
 var entity = card.attr('data-entity')
 var type = card.attr('data-entity-type')
 var format = card.attr('data-entity-format')
 var info = card.attr('data-entity-info')
 var id = card.attr('data-entity-id')
 return new Entity({id: id, code: entity, type: type, format: format, info: JSON.parse(info)})
}

rbbt.page.list = function(){
 var card = $('.entity_list_card')
 if (card.length == 0) return false
 
 var list = card.attr('data-list')
 var type = card.attr('data-list-type')
 return new EntityList({id: list, type: type})
}

rbbt.page.map = function(){
 var card = $('.entity_map_card')
 if (card.length == 0) return false
 
 var map = card.attr('data-map')
 var type = card.attr('data-type')
 var column = card.attr('data-column')
 return new EntityMap({id: map, type: type, column: column})
}
