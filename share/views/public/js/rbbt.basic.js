rbbt.mlog = function(data){
  console.log(data)
}

// AJAX

rbbt.ajax = function(params){
  params.config = function(xhr, options){ xhr.setRequestHeader( "X-Requested-With", "XMLHttpRequest"); return xhr; }
  if (undefined === params.method) params.method = "GET"
  return m.request(params)
}

rbbt.post = function(url, data, params){
  var request_params
  if (typeof url === 'object'){
    request_params = url
    if (data) request_params.data = data
  }else{

    if (undefined === params)  params = {}
    if (undefined === params.url) params.url = url

    request_params = {url: url, method: "POST", data: data, serialize: function(formData){return formData} }
  }

  if (undefined === request_params.method) request_params.method = 'POST'
  if (undefined === request_params.serialize) request_params.serialize = function(formData) {return formData}

  if (request_params.data){
    var formData = new FormData()
    forHash(request_params.data, function(key,value){
      formData.append(key, value)
    })
    request_params.data = formData
  }

  return rbbt.ajax(request_params)
}

rbbt.insist_request = function(params, deferred, timeout, missing){
  if (undefined === deferred) deferred = m.deferred()
  if (undefined === timeout) timeout = 1000
  if (timeout > 20000) timeout = 20000

  params.extract = function(xhr, xhrOptions){
    if (xhr.status != '200') throw(xhr)
    return xhr.responseText
  }


  rbbt.ajax(params).then(
    function(res){
      deferred.resolve(res)
    }, 
    function(xhr){ 
      m.redraw()
      if (xhr.status == '202'){ 
        if (xhr.responseURL != params.url) params = $.extend(params, {url: xhr.responseURL, method: 'GET', data: params.data})
        if (params.data !== undefined && params.data['_update'] !== undefined) params.data['_update'] = undefined
          setTimeout(function(){ m.redraw(); rbbt.insist_request(params, deferred,timeout*2.5) }, timeout)
      }else{ 
        deferred.reject(new Error("Status " + xhr.status + " in '" + params.url + "': " + xhr.statusText))
      }
    }
  )

  return deferred.promise
}

// LocalStorage

rbbt.LS = {}

rbbt.LS.load = function(key){
 var content = localStorage[key]
 if (content === undefined)
  return undefined
 else
  return JSON.parse(content)
}

rbbt.LS.store = function(key, value){
 localStorage[key] = JSON.stringify(value)
}


