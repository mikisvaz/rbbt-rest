
function get_favourite_entities(complete){
 return get_ajax({url: '/favourite_entities', async: false, cache: false}, complete)
}

function get_favourite_entity_lists(complete){
 return get_ajax({url: '/favourite_entity_lists', async: false, cache: false}, complete)
}

function get_favourite_entity_maps(complete){
 return get_ajax({url: '/favourite_entity_maps', async: false, cache: false}, complete)
}

//{{{{ FAVOURITE MENUS

function favourite_type_ul(entities){
  var type_ul = $('<ul>').addClass('entities')
  for (var entity in entities){
    var entity_hash = entities[entity];
    var link   = entity_hash["link"];
    var entity_li = $('<li>');
    entity_li.append(link);
    type_ul.append(entity_li);
  }
  return type_ul
}

function favourite_list_type_ul(type, lists){
  var type_ul = $('<ul>').addClass('lists')
  for (var list in lists){
    var list = lists[list];
    var link = list_link(type, list)
    var entity_li = $('<li>');
    entity_li.html(link);
    type_ul.append(entity_li);
  }
  return type_ul
}

function favourite_map_type_ul(type, column, maps){
  var type_ul = $('<ul>').addClass('maps')
  for (var map in maps){
    var map = maps[map];
    var link = map_link(type, column, map)
    var entity_li = $('<li>');
    entity_li.html(link);
    type_ul.append(entity_li);
  }
  return type_ul
}

$.widget("rbbt.favourites", {
 options: {
  entities: {},
  lists: {},
  maps: {}
 },

 _create: function() {
  this.update();
  var tool = this;
  this.element.on('click', 'dt.star', function(){
   tool.toggle()
   return false
  })
  this.element.on('click', 'a.remove_element', function(){
   tool._remove_element($(this).siblings('a.entity, a.entity_list, a.entity_map'))
  })
 },

 _menu: function(){
  return(this.element)
 },

 _sync: function(){
   var tool = this

   get_favourite_entities(function(entities){
     tool.options.entities = entities;
     tool._update_entities()
     tool._update_star()
   })

   get_favourite_entity_lists(function(lists){
     tool.options.lists = lists;
     tool._update_lists()
     tool._update_star()
   })


   get_favourite_entity_maps(function(maps){
     tool.options.maps = maps;
     tool._update_maps()
     tool._update_star()
   })
 },

 //{{{ REMOVE ELEMENT
 //----------

 _remove_element: function(link){
  var item = link.parent('li');
  var ul = item.parent('ul');
  var type = ul.attr('class');
  var dt = ul.parent('dd').prev('dt');
  var element     = link.attr('title');
  var entity_type = dt.attr('entity_type');
  var entity_column = dt.attr('entity_column');
  var url;
  var tool = this;

  switch(type){
   case "entities":
   method = "/remove_favourite_entity/";
   element = link.attr('attr-entity_id')
   url = method + clean_element(entity_type) + "/" + element;
   break;

   case "lists":
   method = "/remove_favourite_entity_list/";
   url = method + clean_element(entity_type) + "/" + clean_element(element);
   break;

   case "maps":
   method = "/remove_favourite_entity_map/";
   url = method + clean_element(entity_type) + "/" + clean_element(entity_column) + "/" + clean_element(element);
   break;
  };

  $.ajax({url: url, type: 'POST', success: function (){ tool.update()}})
 },

 _add_destructors: function(list){
  var icon = $('<i class="general foundicon-minus">')
  var remove = $('<a class=remove_element></a>').append(icon)
  list.find('li').prepend(remove)
 },


 //{{{ TOGGLE PAGE STAR
 //----------

 _update_star: function(){
  if (this.is_favourite() == true){
   this.element.find('dt.star').addClass('active');
  }else{
   this.element.find('dt.star').removeClass('active');
  }
 },
 _toggle_page: function(){
  this.toggle_page(undefined)
 },

 toggle: function(){
  this._toggle_page();
 },

 //{{{ UPDATE
 //----------

 _update_entities: function(){
  var menu = this._menu()
  menu.find('ul.entities').addClass('remove');

  var entities = menu.find('dt.entities').next('dd').find('> dl')
  for(type in this.options.entities){
   var ul = favourite_type_ul(this.options.entities[type]);
   this._add_destructors(ul)
   var dt = entities.find('dt[entity_type=' + clean_attr(type) + ']')

   if (dt.length == 0){
    var dt = $('<dt>').html(type).addClass('next').addClass('type').attr('entity_type', type);
    var dd = $('<dd>').append(ul);
    entities.append(dt).append(dd);
    update_rbbt();
   }else{
    if (dt.next('dd').find('ul.entities').length == 0){
     dt.next('dd').append(ul);
    }else{
     dt.next('dd').find('ul.entities').replaceWith(ul);
    }
   }

   menu.find('dt[entity_type=' + clean_attr(type) + ']').next('dd').find('ul.entities').replaceWith(ul);
  }
  menu.find('ul.entities.remove').remove()
 },

 _update_lists: function(){
  var menu = this._menu()
  menu.find('ul.lists').addClass('remove');

  var lists = menu.find('dt.lists').next('dd').find('> dl')
  for(type in this.options.lists){
   var ul = favourite_list_type_ul(type, this.options.lists[type])
   this._add_destructors(ul)
   var dt = lists.find('dt[entity_type=' + clean_attr(type) + ']');

   if (dt.length == 0){
    var dt = $('<dt>').html(type).addClass('next').addClass('type').attr('entity_type', type);
    var dd = $('<dd>').append(ul);
    lists.append(dt).append(dd);
    update_rbbt();
   }else{
    if (dt.next('dd').find('ul.lists').length == 0){
     dt.next('dd').append(ul);
    }else{
     dt.next('dd').find('ul.lists').replaceWith(ul);
    }
   }
  }
  menu.find('ul.lists.remove').remove();
 },

 _update_maps: function(){
  var menu = this._menu()
  menu.find('ul.maps').addClass('remove')

  var maps = menu.find('dt.maps').next('dd').find('> dl')
  for(type in this.options.maps){
   for(column in this.options.maps[type]){
    var ul = favourite_map_type_ul(type, column, this.options.maps[type][column]);
    this._add_destructors(ul)
    var dt = maps.find('dt[entity_type=\'' + clean_attr(type) + '\'][entity_column=\'' + clean_attr(column) + '\']');

    if (dt.length == 0){
     var dt = $('<dt>').html(type + ' - ' + column).addClass('next').addClass('type').attr('entity_type', clean_attr(type)).attr('entity_column', clean_attr(column));
     var dd = $('<dd>').append(ul);
     maps.append(dt).append(dd);
     update_rbbt();
    }else{
     if (dt.next('dd').find('ul.maps').length == 0){
      dt.next('dd').append(ul);
     }else{
      dt.next('dd').find('ul.maps').replaceWith(ul);
     }
    }
   }
  }
  menu.find('ul.maps.remove').remove()
 },


 //{{{ SELECTS
 //
 _update_list_select: function(select, type, lists){
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
      option = $('<option attr-entity_type="' + type + '" class="automatic_load" value="' + name + '">' + name + '</option>');
    }else{
      option = $('<option attr-entity_type="' + type + '" class="automatic_load" selected=selected value="' + name + '">' + name + '</option>');
    }
    select.append(option);
    return true
  })
 },

 _update_map_select: function(select, type, map_lists){
  if (select.attr('attr-allow-empty') == 'true'){
   var option = $('<option value="none" class="loaded">none</option>');
   select.append(option);
  }

  var selected = null;

  if (select.attr('attr-selected') != undefined ){
   selected = select.attr('attr-selected');
  }

  for (column in map_lists){
   var maps = map_lists[column];
   if (undefined === select.attr('column') || select.attr('column') == column){
    $.each(maps, function(name, elems){
     var option = null;
     var name = elems
     if (selected == null || name != selected){
      option = $('<option class="automatic_load" attr-entity_type="' + clean_attr(type) + '" attr-column="'+ clean_attr(column) + '" value="' + name + '">' + name + '</option>');
     }else{
      option = $('<option class="automatic_load" attr-entity_type="' + clean_attr(type) + '" attr-column="'+ clean_attr(column) + '" selected=selected value="' + name + '">' + name + '</option>');
     }
     select.append(option);
     return true
    })
   }
  }
 },

 //{{{ UPDATES
 //
 update_list_selects: function(){
  var tool = this;
  $('select.favourite_lists').find('option.automatic_load').remove()

  $.each(this.options.lists, function(type, lists){
   $('select.favourite_lists[type=' + type + ']').each(function(){
    var select = $(this);
    tool._update_list_select(select, type, lists);
   })
   $('select.favourite_lists[type=All]').each(function(){
    var select = $(this);
    select.append($('<option class="automatic_load" disabled>'+ type +'</option>'));
    tool._update_list_select(select, type, lists);
   })
  });
 },

 update_map_selects: function(){
  var tool = this;
  $('select.favourite_maps').find('option.automatic_load').remove()

  $.each(this.options.maps, function(type, maps){
    $('select.favourite_maps[type=' + type + ']').each(function(){
      var select = $(this);
      tool._update_map_select(select, type, maps);
    })
    $('select.favourite_maps[type=All]').each(function(){
      var select = $(this);
      select.append($('<option class="automatic_load" disabled>'+ type +'</option>'));
      tool._update_map_select(select, type, maps);
    })
  });
 },

 close: function(){
  this.element.find('.show').removeClass('show')
 },

 is_favourite: function(path){
  var type = page_type(path);

  switch(type){

   case "entity":
   var entity      = page_entity(path);
   var entity_type = page_entity_base_type(path);
   return this.options.entities[entity_type] !== undefined && this.options.entities[entity_type][entity] !== undefined

   case "entity_list":
   var list = page_entity_list(path);
   var entity_type = page_entity_base_type(path);
   return this.options.lists[entity_type] !== undefined && _.indexOf(this.options.lists[entity_type], list) !== -1

   case "entity_map":
   var map      = page_entity_map(path);
   var entity_type = page_entity_base_type(path);
   var entity_column = page_entity_map_column(path);
   return this.options.maps[entity_type] !== undefined && this.options.maps[entity_type][entity_column] !== undefined && _.indexOf(this.options.maps[entity_type][entity_column], map) !== -1
  }

  return false
 },

 toggle_page: function(path){
  var type = page_type(path);
  var tool = this
  switch(type){

   case "entity":
   var entity      = page_entity(path);
   var entity_type = page_entity_type(path);
   var entity_info = page_entity_info(path);

   if (this.is_favourite(path)){
    method = "/remove_favourite_entity/";
   }else{
    method = "/add_favourite_entity/";
   }
   var url = method + clean_element(entity_type) + "/" + entity;
   $.ajax({url: url, type: 'POST', data: entity_info, success: function (){ tool.update()}})
   break;

   case "entity_list":
   var list = page_entity_list(path);
   var entity_type = page_entity_type(path);
   if (this.is_favourite(path)){
    method = "/remove_favourite_entity_list/";
   }else{
    method = "/add_favourite_entity_list/";
   }
   var url = method + clean_element(entity_type) + "/" + clean_element(list);
   $.ajax({url: url, type: 'POST', success: function (){ tool.update() }})
   break;

   case "entity_map":
   var map      = page_entity_map(path);
   var entity_type = page_entity_type(path);
   var entity_column = page_entity_map_column(path);
   if (this.is_favourite(path)){
    method = "/remove_favourite_entity_map/";
   }else{
    method = "/add_favourite_entity_map/";
   }
   var url = method + clean_element(entity_type) + "/" + clean_element(entity_column) + "/" + clean_element(map);
   $.ajax({url: url, type: 'POST', success: function (){ tool.update()}})
   break;
  }
 },


 update: function(){
  this._sync()
  //this._update_entities()
  //this._update_lists()
  //this._update_maps()
  //this._update_star()
  //this._add_destructors()
  $('#modal.url.entity').modal('update_star')
 }

})


