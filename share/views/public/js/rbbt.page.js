rbbt.page = {};

rbbt.page.type = function(path){
  if (undefined === path){ path = window.location.pathname; }

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

//{{{ OLD
//function rbbt.page_entity(path){
//  if (undefined === path){ path = window.location.pathname; }
//
//  switch(page_type(path)){
//    case "entity":
//    return restore_element(path.split('?')[0].split("/")[3]);
//    default:
//    return undefined
//  }
//}
//
//function rbbt.page_entity_list(path){
//  if (undefined === path){ path = window.location.pathname; }
//
//  switch(page_type(path)){
//    case "entity_list":
//    return restore_element(path.split('?')[0].split("/")[3]);
//    default:
//    return undefined
//  }
//}
//
//function rbbt.page_entity_map(path){
//  if (undefined === path){ path = window.location.pathname; }
//
//  switch(page_type(path)){
//    case "entity_map":
//    return restore_element(path.split('?')[0].split("/")[4]);
//    default:
//    return undefined
//  }
//}
//
//function rbbt.page_entity_map_column(path){
//  if (undefined === path){ path = window.location.pathname; }
//
//  switch(page_type(path)){
//    case "entity_map":
//    return restore_element(path.split("/")[3]);
//    default:
//    return undefined
//  }
//}
//
//function rbbt.page_entity_type(path){
//  if (undefined === path){ path = window.location.pathname; }
//  var entity_type;
//
//  switch(page_type(path)){
//    case "entity":
//    case "entity_list":
//    case "entity_action":
//    case "entity_list_action":
//    case "entity_map":
//    return restore_element(path.split("/")[2]);
//    break;
//  }
//  return undefined;
//}
//
//function rbbt.page_entity_base_type(path){
//  return page_entity_type(path).split(":")[0]
//}
//
//function rbbt.page_entity_format(path){
//  return page_entity_type(path).split(":")[1]
//}
//
//function rbbt.page_entity_info(path){
// var params;
// if (undefined === path){ 
//  params = window.location.search; 
// }else{
//  params = path.split('?')[1]
// }
// return parse_parameters(params)
//}
//
////{{{ Link generators
//

