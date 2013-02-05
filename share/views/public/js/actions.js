function load_action(link){
  var action_list_item = link.parent('dd');
  var action_list = action_list_item.parent('dl');
  var action_controller = action_list.parent('.action_controller');
  var action_div = action_controller.next('.action_loader');
  var href = link.attr('href')


  if( ! action_div.hasClass('reloading') ) {
    action_list.find('dd').removeClass('active');
    action_list_item.addClass('active');
    replace_object(action_div, href, true);
  }

}

function setup_action(){
  activate_action = function(){
    var link = $(this);
    load_action(link);
    return false
  };

  reload_action = function(){
    var link = $(this);

    var action_list_item = link.parent('dt');
    var action_list = action_list_item.parent('dl');
    var action_controller = action_list.parent('.action_controller');
    var action_div = action_controller.next('.action_loader');

    if (action_div.attr('target-href') != undefined){
      update_embedded(action_div)
    }

    return false
  };

  var body = $('body');

  body.on('click', 'div.action_controller > dl > dd > a.entity_list_action', activate_action)
  body.on('click', 'div.action_controller > dl > dd > a.entity_action', activate_action)
  body.on('click', 'div.action_controller > dl > dt.reload_action > a', reload_action)
}


