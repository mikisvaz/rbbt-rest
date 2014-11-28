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

