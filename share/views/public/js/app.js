function fit_content(){
 var height = window.innerHeight - $('footer').outerHeight(true);
 var top_offset = $('#content').get()[0].offsetTop
 $('#content').css('min-height', height - top_offset - 48)
 $('#top_menu dl.rbbt_menu').css('max-height', height - 100)
}

function update_rbbt(){
 update_dom()

 $('table').table()
 $('.action_controller').action_controller()
 $('.ui.accordion').accordion();
 $('.ui.checkbox').checkbox();

 $('.rbbt_reveal_trigger').reveal()

 //$('table.tablesorter').tablesorter()
 //$('body > #modal').modal()
 //$('#top_menu .favourites').favourites('update_list_selects').favourites('update_map_selects')
 //$('#top_bar .favourites').favourites('update_list_selects').favourites('update_map_selects')
 //$('select:not(.favourite_lists)').dropdown();
 //$('.selection.dropdown').find('.item:not([data-value])').removeClass('item').addClass('header');

 start_deferred()
 fit_content()
 $('.preload').removeClass('preload');

 if (undefined !== rbbt.aesthetics){
   rbbt.aesthetics.load()
   rbbt.aesthetics.apply()
 }


 rbbt.favourites.update()
}

$(function(){

 register_dom_update(('.next'), function(elem){
   elem.click(function(){
     var trigger = $(this)
     var next = trigger.next()

     next.siblings().removeClass('show').removeClass('active')

     next.toggleClass('show')
     trigger.toggleClass('active')
   })
 })

 register_dom_update('#top_menu > .reload', function(item){
  item.click(function(){
   var url = window.location.toString();
   url = url.replace(/#$/, '');

   url = remove_parameter(url, '_update');
   url = add_parameters(url, '_update=reload');

   url = remove_parameter(url, '_');
   url = add_parameters(url, '_=' + Math.random().toString());

   window.location = url
   return false
  })
 })

 register_dom_update('dt a.entity_list', function(link){
  link.click(function(){
   window.location = $(this).attr('href')
   return false;
  })
 })

 if (undefined !== rbbt.favourites && user != 'none') rbbt.favourites.update()

 update_rbbt()
})

