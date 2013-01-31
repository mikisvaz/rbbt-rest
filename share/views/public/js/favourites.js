function setup_favourites(){

  register_dom_update('a#add_favourite', function(link){
    link.click(function(){
      var link = $(this);
      var entity_type = link.attr('entity_type')
      var entity = link.attr('entity')
      var entity_info = JSON.parse(link.attr('entity_info'))

      var url = "/add_favourite/" + entity_type + "/" + entity

      $.ajax({url: url, type: 'POST', data: entity_info})
    
      return false
    })
  })
}


