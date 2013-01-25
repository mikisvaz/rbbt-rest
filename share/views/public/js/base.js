function replace_link(link){
  $.ajax({
    url : link.attr('href'),
    beforeSend: function(){ link.addClass("reloading") },
    error: function( req, text, error ) {
      link.removeClass("reloading");
      link.addClass("error");
    },
    success: function( data, stat, req ) {
      if (req.status == 202){
        link.addClass("reloading");
        window.setTimeout(function(){replace_link(link)}, 7000);
      }else{
        link.removeClass("reloading");
        link.replaceWith(data);
      }
    }
  })
}

function replace_fragments(){
  $('a.fragment').each(function(){replace_link($(this))});
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
  setup_page_reload();
}
