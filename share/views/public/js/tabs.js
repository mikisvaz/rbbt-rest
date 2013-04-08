function activate_tab(){
  $(this).siblings().removeClass('selected').end().next('dd').andSelf().addClass('selected');
}

function setup_tabs(){
  $('body').on('click', 'dl.tabs dt', activate_tab)
}
