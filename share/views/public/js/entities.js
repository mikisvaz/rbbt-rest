
function page_type(path){
  if (undefined === path){
    path = window.location.pathname;
  }

  if (path.match(/^\/entity\//)){ return "entity"; }
  if (path.match(/^\/entity_action\//)){ return "entity_action"; }
  if (path.match(/^\/entity_list\//)){ return "entity_list"; }
  if (path.match(/^\/entity_list_action\//)){ return "entity_list_action"; }
}

