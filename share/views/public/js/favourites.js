function setup_favourites(){

  register_dom_update('a#toggle_favourite', function(link){
    link.click(function(){
      var link = $(this);

      var type        = page_type();
      switch(type){
        case "entity":
        var entity      = page_entity();
        var entity_type = page_entity_type();
        var entity_info = page_entity_info();

        if (link.hasClass('active')){
          method = "/remove_favourite_entity/";
        }else{
          method = "/add_favourite_entity/";
        }
        var url = method + clean_element(entity_type) + "/" + entity;

        $.ajax({url: url, type: 'POST', data: entity_info, success: function (){ update_favourite_entities() }})

        return false
        case "entity_list":
        var entity_list      = page_entity_list();
        var entity_type = page_entity_type();

        if (link.hasClass('active')){
          method = "/remove_favourite_entity_list/";
        }else{
          method = "/add_favourite_entity_list/";
        }
        var url = method + clean_element(entity_type) + "/" + entity_list;

        $.ajax({url: url, type: 'POST', success: function (){ update_favourite_entity_lists() }})

        return false
      }
    })
  })

  update_favourite_entities_star();
}

function get_favourite_entities(){
  return JSON.parse($.ajax({url: '/favourite_entities', async: false, cache: false}).responseText)
}

function get_favourite_entity_lists(){
  return JSON.parse($.ajax({url: '/favourite_entity_lists', async: false, cache: false}).responseText)
}

function update_favourite_entities_star(favourites){

  var type = page_type();
  switch(type){
    case "entity":

    if (undefined === favourites){ favourites = get_favourite_entities(); }

    var entity = page_entity();
    var type = page_entity_base_type();

    if ((favourites[type] != undefined) && (favourites[type][entity] != undefined)){
      $('a#toggle_favourite').addClass('active').removeClass('inactive');
    }else{
      $('a#toggle_favourite').removeClass('active').addClass('inactive');
    }

    break
    case "entity_list":

    if (undefined === favourites){ favourites = get_favourite_entity_lists(); }

    var entity_list = page_entity_list();
    var type = page_entity_base_type();

    if ((favourites[type] != undefined) && ($.inArray(entity_list, favourites[type]) != -1 )){
      $('a#toggle_favourite').addClass('active').removeClass('inactive');
    }else{
      $('a#toggle_favourite').removeClass('active').addClass('inactive');
    }


    break
  }
}

function favourite_type_ul(entities){
  var type_ul = $('<ul>')
  for (var entity in entities){
    var entity_hash = entities[entity];
    var link   = entity_hash["link"];
    var entity_li = $('<li>');
    entity_li.html(link);
    type_ul.append(entity_li);
  }
  return type_ul
}

function favourite_list_type_ul(type, lists){
  var type_ul = $('<ul>')
  for (var list in lists){
    var list = lists[list];
    var link = list_link(type, list)
    var entity_li = $('<li>');
    entity_li.html(link);
    type_ul.append(entity_li);
  }
  return type_ul
}

function update_favourite_entities(favourites){
  if (undefined === favourites){ favourites = get_favourite_entities(); }

  var favourites_ul = $('<ul class="dropdown favourite_entities" >');
  var title_li = $('<li class="title back js-generated rbbt-generated"><h5><a href="#">Favourite Entities</a></h5></li>');
  favourites_ul.append(title_li);

  for (var type in favourites){

      var title_li = $('<li class="title back js-generated rbbt-generated"><h5><a href="#">' + type + '</a></h5></li>');
      var entities = favourites[type];
      var type_ul = favourite_type_ul(entities);
      type_ul.addClass("dropdown").prepend(title_li);

      var type_li = $('<li class="has-dropdown">')
      type_li.append($('<a href="#">' + type + '</a>')).append(type_ul);

      favourites_ul.append(type_li);
  }

  var current_favourites = $('li#top-favourites ul.favourite_entities')
  current_favourites.replaceWith(favourites_ul);
  update_favourite_entities_star(favourites);
}

function update_favourite_entity_lists(favourites){
  if (undefined === favourites){ favourites = get_favourite_entity_lists(); }

  var favourites_ul = $('<ul class="dropdown favourite_entity_lists" >');
  var title_li = $('<li class="title back js-generated rbbt-generated"><h5><a href="#">Favourite Entities Lists</a></h5></li>');
  favourites_ul.append(title_li);

  for (var type in favourites){

      var title_li = $('<li class="title back js-generated rbbt-generated"><h5><a href="#">' + type + '</a></h5></li>');
      var lists = favourites[type];
      var type_ul = favourite_list_type_ul(type, lists);

      type_ul.addClass("dropdown").prepend(title_li);

      var type_li = $('<li class="has-dropdown">')
      type_li.append($('<a href="#">' + type + '</a>')).append(type_ul);

      favourites_ul.append(type_li);
  }

  var current_favourites = $('li#top-favourite_lists ul.favourite_entity_lists')
  current_favourites.replaceWith(favourites_ul);
  update_favourite_entities_star(favourites);
  update_selects(favourites);
}

function update_select(select, lists){
  select.find('option[class*=automatic_load]').remove();

  if (select.attr('attr-allow-empty') == 'true'){
    var option = $('<option value="none" class="loaded">none</option>')
    select.append(option);
  }

  var selected = null;

  if (select.attr('attr-selected') != undefined ){
    selected = select.attr('attr-selected');
  }

  $.each(lists, function(name, elems){
    var option = null;
    var name = elems
    if (selected == null || name != selected){
      option = $('<option class="automatic_load" value="' + name + '">' + name + '</option>');
    }else{
      option = $('<option class="automatic_load" selected=selected value="' + name + '">' + name + '</option>');
    }
    select.append(option);
    return true
  })

}

function update_selects(favourites){
  if (undefined === favourites){ favourites = get_favourite_entity_lists(); }

  $.each(favourites, function(type, lists){
    $('select.favourite_lists[type=' + type + ']').each(function(){
      var select = $(this);
      update_select(select, lists);
    })
  });
}

register_dom_update('select.favourite_lists', function(select){
  var type = select.attr('type');
  var lists = get_favourite_entity_lists()[type];
  if (undefined !== lists){
    update_select(select, lists);
  }
})
