$.widget("rbbt.reveal", {
  options: {
   modal: $('#modal').first()
  },

  _create: function() {
   var tool = this;
   var modal = this.options.modal;

   tool.element.click(function(){
    var modal = $('#modal').first();
    var link = $(this);
    var source_id = link.attr('attr-reveal_id');
    var title     = link.attr('attr-reveal_title');
    var content = $('#' + source_id);

    var height = window.innerHeight - $('#top_menu').outerHeight(true);
    modal.css('height',height)
    rbbt.modal.controller.show(content.html(), title)
    modal.attr('attr-reveal_source_id', source_id)
    return false
   })
  },
})

