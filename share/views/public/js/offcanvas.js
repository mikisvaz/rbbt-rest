function setup_offcanvas(){
  var body = $('body');

  body.on('click', 'a.offcanvas_button', function(){
    var link = $(this);
    var main = link.parent();
    var offcanvas = main.find('.offcanvas');

    offcanvas.toggleClass('active');

    main.toggleClass('shifted');
 
    if (! offcanvas.hasClass('offcanvas-positioned')){
      var relative_top = offcanvas.position().top;
      offcanvas.css('top',  - relative_top);
      offcanvas.addClass('offcanvas-positioned');
    }
 
  })

  register_dom_update('.offcanvas', function(offcanvas){
    offcanvas.each(function(){
      var offcanvas = $(this);
      var main = offcanvas.parent();
      var button = $('<a class="offcanvas_button"> <i class="general foundicon-right-arrow open_icon"></i> <i class="general foundicon-left-arrow close_icon"></i> </a>')

      main.addClass('has-offcanvas'); 

      main.prepend(button).removeClass('shifted');
    })
  
  })
}
