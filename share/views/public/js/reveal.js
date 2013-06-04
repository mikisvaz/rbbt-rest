$('body').on('click', 'a.rbbt_reveal_trigger', function(){
  var link = $(this);
  var source_id = link.attr('attr-reveal_id')
  var content = $('#' + source_id)
  $('#modal1').attr('attr-reveal_source_id', source_id).find('.content').html(content.html());
  update_rbbt();
  return true
});


