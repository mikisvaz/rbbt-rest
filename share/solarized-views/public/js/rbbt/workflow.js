function rbbt_job(workflow, task, params, complete){
  var url = "/" + workflow + '/' + task;
  var async = undefined !== complete;

  response = get_ajax({
    url: url,
    async: async,
    method: 'POST',
    data: $.extend({_format: 'json'}, params)
  }, complete)

  if (async){
    return false;
  }else{
    //return JSON.parse(response);
    return response;
  }
}
