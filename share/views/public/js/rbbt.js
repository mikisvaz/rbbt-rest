
rbbt.post = function(params){
  var req_params = {config: rbbt.post.asFormUrlEncoded, serialize: rbbt.post.serialize_data, method: 'POST'}
  for (key in params)
   req_params[key] = params[key]

  return m.request(req_params)
}

rbbt.post.serialize_data = function(obj) {
 var str = [];
 for(var p in obj)
  if (obj.hasOwnProperty(p)) {
   str.push(encodeURIComponent(p) + "=" + encodeURIComponent(obj[p]));
  }
   
 return str.join("&");
}

rbbt.post.asFormUrlEncoded = function(xhr){
 xhr.setRequestHeader("Content-type","application/x-www-form-urlencoded");
}

rbbt.log = function(obj){
 console.log(obj)
}

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
