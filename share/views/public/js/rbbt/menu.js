register_dom_update('dl.tabs > dt, dl.rbbt_tabs > dt.next, .rbbt_menu > .next, .rbbt_vertical_menu > .next, .rbbt_accordion > .next', function(title){
  title.click(function(){
    var option = $(this)
    var content = option.next()

    var showed = content.hasClass('show')

    option.siblings().removeClass('show')

    if (showed) { 
      content.removeClass('show');
      option.removeClass('show');
    } else { 
      content.addClass('show');
      option.addClass('show');
    }
  })
})

