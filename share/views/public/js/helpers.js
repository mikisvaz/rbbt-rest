//{{{ URL PARAMETER CONTROL

function add_parameters(url, parameters){
 var string;

 if ( typeof(parameters) == 'string' || typeof(parameters) == 'String'){
  string = parameters;
 }else{
  var pairs = [];
  for (parameter in parameters){
   pairs.push(parameter + "=" + parameters[parameter]);
  }
  string = pairs.join("&");
 }

 if (string.length == 0){return(url)}

 if (url.indexOf('?') == -1){
  return url + '?' + string;
 }else{
  return url + '&' + string;
 }
}

function add_parameter(url, parameter, value){
 var url = remove_parameter(url, parameter)
 url = add_parameters(url, parameter + "=" + value)
 return url;
}

function remove_parameter(url, parameter){
 if (url.match("&" + parameter + "=")){
  return url.replace("&" + parameter + "=", '&REMOVE=').replace(/REMOVE=[^&]+/, '').replace(/\?&/, '?').replace(/&&/, '&').replace(/[?&]$/, '');
 }else{
  return url.replace("?" + parameter + "=", '?REMOVE=').replace(/REMOVE=[^&]+/, '').replace(/\?&/, '?').replace(/&&/, '&').replace(/[?&]$/, '');
 }
}

function clean_element(elem){
 return elem.replace(/\//g, '--').replace(/%/g,'o-o')
}

function restore_element(elem){
 return unescape(elem.replace(/--/g, '/').replace(/o-o/g,'%'));
}

function parse_parameters(params){
 var ret = {},
 seg = params.replace(/^\?/,'').split('&'),
 len = seg.length, i = 0, s;
 for (;i<len;i++) {
  if (!seg[i]) { continue; }
  s = seg[i].split('=');
  ret[s[0]] = restore_element(s[1]);
 }
 return ret
}

var required_js = [];
function require_js(url, success){
 if (typeof url == 'object'){
   if (url.length > 1){
    var u = url.shift()
    require_js(u, function(){
     require_js(url, success);
    })
    return true
   }else{
    return require_js(url.shift(), success);
   }
 }else{
  var async = true;
  if (undefined === production) production = false
  var cache = production;

  if (undefined === success){
   async = false;
  }else{
   async = true;
  }

  url = url.replace('/js/', '/js-find/')

  if ($.inArray(url, required_js) >= 0){
    if (typeof success == 'function'){ success.call() }
  }else{
    var _success = function(){ required_js.push(url); if (typeof success == 'function'){ success.call() }; }
    $.ajax({url: url, cache:cache, dataType:'script', async: async, success: _success} ).fail(function(jqxhr, settings, exception){ console.log('Failed to load ' + url) })
  }
 }
}

function remove_from_array(array, elem){
 return jQuery.grep(array, function(value) {
  return value != elem;
 });
}

function array_values(hash){
 var tmp_arr = [], key = '';
 for (key in hash) {
  tmp_arr[tmp_arr.length] = hash[key];
 }

 return tmp_arr;
}

function clean_attr(text){
 return encodeURIComponent(text)
}

function uniq(ary) {
 var seen = {};
 return ary.filter(function(elem) {
  var k = elem;
  return (seen[k] === 1) ? 0 : seen[k] = 1;
 })
}
function uniqBy(ary, key) {
 var seen = {};
 return ary.filter(function(elem) {
  var k = key(elem);
  return (seen[k] === 1) ? 0 : seen[k] = 1;
 })
}


function unique(arrayName) {
  var newArray=new Array();
  label:for(var i=0; i<arrayName.length;i++ ){  
    for(var j=0; j<newArray.length;j++ ){ 
    if(newArray[j]==arrayName[i]) 
      continue label;
    }
    newArray[newArray.length] = arrayName[i];
  }
  return newArray;
}

function forHash(obj, fn, thisObj){
  var key, i = 0;
  function exec(fn, obj, key, thisObj){
    return fn.call(thisObj, key, obj[key], obj);
  }
  for (key in obj) {
    if (obj.hasOwnProperty(key)) { 
      if (exec(fn, obj, key, thisObj) === false) {
        break;
      }
    }
  }
  return forHash;
}

function forArray(obj, fn, thisObj){
  var key, i = 0;
  function exec(fn, obj, prop, thisObj){
    return fn.call(thisObj, obj[prop], obj);
  }
  for (var prop in obj) {
    if (obj.hasOwnProperty(prop)) { 
      if (exec(fn, obj, prop, thisObj) === false) {
        break;
      }
    }
  }
  return forArray;
}
