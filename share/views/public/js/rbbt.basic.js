rbbt.mlog = function(data){
  console.log(data)
  return data
}

// AJAX

rbbt.ajax = function(params, complete){
  if (undefined === params.complete){
   params.complete = complete
  }
  if (undefined === params.method) params.method = "GET"
  if (rbbt.proxy && params.url.indexOf('//') < 0 && params.url.indexOf('/') == 0){
    params.url = rbbt.proxy + params.url
  }else{
    params.config = function(xhr, options){ xhr.setRequestHeader( "X-Requested-With", "XMLHttpRequest"); return xhr; }
  }

  params.url = rbbt.url_add_script_name(params.url)

  if (params.cookies){
    var config = params.config
    if (undefined === config){ 
      config = function(xhr){
        forHash(params.cookies, function(k,v){console.log("Set: " + k); rbbt.set_cookie(k,v)})
        var old = xhr.onreadystatechange
        xhr.onreadystatechange = function(){
          if (xhr.readyState == 2){
            forHash(params.cookies, function(k,v){console.log("Remove: " + k);rbbt.remove_cookie(k)})
          }
          old(xhr)
        }
      }
    }else{
      var old_config = config
      config = function(xhr){
        old_config(xhr)
        forHash(params.cookies, function(k,v){console.log("Set: " + k); rbbt.set_cookie(k,v)})
        var old = xhr.onreadystatechange
        xhr.onreadystatechange = function(){
          if (xhr.readyState == 2){
            forHash(params.cookies, function(k,v){console.log("Remove: " + k);rbbt.remove_cookie(k)})
          }
          old(xhr)
        }
      }
    }

    params.config = config
  }

  if (params.json == false){
    params.deserialize = function(body){ return body }
  }

  // circunvent m.request parametrizeUrl

  params.url.replace(/:[a-z]\w+/gi, function(token){
    if (undefined === params.data) params.data = {}
    params.data[token.slice(1)] = token
  })


  req = m.request(params)

  if (undefined !== params.success || undefined !== params.error){
    req = req.then(params.success, params.error);
  }
    
  if (undefined !== params.complete){
    req = req.then(params.complete);
  }

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

rbbt.get = function(url, params){
  var request_params
  if (typeof url === 'object'){
    request_params = url
  }else{

    if (undefined === params)  params = {}
    if (undefined === params.url) params.url = url

    request_params = {url: url, method: "GET"}
    forHash(params, function(k,v){request_params[k] = v})
  }

  if (undefined === request_params.method) request_params.method = 'GET'

  return rbbt.insist_request(request_params)
}

rbbt.post = function(url, data, params){
  var request_params
  if (typeof params === 'function'){
    params = {complete: params}
  }
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
  Cookies.set(name, value, { sameSite: 'strict'})
}

rbbt.get_cookie = function(name){
  if (undefined === name)
    return Cookies.get()
  else
    return Cookies.get(name)
}

rbbt.remove_cookie = function(name){
  Cookies.remove(name, { sameSite: 'strict'})
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
 localStorage[key] = JSON.stringify(value);
}

rbbt.LS.delete = function(key){
  delete(localStorage[key]);
}


// 
rbbt.logged_in = function(){
  return (undefined !== user && user != 'none')
}
