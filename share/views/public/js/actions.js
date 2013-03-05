function load_action(link){
  var action_list_item = link.parent('li');
  var action_list = action_list_item.parent('ul');
  var action_controller = action_list.parents('.action_controller').first();
  var action_div = action_controller.next('.action_loader');
  var href = link.attr('href')

  setup_action_controls = function(jqXHR, textStatus){
    var action_div = action_controller.next('.action_loader');
    if (jqXHR.status == 202){
      action_controller.removeClass('active');

      if (action_div.html() == ""){
        action_div.html("<span class='loading'>Loading ...</span>");
      }
    }else{ 
      action_controller.addClass('active'); 
    }
    var action_div = action_controller.next('.action_loader').first();
    if (action_div.find('> .action_card > .action_parameters').length > 0){
      action_controller.find('dd.controls > ul > li.parameters').addClass('active');
    }else{
      action_controller.find('dd.controls > ul > li.parameters').removeClass('active');
    }
  }

  if( ! action_div.hasClass('reloading') ) {
    action_div.removeClass('active');
    action_list.find('li').removeClass('active');
    action_list_item.addClass('active');
    replace_object(action_div, href, true, setup_action_controls);

    return false
  }
}

function display_parameters(){
  var link = $(this);
  var action_loader = link.parents('.action_controller').first().next('.action_loader').first();
  var action_parameters = action_loader.find('.action_parameters').first();
  var action_content = action_parameters.next('.action_content').first();

  action_parameters.toggleClass('active')
  action_content.toggleClass('shifted')

  return false
}

function setup_action(){
  activate_action = function(){
    var link = $(this);
    load_action(link);
    return false
  };

  reload_action = function(){
    var link = $(this);

    var action_list_item = link.parent('li');
    var action_list = action_list_item.parent('ul');
    var action_controller = action_list.parent('dd').parent('.action_controller');
    var action_div = action_controller.next('.action_loader').first();

    if (action_div.attr('target-href') != undefined){
      update_embedded(action_div)
    }

    return false
  };

  var body = $('body');

  body.on('click', 'dl.action_controller > dd.actions  ul > li > a.entity_list_action', activate_action)
  body.on('click', 'dl.action_controller > dd.actions  ul > li > a.entity_action', activate_action)
  body.on('click', 'dl.action_controller > dd.controls > ul > li > a.reload_action', reload_action)
  body.on('click', 'dl.action_controller > dd.controls > ul > li.parameters > a', display_parameters)
}


