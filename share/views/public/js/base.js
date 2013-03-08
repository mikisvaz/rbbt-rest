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
  register_dom_update(('a.fragment'), function(link){
    link.each(function(){replace_link($(this))});
  })
  register_dom_update(('a.modal_fragment'), function(link){
    link.click(function(){
      var modal = $('#modal1')
      link.attr('data-reveal-id', 'modal1')
      replace_object(modal, $(this).attr('href'), true)
      return true
    })
  })

}

function deactivate_off_links(){
  var body = $('body');
  body.on('click', 'a.off', function(){return false})
}

function setup_finder(){
  //register_dom_update("#header li.search input", function(elem){
  //  elem.autocomplete({
  //    source: "/find",
  //    minLength: 2,
  //    appendTo: '#find_wrapper'
  //  }).data( "autocomplete" )._renderItem = function( ul, item ) {
  //    var litem =  $( "<li></li>" ).data( "item.autocomplete", item )
  //    var link = $("<a class='select_autocomplete'></a>");

  //    link.append("<span class='match'>" + item.best +  "</span>" )
  //    link.append( "<span class='code'>" + item.value + "</span>")
  //    link.appendTo(litem);
  //    litem.appendTo( ul );
  //  };
  //})
}

function fit_content(){
  var height = window.innerHeight - $('#header').outerHeight(true) - $('#footer').outerHeight(true);
  $('#body').css('min-height', height)
}

function update_rbbt(){
  update_dom();
  start_defferred();
}

function setup_rbbt(){
  setup_fragments();
  setup_action();
  setup_page_reload();
  setup_favourites();
  deactivate_off_links();
  setup_finder();
  setup_offcanvas();
  setup_list_management();
  fit_content();

  update_rbbt();
}
