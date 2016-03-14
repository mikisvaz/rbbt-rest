rbbt.mlog = function(data){
  console.log(data)
}

// AJAX

rbbt.ajax = function(params){
  if (undefined === params.method) params.method = "GET"
  if (rbbt.proxy && params.url.indexOf('//') < 0 && params.url.indexOf('/') == 0){
    params.url = rbbt.proxy + params.url
  }else{
    params.config = function(xhr, options){ xhr.setRequestHeader( "X-Requested-With", "XMLHttpRequest"); return xhr; }
  }

  if (params.cookies){
    forHash(params.cookies, function(k,v){rbbt.set_cookie(k,v)})
    params.cookies_set = true
    params.onreadystatechange = function(){
      if (params.cookies_set){
        forHash(params.cookies, function(k,v){rbbt.remove_cookie(k)})
        params.cookies_set = false
      }
    }
  }

  req = m.request(params)

  return req
}

rbbt.insist_request = function(params, deferred, timeout, missing){
  if (undefined === deferred) deferred = m.deferred()
  if (undefined === timeout) timeout = 1000
  if (timeout > 20000) timeout = 20000

  params.extract = function(xhr, xhrOptions){
    if (xhr.status != '200') throw(xhr)
    return xhr.responseText.length === 0 && xhrOptions.deserialize === JSON.parse ? null : xhr.responseText
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

rbbt.post = function(url, data, params){
  var request_params
  if (typeof url === 'object'){
    request_params = url
    if (data) request_params.data = data
  }else{

    if (undefined === params)  params = {}
    if (undefined === params.url) params.url = url

    request_params = {url: url, method: "POST", data: data, serialize: function(formData){return formData} }
    forHash(params, function(k,v){request_params[k] = v})
  }

  if (undefined === request_params.method) request_params.method = 'POST'
  if (undefined === request_params.serialize) request_params.serialize = function(formData) {return formData}

  if (request_params.data){
    var formData = new FormData()
    forHash(request_params.data, function(key,value){
      if (typeof value == 'object')
        formData.append(key, JSON.stringify(value))
      else
        if (undefined !== value) formData.append(key, value)
    })
    request_params.data = formData
  }

  //return rbbt.ajax(request_params)
  return rbbt.insist_request(request_params)
}

// Cookies

rbbt.set_cookie = function(name,value){
  Cookies.set(name, value)
}

rbbt.get_cookie = function(name){
  if (undefined === name)
    return Cookies.get()
  else
    return Cookies.get(name)
}

rbbt.remove_cookie = function(name){
  Cookies.remove(name)
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


// 
rbbt.logged_in = function(){
  return (undefined !== user && user != 'none')
}
