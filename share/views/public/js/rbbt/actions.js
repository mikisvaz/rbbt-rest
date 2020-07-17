$.widget("rbbt.action_controller", {

  options: {
    saved: {},
  },

  _dump: function(){
    localStorage['rbbt.action_controller.saved'] = JSON.stringify(this.options.saved)
    localStorage['rbbt.action_controller.bookmarked'] = JSON.stringify(this.options.bookmarked)
  },

  _load: function(){
    if (undefined === localStorage['rbbt.action_controller.bookmarked']){
      this.options.saved = {};
      this.options.bookmarked = []
      this._dump();
    }else{
      this.options.saved = JSON.parse(localStorage['rbbt.action_controller.saved'])
      this.options.bookmarked = JSON.parse(localStorage['rbbt.action_controller.bookmarked'])
    }
  },

  _untrack: function(url){
    this.options.bookmarked = remove_from_array(this.options.bookmarked, url);
    this._dump();
    this._update_jobs();
  },

  _track: function(){
    var url = this._url();
    if ($.inArray(url, this.options.bookmarked) == -1){
      this.options.bookmarked.push(url);
    }
    this._dump();
    this._update_jobs();
  },

  _update_jobs: function(){
    var job_list = $('#top_menu .user .jobs')
    job_list.html("")
    for(i in this.options.bookmarked){
      var url = this.options.bookmarked[i];

      var action = url.split('?')[0].split("/")[3]
      var element = url.split('?')[0].split("/")[4]

      action = unescape(action)
      element = unescape(element)
      var name = [action, element].join(" - ");
      var a = $('<a>').attr('href', url).html(name);
      var li = $('<li>').append(a);

      var icon = $('<i class="general fi-minus">')
      var remove = $('<a class=remove_element></a>').append(icon)
      li.prepend(remove)

      job_list.append(li);
    }
    this._update_flag()
  },

  _toogle_track: function(){
    if (this.element.find('.controls > .url.bookmarked').length > 0){
      this._untrack(this._url());
    }else{
      this._track();
    }
  },

  _create: function() {
    var tool = this
    var controller = tool.element;

    controller.on('click', '> .action_menu  .button', function(e){ tool._activate_action(this); return false});
    controller.on('click', '> .controls > .reload', function(e){ tool._reload_action(this); return false});
    controller.on('click', '> .controls > .parameters', function(e){ tool._display_parameters(this); return false});
    controller.on('click', '> .controls > .description', function(e){ tool._display_description(this); return false});
    controller.on('click', '> .controls > .pin', function(e){ tool._toggle_pin(this); return false});
    controller.on('click', '> .controls > .url', function(e){ tool._toogle_track(this); return false});
    $('#top_menu .user .jobs').on('click', 'a.remove_element', function(){
      var link = $(this).next('a')
      tool._untrack(link.attr('href'))
    })

    this.options.controller = controller
    this.options.action_controls = controller.find('> .controls')
    this.options.action_list = controller.find('> .action_menu')

    this.options.complete = function(jqXHR, textStatus){
      var action_controller = tool.options.controller
      var action_list_item = action_controller.find('.action_menu > .loading, .action_menu > .active')
      var action_div = tool._loader();

      if (jqXHR.status == 202){
        if (action_div.attr('reload-attempts') != '0'){
          action_controller.removeClass('active').addClass('loading'); 

          var response = $(jqXHR.responseText)
          var stat = response.find('span.status').html()
          var message = response.find('.step_messages li:first').html()
          var progress = response.find('.step.progress')

          text = [$('<div class="header">').html(stat), $('<div class="content">').html(message)]
          action_controller.siblings('.action_progress').html("").append(text).append(progress);
          update_rbbt()
        }
      }else{ 
        action_controller.siblings('.action_progress').html("");
        action_controller.removeClass('loading').removeClass('disabled'); 
        action_list_item.removeClass('loading').removeClass('disabled');

        action_controller.find('.controls > .reload').removeClass('disabled');
      }

      var action_div = tool._loader();
      action_controller.find('.controls > .url').removeClass('disabled');
      if (action_div.find('> .action_card > .action_parameters').length > 0){
        action_controller.find('.controls > .parameters').removeClass('disabled');
        action_controller.find('.controls > .pin').removeClass('disabled');
      }else{
        action_controller.find('.controls > .parameters').addClass('disabled');
        action_controller.find('.controls > .pin').addClass('disabled');
      }
      if (action_div.find('> .action_card > .action_description').length > 0){
        action_controller.find('.controls > .description').addClass('disabled');
      }else{
        action_controller.find('.controls > .description').addClass('disabled');
      }
    }

    this._load();
    this._update_jobs();
  },

  _update_flag: function(){
    if ($.inArray(this._url(), this.options.bookmarked) != -1){
      $(this.element).find('> .controls > .url').addClass('bookmarked')
      }else{
        $(this.element).find('> .controls > .url').removeClass('bookmarked')
      }
    },

    _activate_action: function(e){
      var action_list_item = $(e)
      var action_list = action_list_item.parent('.action_menu');
      var link = action_list_item.find('> a')
      link = action_list_item


      var action_controller = this.options.controller;
      action_controller.find('.controls > .reload').addClass('disabled');

      this._load_action(link);

      var action = link.html()
      if (this.options.saved[action] !== undefined){
        $(this.element).find('> .controls > .pin').addClass('saved')
        }else{
          $(this.element).find('> .controls > .pin').removeClass('saved')
        }

        this._update_flag()

        action_list.addClass('active');

        return false
      },

      _unpin_parameters: function(){
        var controller = $(this.element)
        var action = controller.find('.action_menu .active a').first().html()
        this.options.saved[action] = undefined
        controller.find('> .controls > .pin').removeClass('saved')
      },

      _pin_parameters: function(){
        var controller = $(this.element)
        var action = $(this.element).find('.action_menu .active a').first().html()
        var loader = this._loader();
        this.options.saved[action] = loader.attr('form-params')
        controller.find('> .controls > .pin').addClass('saved')
        this._dump()
      },

      _toggle_pin: function(){
       var action = $(this.element).find('.action_menu .active a').first().html()

       if (this.options.saved[action] != undefined){
         this._unpin_parameters();
       }else{
         this._pin_parameters();
       }
     },

     _loader: function(){
       return $(this.element).siblings('.action_loader').first();
     },

     _url: function(){
       var url = this._loader().attr('target-href');
       if (undefined === url){ return url}
       return unescape(remove_parameter(url, '_'))
     },

     _open_url: function(){
       var action_controller = this.element;
       var action_div = this._loader();

       if (this._url() !== undefined){
         window.location = this._url();
       }

       return false
     },


     _reload_action: function(e){
       if($(e).hasClass('disabled')){ return false}
       var action_list_item = $(e);
       var action_list = action_list_item.parent('.controls');
       var action_controller = action_list.parent('.action_controller');
       var action_div = this._loader();

       action_div.html("");

       action_controller.find('.controls > .reload').addClass('disabled');

       if (action_div.attr('target-href') != undefined){
         update_embedded(action_div, true, this.options.complete)
       }

       return false
     },

     _display_parameters: function(e){
       if(! $(e).hasClass('active')){ return false}
       var link = $(e);
       var action_controller = link.parents('.action_controller').first()
       var action_loader = this._loader();
       var action_parameters = action_loader.find('.action_parameters').first();
       var action_description = action_loader.find('.action_description').first();
       var action_content = action_parameters.next('.action_content').first();

       action_parameters.toggleClass('active');
       action_description.removeClass('active');
       action_content.toggleClass('shifted');

       $.scrollTo(this.element, {axis:'y', offset:{top: -$("#top_menu").height() - 20}})

       return false
     },

     _display_description: function(e){
       if(! $(e).hasClass('active')){ return false}
       var link = $(e);
       var action_controller = link.parents('.action_controller').first()
       var action_loader = this._loader();
       var action_parameters = action_loader.find('.action_parameters').first();
       var action_description = action_loader.find('.action_description').first();
       var action_content = action_parameters.next('.action_content').first();

       action_description.toggleClass('active');
       action_parameters.removeClass('active');
       action_content.toggleClass('shifted');

       $.scrollTo(this.element, {axis:'y', offset:{top: -$("#top_menu").height() - 20}})

       return false
     },

     _load_action: function(link){
       var action_list_item = link.parent('.button');
       action_list_item = link
       var action_list = action_list_item.parent('.action_menu');
       var action_controller = action_list.parents('.action_controller').first();
       var action_div = this._loader();
       var href = link.attr('href')
       href = add_parameter(href, '_layout', 'false')
        
       action_div.html("");

       var action = link.html()
       var saved = this.options.saved[action]

       if (undefined !== saved){
         href = add_parameters(href, saved)
       }


       if( ! action_div.hasClass('reloading') ) {
         action_div.removeClass('active');
         action_controller.find('.controls > .reload').removeClass('active');
         action_controller.find('.controls > .parameters').removeClass('active');
         action_list.find('.button').removeClass('active').removeClass('loading');
         action_list_item.addClass('active');
         action_controller.addClass('loading');

         replace_object(action_div, href, true, this.options.complete);
         var tool = this
         action_div.on('click', '.reload', function(e){ 
           update_embedded(action_div, true, tool.options.complete); return false
         });

         return false
       }
     }
   })

