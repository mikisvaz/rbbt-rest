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
    var tag = "rbbt_dom_update_" + hex_md5(selector);
    var elements = $(selector).not('[rbbt-update_tags*=' + tag + ']')
    if (elements.length > 0){
      var prev = elements.attr('rbbt-update_tags');
      if (undefined === prev){
        elements.attr('rbbt-update_tags', tag);
      }else{
        elements.attr('rbbt-update_tags', prev + " " + tag);
      }
      $.each(rbbt_updater[selector], function(){
        this(elements);
      })
    }
  }
}

