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
  return m.render(mobj)
}

// From: https://www.sitepoint.com/currying-in-functional-javascript/
rbbt.curry = function(uncurried) {
  var parameters = Array.prototype.slice.call(arguments, 1);
  return function() {
    return uncurried.apply(this, parameters.concat(
             Array.prototype.slice.call(arguments, 0)
           ));
  };
};

rbbt.default = function(val, def){
  if (undefined === val || null === val) return def
  else return val
}

rbbt.url_add_script_name = function(url){

  if (script_name != undefined && url[0] == "/" && url.indexOf(script_name) != 0){
    url = script_name + url
  }

  return url
}

rbbt.link_add_script_name = function(link){
  
  console.log(link)
  var l = $(link)
  console.log(l)
  l.attr('href', rbbt.url_add_script_name(l.attr('href')))
  return l[0].outerHTML;
}

