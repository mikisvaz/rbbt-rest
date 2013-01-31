var rbbt_updater = []

function register_dom_update(selector, func){
  if (rbbt_updater[selector] === undefined){
    rbbt_updater[selector] = [func];
  }else{
    rbbt_updater[selector].push(func);
  }
}

function update_dom(){
  for (selector in rbbt_updater){
    var elements = $(selector).not('[class*=rbbt_action_setup]')
    if (elements.length > 0){
      elements.addClass('rbbt_action_setup')
      $.each(rbbt_updater[selector], function(){
        this(elements);
      })
    }
  }
}

