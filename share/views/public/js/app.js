function fit_content(){
 var height = window.innerHeight - $('footer').outerHeight(true);
 $('#content').css('min-height', height)
 $('#top_menu dl.rbbt_menu').css('max-height', height - 100)
}

function update_rbbt(){
 update_dom()

 $('.rbbt_reveal_trigger').reveal()
 $('table').table()
 //$('table.tablesorter').tablesorter()
 $('body > #modal').modal()
 $('.action_controller').action_controller()
 $('#top_menu li.favourites').favourites('update_list_selects').favourites('update_map_selects')

 start_defferred()
 fit_content()
}

$(function(){

 register_dom_update('#top_menu > ul > li.reload', function(item){
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

 $('#top_menu li.favourites').favourites()

 update_rbbt()
})

// Activate tools

