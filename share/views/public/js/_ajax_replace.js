var reload_seconds_for_try = {0: 1, 1: 1, 2: 2, 3: 2, 4: 3, 5: 7, 6: 7, 7: 7, 8: 7, 9: 7, 10: 30, 11: 30, 12: 60, 13: 120, 14: 120, 15: 120, 16: "STOP"}

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

  console.log(options.data)
  response = $.ajax(options)
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

  $.ajax({
    url : href,
    cache: false,
    beforeSend: function(){ object.addClass("reloading"); object.find("span.error").remove() },
    complete: complete,
    error: function( req, text, error ) {
      href = remove_parameter(href, '_update');
      href = remove_parameter(href, '_');
      error_span = $('<span>').html(error).addClass('error')
      error_message = $(req.responseText).find('span.error_message')
      error = $('<div>').append(error_span).append(error_message)
      object.removeClass("reloading").addClass("error").css('height', 0).html(error).css('height', 'auto').attr('target-href', href);
    },
    success: function( data, stat, req ) {
      object.removeClass('error');
      if (req.status == 202){
        object.addClass("reloading");
        href = remove_parameter(href, '_update');
        href = remove_parameter(href, '_');
        var reload_seconds = reload_time(object);

        if (reload_seconds == "STOP"){
          object.removeClass("reloading").addClass("error").html("Maximum number or retries reached").attr('reload-attempts', 0);
        }else{
          window.setTimeout(function(){replace_object(object, href, embedd, complete)}, reload_seconds * 1000);
        }
      }else{
        object.removeClass("reloading").attr('reload-attempts', 0);
        if (embedd){
          if (undefined !== req.getResponseHeader("URI")){
            href = req.getResponseHeader("URI")
          }else{
            href = remove_parameter(href, '_update');
            href = remove_parameter(href, '_');
          }
          object.html(data).addClass("embedded").attr('target-href', href);
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

  replace_object(link, href);
}

function update_embedded(object, reload){
  var href = object.attr('target-href');
  if (reload == true){
      href = add_parameters(href, '_update=reload');
      href = add_parameters(href, '_=' + Math.random().toString());
  }
  replace_object(object, href, true);
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

    embedded.attr('target-href', url)

    update_embedded(embedded);

    return false;
  })
}

