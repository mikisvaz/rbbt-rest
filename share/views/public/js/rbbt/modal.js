$.widget("rbbt.modal", {
  _create: function() {
  },

  _reset_modal: function(modal_title, source_id){
    var tool = this

    var modal = this.element
    modal.html('').addClass('modal')

    var title = $('<div>').addClass('title')
    if (modal_title !== undefined){ title.html(modal_title) }
    var controls = $('<div>').addClass('controls')
    controls.append($('<a>').addClass('toggle_favourite').append($('<i>').addClass('fi-star')))
    controls.append($('<a>').addClass('link-reveal-modal').append($('<i>').addClass('fi-arrow-right')))
    controls.append($('<a>').addClass('close-reveal-modal').append($('<i>').addClass('fi-x')))

    var header = $('<div>').addClass('header').append(title).append(controls)

    modal.append(header)
    var content = $('<div>').addClass('content').html(content)
    modal.attr('attr-reveal_source_id', source_id)
    
    modal.on('click', 'a.close-reveal-modal', function(){ tool.close() })

    modal.on('click', 'a.toggle_favourite', function(){ 
      var url = $(tool.element).find('> .content').attr('target-href')
      if (url !== undefined){
        $('#top_menu .favourites').favourites('toggle_page', url)
      }
      return false
    })

    var content = $('<div>').addClass('content')
    modal.append(content)

    modal.removeClass('url').removeClass('entity')

    return modal;
  },

  _shown_url: function(){
    return $(this.element).find('> .content').attr('target-href')
  },

  update_star: function(){
    var url = this._shown_url()
    if ($('#top_menu .favourites').favourites('is_favourite', url)){
      $(this.element).find('a.toggle_favourite').addClass('active');
    }else{
      $(this.element).find('a.toggle_favourite').removeClass('active');
    }
  },

  show: function(content, title, source_id){
    var tool = this;
    var modal = tool._reset_modal(title, source_id)

    modal.find('> .content').html(content)
    this.element.show()
    this.element.addClass('show');
    update_rbbt()
  },

  ask: function(content, title, complete){
    this.show(content, title)
    $('#modal').find('form').first().submit(complete)
  },

  show_url: function(url, title, source_id, complete){
    var tool = this;
    var modal = this._reset_modal(title, source_id)
    tool.url = url

    $('body').append(modal)

    replace_object(modal.find('> .content'), url, true, function(){
      var url  = tool.url 
      url = remove_parameter(url, '_')

      modal.addClass('url')
      modal.find('.link-reveal-modal').attr('href', url)

      if (url != undefined && url.match(/^\/(?:entity|entity_list|entity_map)\//) != null){
        modal.addClass('entity')
        tool.update_star()
      }

      tool.element.show()
      this.element.addClass('show');
      if (undefined !== complete){ complete()}
      update_rbbt()
    })
  },

  close: function(){
    this.element.removeClass('show');
    this.element.hide()
  }
})



