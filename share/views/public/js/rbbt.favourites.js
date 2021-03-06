
rbbt.favourites = {};
var fav_module = rbbt.favourites;

fav_module.entities = {types: m.prop({})}
fav_module.entities.init = function(){
  return FavouriteEntities.get().then(fav_module.entities.types)
}

fav_module.lists = {types: m.prop({})}
fav_module.lists.init = function(){
  return FavouriteLists.get().then(fav_module.lists.types)
}

fav_module.maps = {types: m.prop({})}
fav_module.maps.init = function(){
  return FavouriteMaps.get().then(fav_module.maps.types)
}

fav_module.update_favourites = function(){
 return m.sync([fav_module.lists.init(), fav_module.entities.init(), fav_module.maps.init()])
}

fav_module.isFavourite_entity = function(entity){
 return fav_module.entities.types()[entity.type] !== undefined && fav_module.entities.types()[entity.type][entity.code] !== undefined
}

fav_module.isFavourite_list = function(list){
 return fav_module.lists.types()[list.type] !== undefined && fav_module.lists.types()[list.type][list.id] !== undefined
}

fav_module.isFavourite_map = function(map){
 return fav_module.maps.types()[map.type] !== undefined && fav_module.maps.types()[map.type][map.id] !== undefined
}

//{{{ TOGGLE

fav_module.toggleFavourite_entity = function(){
 var entity = rbbt.page.entity();

 if (fav_module.isFavourite_entity(entity)){
  var url = '/remove_favourite_entity/' + entity.type + '/' + clean_element(entity.code)
  url = rbbt.url_add_script_name(url)
  rbbt.post({url: url, data: entity.info}).then(fav_module.update)
 }else{
  var url = '/add_favourite_entity/' + entity.type + '/' + clean_element(entity.code)
  url = rbbt.url_add_script_name(url)
  rbbt.post({url: url, data: entity.info}).then(fav_module.update)
 }
}

fav_module.toggleFavourite_list = function(){
 var list = rbbt.page.list();

 if (fav_module.isFavourite_list(list)){
  rbbt.post({url: '/remove_favourite_entity_list/' + list.type + '/' + clean_element(list.id)}).then(fav_module.update)
 }else{
  rbbt.post({url: '/add_favourite_entity_list/' + list.type + '/' + clean_element(list.id)}).then(fav_module.update)
 }
}

fav_module.toggleFavourite_map = function(){
 var map = rbbt.page.map();

 if (fav_module.isFavourite_map(map)){
  rbbt.post({url: '/remove_favourite_entity_map/' + map.type + '/' + clean_element(map.column) + '/' + clean_element(map.id)}).then(fav_module.update)
 }else{
  rbbt.post({url: '/add_favourite_entity_map/' + map.type + '/' + clean_element(map.column) + '/' + clean_element(map.id)}).then(fav_module.update)
 }
}

fav_module.toggleFavourite = function(){
  if (rbbt.page.entity())
    return fav_module.toggleFavourite_entity()
  if (rbbt.page.list())
    return fav_module.toggleFavourite_list()
  if (rbbt.page.map())
    return fav_module.toggleFavourite_map()
}

//{{{ VIEWS

fav_module.star_view = function(){
 if (! rbbt.page.entity())
  if (! rbbt.page.list())
   if (! rbbt.page.map())
    return
   else
    return m('.item.pointer', {onclick: fav_module.toggleFavourite},  m('i.icon.star', {class: (fav_module.isFavourite_map(rbbt.page.map()) ? 'favourite' : 'not_favourite')}))
  else
   return m('.item.pointer', {onclick: fav_module.toggleFavourite}, m('i.icon.star', {class: (fav_module.isFavourite_list(rbbt.page.list()) ? 'favourite' : 'not_favourite')}))
 else
  return m('.item.pointer', {onclick: fav_module.toggleFavourite}, m('i.icon.star', {class: (fav_module.isFavourite_entity(rbbt.page.entity()) ? 'favourite' : 'not_favourite')}))
}

fav_module.draw_favourite_menu = function(){
 var favourites = fav_module.entities.types()
 var types = Object.keys(favourites)

 return rbbt.mview.dropdown('Entities',
           [m('.item.buttons', [m('.ui.button',{onclick: fav_module.highlight}, 'highlight'),m('.ui.button',{onclick: fav_module.clear_highlight}, 'clear')])].concat(types.map(function(type, index){ 
             var _type = favourites[type]
             var entities = Object.keys(_type)

             var type_items = entities.map(function(entity, index){ 
               var url = _type[entity].url();
               url = rbbt.url_add_script_name(url);
               return m('a.item', {href: url}, _type[entity].name) 
             })
             return rbbt.mview.dropdown(type, type_items)
           })))
}

fav_module.list_controls = m.prop()
fav_module.toggle_list_controls = function(list){
  if (fav_module.list_controls() == list)
    fav_module.list_controls(undefined)
  else
    fav_module.list_controls(list)

  fav_module.update()
}

fav_module.remove_list = function(type, list){
  var url ='/remove_favourite_entity_list/' + type + '/' + clean_element(list);
  url = rbbt.url_add_script_name(url);
  rbbt.post({url: url}).then(fav_module.update)
}

fav_module.draw_favourite_list_menu = function(){
 var favourites = fav_module.lists.types()
 var types = Object.keys(favourites)

 var new_list_types = known_types.map(function(type,index){
   return m('.item', {'data-type': type, onclick: m.withAttr('data-type', fav_module.new_list)}, type)
 })

 var new_lists = rbbt.mview.dropdown("New list", new_list_types)

 var type_items = types.map(function(type, index){ 
   var _type = favourites[type]
   var lists = Object.keys(_type)

   return rbbt.mview.dropdown(type, lists.map(function(list, index){ 
     var url = _type[list].url()
     url = rbbt.url_add_script_name(url);

     var link = m('a.item', {href: url, style: 'display: inline-block'}, _type[list].name)
     if (fav_module.list_controls() == list){
       var highlight_g = m('span.bullet.green.highlight', {onclick: function(){_type[list].highlight('green'); return false}},'')
       var highlight_r = m('span.bullet.red.highlight', {onclick: function(){_type[list].highlight('red'); return false}},'')
       var highlight_p = m('span.bullet.purple.highlight', {onclick: function(){_type[list].highlight('purple'); return false}},'')
       var remove = m('span.minus.remove', {onclick: function(){fav_module.remove_list(type,list); return false}},'')
       link = [link, m('div.controls', [highlight_g, highlight_p, highlight_r, remove])]
     }
     return [
      m('span.open_fav_controls', {onclick: function(){fav_module.toggle_list_controls(list); return false}},''),
      link,
      m('br')
     ] 
   }))
 })

 type_items.unshift(new_lists)
 return rbbt.mview.dropdown('Lists', type_items)
}

fav_module.draw_favourite_map_menu = function(){
  var favourites = fav_module.maps.types()
  var types = Object.keys(favourites)

  return rbbt.mview.dropdown('Maps',types.map(function(type, index){ 
    var _type = favourites[type]
    var maps = Object.keys(_type)

    return m('.ui.dropdown.item', [
      m('i.icon.dropdown'), 
      type,
      m('.menu', maps.map(function(map, index){ 
        var url = _type[map].url()
        url = rbbt.url_add_script_name(url);
        var link = m('a.item', {href: url, _style: 'display: inline-block;width:100%'}, _type[map].name)
        //return [link, m('span.bullet.green', {onclick: function(){_type[map].highlight('green'); return false}},''),m('br')] 
        return link
      }))
    ]);
  }))
}

fav_module.view = function(){
  //m.render($('#top_menu .favourite')[0], [
  //  m('.item.pointer', {onclick: fav_module.toggleFavourite}, fav_module.star_view()), 
  //  m('.item', {style: 'padding: 0px'}, fav_module.draw_favourite_menu()),
  //  m('.item', {style: 'padding: 0px'}, fav_module.draw_favourite_list_menu()),
  //  m('.item', {style: 'padding: 0px'}, fav_module.draw_favourite_map_menu())
  //])
  m.render($('#top_menu .favourite')[0], [
    fav_module.star_view(), 
    fav_module.draw_favourite_menu(),
    fav_module.draw_favourite_list_menu(),
    fav_module.draw_favourite_map_menu()
  ])
}

//{{{ HOOKS

fav_module._update_list_select= function(select, type, lists){
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
      option = $('<option attr-entity_type="' + type + '" class="automatic_load" value="' + name.id + '">' + name.id + '</option>');
    }else{
      option = $('<option attr-entity_type="' + type + '" class="automatic_load" selected=selected value="' + name.id + '">' + name.id + '</option>');
    }
    select.append(option);
    return true
  })
},

fav_module.update_list_selects= function(){
  $('select.favourite_lists').find('option.automatic_load').remove()

  $.each(fav_module.lists.types(), function(type, lists){
    $('select.favourite_lists[type=' + type + ']').each(function(){
   var select = $(this);
   fav_module._update_list_select(select, type, lists);
  })
  $('select.favourite_lists[type=All]').each(function(){
   var select = $(this);
   select.append($('<option class="automatic_load ui" disabled>'+ type +'</option>'));
   fav_module._update_list_select(select, type, lists);
  })
 });
}

fav_module._update_map_select= function(select, type, maps){
 if (select.attr('attr-allow-empty') == 'true'){
  var option = $('<option value="none" class="loaded">none</option>')
  select.append(option);
 }

 var selected = null;

 if (select.attr('attr-selected') != undefined ){
  selected = select.attr('attr-selected');
 }

 $.each(maps, function(name, elems){
  var option = null;
  var name = elems
  if (selected == null || name != selected){
   option = $('<option attr-column="' + name.column + '" attr-entity_type="' + name.type + '" class="automatic_load" value="' + name.id + '">' + name.id + '</option>');
  }else{                                
   option = $('<option attr-column="' + name.column + '" attr-entity_type="' + name.type + '" class="automatic_load" selected=selected value="' + name.id + '">' + name.id + '</option>');
  }
  select.append(option);
  return true
 })
},

fav_module.update_map_selects= function(){
 $('select.favourite_maps').find('option.automatic_load').remove()

 $.each(fav_module.maps.types(), function(type, maps){
  $('select.favourite_maps[type=' + type + ']').each(function(){
   var select = $(this);
   fav_module._update_map_select(select, type, maps);
  })

  $('select.favourite_maps[type=All]').each(function(){
   var select = $(this);
   select.append($('<option class="automatic_load ui" disabled>'+ type +'</option>'));
   fav_module._update_map_select(select, type, maps);
  })
 });
}

fav_module.highlight = function(){
 var all_targets = []

 for (type in fav_module.entities.types()){
  var _type = fav_module.entities.types()[type]
  console.log(_type)
  var n = Object.keys(_type)
  var targets = n.map(function(e){ return _type[e]})
  all_targets = all_targets.concat(targets)
 }

 rbbt.aesthetics.apply_aes({targets: all_targets, aes: 'color', value: 'gold'})
}

fav_module.clear_highlight = function(){
 rbbt.aesthetics.apply_aes({selector: '.entity', aes: 'color', value: 'remove'})
}

fav_module.new_list = function(type){
  var url = '/entity_list/' + type + '/new/?_layout=false';
  url = rbbt.url_add_script_name(url);
  rbbt.modal.controller.show_url(url, "New " + type + " list")
}

fav_module.hooks = function(){
 fav_module.update_list_selects()
 fav_module.update_map_selects()
}

fav_module.update = function(){
 if (rbbt.logged_in())
  fav_module.update_favourites().then(fav_module.view).then(function(){ $('.__dropdown:not([tabindex])').dropdown()}).then(fav_module.hooks)
}
