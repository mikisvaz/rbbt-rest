rbbt.page = {};

rbbt.page.path = function(){
  return window.location.pathname;
}

rbbt.page.path_parts = function(path){
  if (undefined === path) path = rbbt.page.path() 

  var parts = path.split("/")
  if (parts[0] == "") parts.shift()

  return parts
}

rbbt.page.type = function(path){
  if (undefined === path) path = rbbt.page.path() 

  if (path.match(/^\/entity\//)){ return "entity"; }
  if (path.match(/^\/entity_action\//)){ return "entity_action"; }
  if (path.match(/^\/entity_map\//)){ return "entity_map"; }
  if (path.match(/^\/entity_list\//)){ return "entity_list"; }
  if (path.match(/^\/entity_list_action\//)){ return "entity_list_action"; }
  return undefined;
}

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

 if (card.length > 0){ 
   var list = card.attr('data-list')
   var type = card.attr('data-list-type')
   return new EntityList({id: list, type: type})
 }

 if (rbbt.page.type() == 'entity_list_action'){
   var parts = rbbt.page.path_parts()
   var type = parts[1]
   var list = parts[3]
   return new EntityList({id: list, type: type})
 } 

 return false
}

rbbt.page.map = function(){
 var card = $('.entity_map_card')
 if (card.length == 0) return false
 
 var map = card.attr('data-map')
 var type = card.attr('data-type')
 var column = card.attr('data-column')
 return new EntityMap({id: map, type: type, column: column})
}


rbbt.page.list_link = function(type, id){
  var url = "/entity_list/" + clean_element(type) + "/" + clean_element(id)
  var base_type = type.split(":")[0]
  return  m('a', {class: ['entity_list', type, base_type].join(" "), href: url, title: id}, id)
}

rbbt.page.map_link = function(type, column, id){
  var a = $('<a>' + id +'</a>');
  var url = "/entity_map/" + clean_element(type) + "/" + clean_element(column) + "/" + clean_element(id)
  var base_type = type.split(":")[0]

  a.addClass('entity_map').addClass(type).addClass(base_type).attr('href', url).attr('title', id)
  return a
}

