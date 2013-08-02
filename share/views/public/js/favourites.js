// HELPERS
if (loggedin){
 function get_favourite_entities(){
   return JSON.parse(get_ajax({url: '/favourite_entities', async: false, cache: false}))
 }

 function get_favourite_entity_lists(){
   return JSON.parse(get_ajax({url: '/favourite_entity_lists', async: false, cache: false}))
 }

 function get_favourite_entity_maps(){
   return JSON.parse(get_ajax({url: '/favourite_entity_maps', async: false, cache: false}))
 }

 function toggle_favourite(link){
   var link = $(link);
   var path;

   if (link.parents('.reveal-modal').length == 0){
     path = undefined;
   }else{
     path = link.closest('.reveal-modal').find('.embedded').first().attr('target-href');
   }

   var type = page_type(path);
   switch(type){
     case "entity":
     var entity      = page_entity(path);
     var entity_type = page_entity_type(path);
     var entity_info = page_entity_info(path);

     if (link.hasClass('active')){
       method = "/remove_favourite_entity/";
     }else{
       method = "/add_favourite_entity/";
     }
     var url = method + clean_element(entity_type) + "/" + entity;

     $.ajax({url: url, type: 'POST', data: entity_info, success: function (){ update_favourite_entities() }})

     return false
     case "entity_list":
     var entity_list      = page_entity_list(path);
     var entity_type      = page_entity_type(path);

     if (link.hasClass('active')){
       method = "/remove_favourite_entity_list/";
     }else{
       method = "/add_favourite_entity_list/";
     }
     var url = method + clean_element(entity_type) + "/" + clean_element(entity_list);

     $.ajax({url: url, type: 'POST', success: function (){ update_favourite_entity_lists() }})

     return false
     case "entity_map":
     var entity_map      = page_entity_map(path);
     var entity_type     = page_entity_type(path);
     var entity_column   = page_entity_map_column(path);

     if (link.hasClass('active')){
       method = "/remove_favourite_entity_map/";
     }else{
       method = "/add_favourite_entity_map/";
     }
     var url = method + clean_element(entity_type) + "/" + clean_element(entity_column) + "/" + clean_element(entity_map);

     $.ajax({url: url, type: 'POST', success: function (){ update_favourite_entity_maps() }})
   }
 }

 // TOGGLE START

 $('body').on('click', 'a#toggle_favourite, .reveal-modal a.toggle_favourite',function(link){
   var link = $(this)
   toggle_favourite(link)
   update_favourite_entities_star(undefined, link);
   return false
 })


 function update_favourite_entities_star(favourites, link){
   if (undefined === link){link = $('a#toggle_favourite')}

   var path
   if (link.parents('.reveal-modal').length == 0){
     path = undefined;
   }else{
     path = link.closest('.reveal-modal').find('.embedded').first().attr('target-href');
   }

   var type = page_type(path);
   switch(type){
     case "entity":
     if (undefined === favourites){ favourites = get_favourite_entities(path); }

     var entity = page_entity(path);
     var type = page_entity_base_type(path);

     if ((favourites[type] != undefined) && (favourites[type][entity] != undefined)){
       link.addClass('active').removeClass('inactive');
     }else{
       link.removeClass('active').addClass('inactive');
     }
     break

     case "entity_list":
     if (undefined === favourites){ favourites = get_favourite_entity_lists(path); }

     var entity_list = page_entity_list(path);
     var type = page_entity_base_type(path);

     if ((favourites[type] != undefined) && ($.inArray(entity_list, favourites[type]) != -1 )){
       link.addClass('active').removeClass('inactive');
     }else{
       link.removeClass('active').addClass('inactive');
     }
     break

     case "entity_map":
     if (undefined === favourites){ favourites = get_favourite_entity_maps(path); }

     var entity_list = page_entity_map(path);
     var type = page_entity_base_type(path);
     var column = page_entity_map_column(path);

     if ((favourites[type] != undefined) && (favourites[type][column] != undefined) && ($.inArray(entity_list, favourites[type][column]) != -1 )){
       link.addClass('active').removeClass('inactive');
     }else{
       link.removeClass('active').addClass('inactive');
     }

     break
   }
 }

 //{{{{ FAVOURITE MENUS

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

 function favourite_map_type_ul(type, column, maps){
   var type_ul = $('<ul>')
   for (var map in maps){
     var map = maps[map];
     var link = map_link(type, column, map)
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
   update_list_selects(favourites);
 }

 function update_favourite_entity_maps(favourites){
   if (undefined === favourites){ favourites = get_favourite_entity_maps(); }

   var favourites_ul = $('<ul class="dropdown favourite_entity_maps" >');
   var title_li = $('<li class="title back js-generated rbbt-generated"><h5><a href="#">Favourite Entities Lists</a></h5></li>');
   favourites_ul.append(title_li);

   for (var type in favourites){
     for (var column in favourites[type]){
       var title_li = $('<li class="title back js-generated rbbt-generated"><h5><a href="#">' + type + ' - ' + column + '</a></h5></li>');
       var lists = favourites[type][column];
       var type_ul = favourite_map_type_ul(type, column, lists);

       type_ul.addClass("dropdown").prepend(title_li);

       var type_li = $('<li class="has-dropdown">')
       type_li.append($('<a href="#">' + type + ' - ' + column + '</a>')).append(type_ul);

       favourites_ul.append(type_li);
     }

   }

   var current_favourites = $('li#top-favourite_maps ul.favourite_entity_maps')
   current_favourites.replaceWith(favourites_ul);
   update_favourite_entities_star(favourites);
   update_map_selects(favourites);
 }

 //{{{{ LIST SELECTS

 function update_list_select(select, type, lists){
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
 }

 function update_list_selects(favourites){
   if (undefined === favourites){ favourites = get_favourite_entity_lists(); }

   $('select.favourite_lists').find('option.automatic_load').remove()

   $.each(favourites, function(type, lists){
     $('select.favourite_lists[type=' + type + ']').each(function(){
       var select = $(this);
       update_list_select(select, type, lists);
     })
     $('select.favourite_lists[type=All]').each(function(){
       var select = $(this);
       select.append($('<option class="automatic_load" disabled>'+ type +'</option>'));
       update_list_select(select, type, lists);
     })
   });

 }

 register_dom_update('select.favourite_lists', function(select){
  $.each(select, function(){
   var select = $(this);
   var type = select.attr('type');
   console.log(type)
   if (type == 'All'){
    update_list_selects();
   }else{
    var lists = get_favourite_entity_lists()[type];
    if (undefined !== lists){
     update_list_select(select, type, lists);
    }
   }
  })
 })

 //{{{{ MAP SELECTS

 function update_map_select(select, type, map_lists){
   if (select.attr('attr-allow-empty') == 'true'){
     var option = $('<option value="none" class="loaded">none</option>')
     select.append(option);
   }

   var selected = null;

   if (select.attr('attr-selected') != undefined ){
     selected = select.attr('attr-selected');
   }

   for (column in map_lists){
     var maps = map_lists[column]
     if (undefined === select.attr('column') || select.attr('column') == column){
       $.each(maps, function(name, elems){
         var option = null;
         var name = elems
         if (selected == null || name != selected){
           option = $('<option class="automatic_load" attr-entity_type="' + type + '" attr-column="'+ column + '" value="' + name + '">' + name + '</option>');
         }else{
           option = $('<option class="automatic_load" attr-entity_type="' + type + '" attr-column="'+ column + '" selected=selected value="' + name + '">' + name + '</option>');
         }
         select.append(option);
         return true
       })
     }
   }
 }

 function update_map_selects(favourites){
   if (undefined === favourites){ favourites = get_favourite_entity_maps(); }

   $('select.favourite_maps').find('option.automatic_load').remove()

   $.each(favourites, function(type, maps){
     $('select.favourite_maps[type=' + type + ']').each(function(){
       var select = $(this);
       update_map_select(select, type, maps);
     })
     $('select.favourite_maps[type=All]').each(function(){
       var select = $(this);
       select.append($('<option class="automatic_load" disabled>'+ type +'</option>'));
       update_map_select(select, type, maps);
     })

   });
 }

 register_dom_update('select.favourite_maps', function(select){
   var type = select.attr('type');
   if (type == "All"){
     update_map_selects();
   }else{
     var map_lists = get_favourite_entity_maps()[type];
     if (undefined !== map_lists){
       update_map_select(select, type, map_lists);
     }
   }
 })

 // HIGHLIGHT

 if (undefined === localStorage["highlights"]){
   localStorage["highlights"] = '{}'
 }

 register_dom_update('ul.favourite_entity_lists > li > ul.dropdown > li > a:not(.highlight)', function(list_link){
   list_link.before($('<a class="highlight"><i class="foundicon-flag"/></a>'))
 })

 function add_highlight(type, list){
   highlights = JSON.parse(localStorage["highlights"])
   if (undefined === highlights[type]){ 
     highlights[type] = [];
   }
   highlights[type].push(list)
   highlights[type] = $.unique(highlights[type]);
   localStorage["highlights"] = JSON.stringify(highlights)
 }

 function remove_highlight(type, list){
   highlights = JSON.parse(localStorage["highlights"])
   if (undefined === highlights[type]){ return }
   highlights[type] = remove_from_array(highlights[type], list)
   $('ul.favourite_entity_lists li[entity_type=' + type + '] ul li a[href*="' + list + '"]').parent().find('a.highlight').removeClass('active')
   localStorage["highlights"] = JSON.stringify(highlights)
 }

 function apply_highlights(){
   $('a.entity').removeClass('highlighted')
   highlights = JSON.parse(localStorage["highlights"])
   var entities = []
   for (type in highlights){
     for (i in highlights[type]){
       var list = highlights[type][i]
       var entities = list_entities(type, list)
       $('ul.favourite_entity_lists li[entity_type=' + type + '] ul li a[href*="' + list + '"]').parent().find('a.highlight').addClass('active')
       var type_entities = $('a.entity.' + type)
       for (j in entities){
         var entity_id = entities[j];
         type_entities.filter('[attr-entity_id=' + entity_id + ']').addClass('highlighted')
       }
     }
   }
 }

 $('body').on('click', 'ul.favourite_entity_lists a.highlight', function(){
   var link = $(this)
   var list_link = link.parent().children().last()
   var list = list_link.attr('href').split("/")[3]
   var type = link.closest('li.type').find('a').html()
   highlights = JSON.parse(localStorage["highlights"])
   if (undefined === highlights[type] || ! $.inArray(highlights[type], list)){
     add_highlight(type, list)
   }else{
     remove_highlight(type, list)
   }
   apply_highlights()
 })
}
