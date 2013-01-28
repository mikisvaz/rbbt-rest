function replace_fragments(){
  $('a.fragment').each(function(){replace_link($(this))});
}

function setup_action(){
  $('div.actions > ul > li > a.entity_action').click(function(){
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

function setup_page_reload(){
  $('a#reload_page').click(function(){
    var url = window.location.toString();

    url = remove_parameter(url, '_update');
    url = add_parameters(url, '_update=reload');

    url = remove_parameter(url, '_');
    url = add_parameters(url, '_=' + Math.random().toString());

    window.location = url
    return false
  })
}

function setup_rbbt(){
  replace_fragments();
  setup_action();
  setup_page_reload();
}
