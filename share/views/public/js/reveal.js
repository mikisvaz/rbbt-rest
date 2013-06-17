function show_reveal(modal, content, source_id){
  $('#' + modal).attr('attr-reveal_source_id', source_id).find('.content').html(content);
  update_rbbt();
  return true
}
$('body').on('click', 'a.rbbt_reveal_trigger', function(){
  var link = $(this);
  var source_id = link.attr('attr-reveal_id');
  var content = $('#' + source_id);
  var modal = link.attr('data-reveal-id');
  show_reveal(modal, content.html(), source_id);
  return true
});


