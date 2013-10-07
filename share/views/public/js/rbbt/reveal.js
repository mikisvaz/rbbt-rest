$.widget("rbbt.reveal", {
  options: {
   modal: $('body > #modal')
  },

  _create: function() {
   var tool = this;
   var modal = this.options.modal
   tool.element.click(function(){
    var link = $(this);
    var source_id = link.attr('attr-reveal_id');
    var title     = link.attr('attr-reveal_title');
    var content = $('#' + source_id);
    modal.modal('show', content.html(), title, source_id);
    return false
   })
  },
})

