

function setup_action_old(){
  $('div.actions > ul > li > a.entity_list_action').click(function(){
    var link = $(this);
    var action_list_item = link.parent('li');
    var action_list = action_list_item.parent('ul');
    var action_list_div = action_list.parent('div.actions');
    var action_div = action_list_div.find('div.action');
    var href = link.attr('href')


    if( ! action_div.hasClass('reloading') ) {
      action_list.find('li').removeClass('active');
      action_list_item.addClass('active');
      replace_object(action_div, href, true);
    }
    return false
  })

  $('div.actions > ul > li.reload_action > a').click(function(){
    var link = $(this);
    var action_list = $(this).parents('div.actions').first();
    var action_div = action_list.find('div.action');

    if (action_div.attr('target-href') != undefined){
      update_embedded(action_div)
    }

    return false
  })
}


function setup_action(){
  activate_action = function(){
    var link = $(this);
    var action_list_item = link.parent('li');
    var action_list = action_list_item.parent('ul');
    var action_list_div = action_list.parent('div.actions');
    var action_div = action_list_div.find('div.action');
    var href = link.attr('href')


    if( ! action_div.hasClass('reloading') ) {
      action_list.find('li').removeClass('active');
      action_list_item.addClass('active');
      replace_object(action_div, href, true);
    }
    return false
  };

  reload_action = function(){
    var link = $(this);
    var action_list = $(this).parents('div.actions').first();
    var action_div = action_list.find('div.action');

    if (action_div.attr('target-href') != undefined){
      update_embedded(action_div)
    }

    return false
  };

  var body = $('body');

  body.on('click', 'div.actions > ul > li > a.entity_list_action', activate_action)
  body.on('click', 'div.actions > ul > li > a.entity_action', activate_action)
  body.on('click', 'div.actions > ul > li.reload_action > a', reload_action)
}

function setup_page_reload(){
  var body = $('body');
  body.on('click', 'a#reload_page', function(){
    var url = window.location.toString();

    url = remove_parameter(url, '_update');
    url = add_parameters(url, '_update=reload');

    url = remove_parameter(url, '_');
    url = add_parameters(url, '_=' + Math.random().toString());

    window.location = url
    return false
  })
}

function setup_fragments(){
  register_dom_update('a.fragment', function(link){
    link.each(function(){replace_link($(this))});
  })
}

function deactivate_off_links(){
  var body = $('body');
  body.on('click', 'a.off', function(){return false})
}

function setup_rbbt(){
  setup_fragments();
  setup_action();
  setup_page_reload();
  setup_favourites();
  deactivate_off_links();
  update_dom();
}
