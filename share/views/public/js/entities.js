

function page_type(path){
  if (undefined === path){ path = window.location.pathname; }

  if (path.match(/^\/entity\//)){ return "entity"; }
  if (path.match(/^\/entity_action\//)){ return "entity_action"; }
  if (path.match(/^\/entity_map\//)){ return "entity_map"; }
  if (path.match(/^\/entity_list\//)){ return "entity_list"; }
  if (path.match(/^\/entity_list_action\//)){ return "entity_list_action"; }
  return undefined;
}

function page_entity(path){
  if (undefined === path){ path = window.location.pathname; }

  switch(page_type()){
    case "entity":
    return restore_element(path.split("/")[3]);
    default:
    return undefined
  }
}

function page_entity_list(path){
  if (undefined === path){ path = window.location.pathname; }

  switch(page_type()){
    case "entity_list":
    return restore_element(path.split("/")[3]);
    default:
    return undefined
  }
}

function page_entity_map(path){
  if (undefined === path){ path = window.location.pathname; }

  switch(page_type()){
    case "entity_map":
    return restore_element(path.split("/")[4]);
    default:
    return undefined
  }
}

function page_entity_map_column(path){
  if (undefined === path){ path = window.location.pathname; }

  switch(page_type()){
    case "entity_map":
    return restore_element(path.split("/")[3]);
    default:
    return undefined
  }
}

function page_entity_type(path){
  if (undefined === path){ path = window.location.pathname; }
  var entity_type;

  switch(page_type()){
    case "entity":
    case "entity_list":
    case "entity_action":
    case "entity_list_action":
    case "entity_map":
    return restore_element(path.split("/")[2]);
    break;
  }
  return undefined;
}

function page_entity_base_type(){
  return page_entity_type().split(":")[0]
}

function page_entity_format(){
  return page_entity_type().split(":")[1]
}

function page_entity_info(params){
  if (undefined === params){ params = window.location.search; }
  return parse_parameters(params)
}

//{{{ Link generators

function list_link(type, id){
  var a = $('<a>' + id +'</a>');
  var url = "/entity_list/" + type + "/" + id
  var base_type = type.split(":")[0]

  a.addClass('entity_list').addClass(type).addClass(base_type).attr('href', url).attr('title', id)
  return a
}

function map_link(type, column, id){
  var a = $('<a>' + id +'</a>');
  var url = "/entity_map/" + type + "/" + column + "/" + id
  var base_type = type.split(":")[0]

  a.addClass('entity_map').addClass(type).addClass(base_type).attr('href', url).attr('title', id)
  return a
}


