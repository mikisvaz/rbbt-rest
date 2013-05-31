$('body').on('click', 'a.rbbt_reveal_trigger', function(){
  var link = $(this);
  var content = link.next('.rbbt_reveal_content');
  $('#modal1').html(content.html());
  update_rbbt();
  return true
})


