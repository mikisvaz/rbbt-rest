function rbbt_job(workflow, task, params, complete){
  var url = "/" + workflow + '/' + task;
  var async = undefined !== complete;

  response = $.ajax({
    url: url,
    async: async,
    method: 'POST',
    data: $.extend({_format: 'json'}, params),

    success: function( data, stat, req ) {
      if (req.status == 202){
        window.setTimeout(function(){rbbt_job(workflow, task, params, complete)}, reload_seconds * 1000);
      }else{
        if (async){
          return complete(data);
        }else{
          return data
        }
      }
    },
  })

  if (async){
    return false;
  }else{
    return JSON.parse(response.responseText);
  }
}
