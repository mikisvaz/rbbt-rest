register_dom_update('dl.dropdown_menu > .next, dl.menu > .next, dl.tabs > dt, dl.rbbt_tabs > dt.next, dl.rbbt_menu > .next, dl.rbbt_vertical_menu > .next, dl.rbbt_accordion > .next', function(title){
  title.click(function(){
    var option = $(this)
    var content = option.next()
    var menu = option.parent('dl')

    var showed = content.hasClass('show')

    option.siblings().removeClass('show')

    if (showed) { 
      content.removeClass('show');
      option.removeClass('show');
      menu.removeClass('show')
    } else { 
      content.addClass('show');
      option.addClass('show');
      menu.addClass('show')
    }
    return false;
  })
})

