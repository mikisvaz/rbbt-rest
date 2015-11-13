var rbbt = {}

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
  console.log((new Date()).toString() + ' => ' + obj)
}

rbbt.caller = function(){
  var err = new Error();
  return err.stack;
}

rbbt.mount = function(obj, component){
  obj.className = obj.className + ' mithril-mount'
  m.mount(obj, component)
}

rbbt.mrender = function(mobj){
  return render(mobj)
}
