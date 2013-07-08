function show_reveal(modal_id, content, source_id){
  var modal = $('#' + modal_id)

  modal.find('.title').html("")
  modal.find('.content').html("")
  modal.removeClass('url').attr('attr-reveal_source_id', source_id).find('.content').html(content);
  update_rbbt();
  return true
}

function open_url_in_reveal(modal, url, complete){
  var modal = $('#' + modal)
  modal.find('.title').html("")
  modal.find('.content').html("")
  replace_object(modal.find('.content'), url, true, function(){
    modal.addClass('url').foundation('reveal', 'open')
    modal.find('.link-reveal-modal').attr('href', url)
    if (undefined !== complete){ complete()}
  })
}

$('body').on('click', 'a.rbbt_reveal_trigger', function(){
  var link = $(this);
  var source_id = link.attr('attr-reveal_id');
  var content = $('#' + source_id);
  var modal = link.attr('data-reveal-id');
  show_reveal(modal, content.html(), source_id);
  return true
});

$('body').on('submit', '.reveal-modal form.rename', function(){
  var form = $(this);
  var new_name = form.find('input[name=rename]').val()
  var type = page_entity_type()
  var column = page_entity_map_column()
  var map_id = page_entity_map()
  var url = '/entity_map/rename/' + type + '/' + column + '/' + map_id
  url = add_parameter(url, "new_name", new_name)

  window.location = url
  return false
});


$('body').on('click', 'a.close-reveal-modal', function(){
  var modal = $(this).closest('.reveal-modal')
  return true
})
