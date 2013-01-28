function replace_object(object, href, embedd){
  if (embedd === undefined){
    embedd = false;
  }

  $.ajax({
    url : href,
    beforeSend: function(){ object.addClass("reloading") },
    error: function( req, text, error ) {
      object.removeClass("reloading");
      object.addClass("error");
    },
    success: function( data, stat, req ) {
      if (req.status == 202){
        object.addClass("reloading");
        href = remove_parameter(href, '_update');
        href = remove_parameter(href, '_');
        window.setTimeout(function(){replace_object(object, href, embedd)}, 7000);
      }else{
        object.removeClass("reloading");
        if (embedd){
          href = remove_parameter(href, '_update');
          href = remove_parameter(href, '_');
          object.html(data).addClass("embedded").attr('target-href', href);
        }else{
          object.replaceWith(data);
        }
      }
    }
  })
}

function replace_link(link){
  var href = $(link).attr('href');

  replace_object(link, href);
}

function update_embedded(object){
  var href = object.attr('target-href');
  href = add_parameters(href, '_update=reload')
  href = add_parameters(href, '_=' + Math.random().toString());
  replace_object(object, href, true);
}
