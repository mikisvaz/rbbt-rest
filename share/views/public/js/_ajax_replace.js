var reload_seconds_for_try = {0: 1, 1: 1, 2: 2, 3: 2, 4: 3, 5: 7, 6: 7, 7: 7, 8: 7, 9: 7, 10: 30, 11: 30, 12: 60, 13: 120, 14: 120, 15: 120, 16: "STOP"}
var _reloading_class = 'loading'

var ajax_processes = []
function update_ajax_counter(){
  $('#ajax_processes').html(ajax_processes.length)
}
function add_ajax(url){
  ajax_processes.push(url)
  update_ajax_counter();
}

function remove_ajax(url){
  ajax_processes.splice( $.inArray(url, ajax_processes), 1 );
  update_ajax_counter();
}

$.old_ajax = $.ajax;
$.ajax = function(url, options){
  if (typeof url == 'string'){
    options['url'] = url;
  }else{
    options = url;
    url = options['url'];
  }

  url = add_parameter(url, '_layout', 'false')
  options['url'] = url
  options["crossDomain"] = true

  add_ajax(url);

  complete = options['complete'];
  if (undefined === complete){ options['complete'] = function(){ remove_ajax(url)} }
  if (typeof complete == 'function'){ options['complete'] = [complete, function(){ remove_ajax(url)}] }
  if (typeof complete == 'array'){ options['complete'].push(function(){ remove_ajax(url)}) }

  return $.old_ajax(options);
}

function reload_time(object){
  var tries = object.attr('reload-attempts');
  if (undefined === tries){ tries = 0 };

  if (typeof tries == 'string' || tries instanceof String){ tries = parseInt(tries) }


  object.attr('reload-attempts', tries + 1);
  return reload_seconds_for_try[tries];
}

function get_ajax(options, complete){
  options.success = function( data, stat, req ) {
    if (req.status == 202){
      href = options.url
      href = remove_parameter(href, '_update');
      href = remove_parameter(href, '_');
      options.url = href
      window.setTimeout(function(){ get_ajax(options, complete)}, 3 * 1000);
    }else{
      if (undefined !== complete){
        return complete(data)
      }else{
        return(data)
      }
    }
  }

  if (undefined === complete){
    options.async = false
  }else{
    options.async = true
  }


  response = $.ajax(options)

  if (undefined !== response.responseJSON){
    return response.responseJSON
  }

  if (undefined !== response.responseText){
    if (response.status == 202){
      href = options.url
      href = remove_parameter(href, '_update');
      href = remove_parameter(href, '_');
      options.url = href
      return get_ajax(options, complete);
    }else{
      return response.responseText;
    }
  }else{
    return response;
  }
}

function replace_object(object, href, embedd, complete){
  if (embedd === undefined){ embedd = false; }
  var clean_href = remove_parameter(remove_parameter(href,'_'), '_update')

  object.addClass("embedded").attr('target-href', href)

  $.ajax({
    url : href,
    cache: false,
    beforeSend: function(){ object.addClass(_reloading_class); object.find("span.error").remove() },
    complete: complete,

    error: function( req, text, error ) {
      href = remove_parameter(href, '_update');
      href = remove_parameter(href, '_');

      error_message = error.sub(/\n\n.*/,'')

      error_span = $('<span>').html(error_message).addClass('error')
      error = $('<div>').append(error_span)
      object.removeClass(_reloading_class).addClass("error").css('height', 0).html(error).css('height', 'auto').attr('target-href', clean_href);
    },

    success: function( data, stat, req ) {
      object.removeClass('error');
      if (req.status == 202){
        object.addClass(_reloading_class);
        href = remove_parameter(href, '_update');
        href = remove_parameter(href, '_');
        var reload_seconds = reload_time(object);
        var progress = $(data).find('.progress')
        var percent = undefined
        var counts = undefined
        
        if (progress.length > 0)
          if (progress.is('.percent'))
            percent = progress.attr('data-value')
          else
            counts = progress.attr('data-value')
          

        if (percent !== undefined){
          bar = $('.ui.progress.teal.indicator').attr('data-value', percent).attr('data-total', 100)
          object.prepend(bar)
        }
        if (reload_seconds == "STOP"){
          var a =$('<a href="#">').html("insist").click(function(){
            replace_object(object, href, embedd, complete)
            return false;
          })
          object.empty().removeClass(_reloading_class).addClass("error").addClass('TEST').attr('reload-attempts', 0).html("Maximum number of retries reached ").append(a)
        }else{
          window.setTimeout(function(){replace_object(object, href, embedd, complete)}, reload_seconds * 1000);
        }
      }else{
        object.removeClass(_reloading_class).attr('reload-attempts', 0);
        if (embedd){
          if (undefined !== req.getResponseHeader("URI")){
            href = req.getResponseHeader("URI")
          }else{
            href = remove_parameter(href, '_update');
            href = remove_parameter(href, '_');
          }
          object.addClass("embedded").attr('target-href', clean_href).get(0).innerHTML = data;
          object.find('script').each(function(){eval(this.text = this.text || $(this).text())} );

          capture_embedded_form(object);
          update_rbbt();
        }else{
          object.replaceWith(data);

          update_rbbt();
        }
      }
    }
  })
}

function replace_link(link){
  var href = $(link).attr('href');
  href = add_parameter(href, '_layout','false')

  replace_object(link, href);
}

function update_embedded(object, reload, complete){
  var href = object.attr('target-href');
  if (reload == true){
      href = add_parameters(href, '_update=reload');
      href = add_parameters(href, '_=' + Math.random().toString());
  }
  replace_object(object, href, true, complete);
}


function capture_embedded_form(object){

  object.find('form').submit(function(){ 
    var form = $(this);
    var embedded = object;

    var params = "";

    form.find('input').not('[type=submit]').not('[type=radio]').not('[type=checkbox]').each(function(){
      var input = $(this)
      if (params.length > 0){ params += '&'}
      params += input.attr('name') + "=" + input.val();
    })

    form.find('input[type=checkbox]:checked').each(function(){
      var input = $(this)
      if (params.length > 0){ params += '&'}
      params += input.attr('name') + "=" + input.val();
    })

    form.find('input[type=radio]:checked').each(function(){
      var input = $(this)
      if (params.length > 0){ params += '&'}
      params += input.attr('name') + "=" + input.val();
    })

    form.find('select').not('[type=submit]').each(function(){
      var select = $(this)
      var option = select.find('option:selected');
      if (params.length > 0){ params += '&'}
      params += select.attr('name') + "=" + option.val();
    })

    form.find('textarea').each(function(){
      var input = $(this)
      if (params.length > 0){ params += '&'}
      params += input.attr('name') + "=" + escape(input.val());
    })

    
    var url = embedded.attr('target-href');

    if (url.indexOf('?') == -1){
      url = url + '?' + params;
    }else{
      url = url.replace(/\?.*/, '?' + params);
    }

    url = add_parameter(url, '_layout', 'false')

    embedded.attr('target-href', url).attr('form-params', params)

    update_embedded(embedded);

    return false;
  })
}

