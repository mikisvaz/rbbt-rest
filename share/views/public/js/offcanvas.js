function setup_offcanvas(){
  var body = $('body');
  body.on('click', 'a.offcanvas_button', function(){
    var link = $(this);
    var main = link.parent();
    var offcanvas = main.find('.offcanvas');

    offcanvas.toggleClass('active');

    main.toggleClass('shifted');

    return false;
  })

  register_dom_update('.offcanvas', function(offcanvas){
    offcanvas.each(function(){
      var offcanvas = $(this);
      var main = offcanvas.parent();
      //var offcanvas_button = $('<a class="offcanvas_button"> <i class="general foundicon-right-arrow open_icon"></i> <i class="general foundicon-left-arrow close_icon"></i> </a>')
      var offcanvas_button= $('<a href="#" class="offcanvas_button sidebar-button small button seccondary" style="width:auto;height:auto">' +
      '<svg xml:space="preserve" enable-background="new 0 0 48 48" viewBox="0 0 48 48" height="12px" width="12px" y="0px" x="0px" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns="http://www.w3.org/2000/svg" id="Layer_1" version="1.1">' +
      '<line y2="8.907" x2="48" y1="8.907" x1="0" stroke-miterlimit="10" stroke-width="8" stroke="#000000" fill="none"/>' +
      '<line y2="24.173" x2="48" y1="24.173" x1="0" stroke-miterlimit="10" stroke-width="8" stroke="#000000" fill="none"/>' +
      '<line y2="39.439" x2="48" y1="39.439" x1="0" stroke-miterlimit="10" stroke-width="8" stroke="#000000" fill="none"/>' +
      'Menu' +
      '</svg>' +
      '</a>');


      main.addClass('has-offcanvas'); 

      main.prepend(offcanvas_button).removeClass('shifted');
    })
  })
}
