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
 var url = remove_section_hash(url)
 url = remove_parameter(url, parameter)
 url = add_parameters(url, parameter + "=" + value)
 return url;
}

function remove_section_hash(url){
 if (url.match("#")){
   return url.replace(/#.*/,'')
 }else{
   return url
 }
}

function remove_parameter(url, parameter){
 var url = remove_section_hash(url)

 if (url.match("&" + parameter + "=")){
  return url.replace("&" + parameter + "=", '&REMOVE=').replace(/REMOVE=[^&]+/, '').replace(/\?&/, '?').replace(/&&/, '&').replace(/[?&]$/, '');
 }else{
  return url.replace("?" + parameter + "=", '?REMOVE=').replace(/REMOVE=[^&]+/, '').replace(/\?&/, '?').replace(/&&/, '&').replace(/[?&]$/, '');
 }
}

function clean_element(elem){
 return elem.replace(/\//g, '-..-').replace(/%/g,'o-o').replace(/\[/g,'(.-(').replace(/\]/g,').-)')
}

function restore_element(elem){
 return unescape(elem.replace(/-\.\.-/g, '/').replace(/o-o/g,'%')).replace(/\(\.-\(/g,'[').replace(/\)\.-\)/g,']');
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
function require_js(url, success, script){
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
  if (typeof production == 'undefined') production = false
  var cache = production;

  if (undefined === success){
   async = false;
  }else{
   async = true;
  }

  url = url.replace(/^\/js\//, '/js-find/')

  if ($.inArray(url, required_js) >= 0){
    if (typeof success == 'function'){ success.call(script) }
  }else{
    var _success = function(script_text){ required_js.push(url); console.log("Required and loaded JS: " + url); if (typeof success == 'function'){ success(script) }; }
    if (typeof rbbt.proxy != 'undefined')
      url = rbbt.proxy + url
    $.ajax({url: url, cache:cache, dataType:'script', async: async, success: _success} ).fail(function(jqxhr, settings, exception){ console.log('Failed to load ' + url + ': ' + exception)});
  }
 }
}

function remove_from_array(array, elem){
 return jQuery.grep(array, function(value) {
  return value != elem;
 });
}

function merge_hash(destination, source){
  for (var property in source) {
    if (source.hasOwnProperty(property)) {
      destination[property] = source[property];
    }
  }
  return destination;
}

function clean_hash(h){
  var clean = {}

  forHash(h, function(k,v){
    if (undefined !== v) clean[k] = v
  })

  return clean
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

function mapArray(obj, fn, thisObj){
  var result = [];
  forArray(obj, function(e){
    result.push(fn.call(thisObj,e))
  },thisObj)
  return result;
}
function contains(a, obj) {
  for (var i = 0; i < a.length; i++) {
    if (a[i] === obj) {
      return true;
    }
  }
  return false;
}

function return_same(obj){ return obj }

function pvalue_score(pvalue){ if (undefined === pvalue || null == pvalue || pvalue == ""){ return pvalue }; if (pvalue < 0){ return 10 * Math.log10(-pvalue)}else{ return -10 * Math.log10(pvalue) }}

function get_gradient(values, color1, color2){
  var Color = net.brehaut.Color;
  var color1 = Color(color1)
  var color2 = Color(color2)
  var steps = values.length
  var clean_values = []
  forArray(values,function(v){ 
    if (typeof v == 'string') v = parseFloat(v)
    if (typeof v == 'number' && ! isNaN(v)) clean_values.push(v) 
  })
  var max = Math.max.apply(null,clean_values)
  var min = Math.min.apply(null,clean_values)
  var diff = max - min
  var colors = []
  forArray(values, function(value){
    if (typeof value == 'string') value = parseFloat(value)
    if (typeof value == 'number'){
      var a 
      if (diff != 0)
        a = (value - min)/diff
      else
        a = 1
      colors.push(color1.blend(color2, a).toString())
    }else{
      colors.push(undefined)
    }
  })
  return colors
}

function get_sign_gradient(values, color1, color0, color2){
  var Color = net.brehaut.Color;
  var color1 = Color(color1)
  var color0 = Color(color0)
  var color2 = Color(color2)
  var steps = values.length
  var clean_values = []
  forArray(values,function(v){ 
    if (typeof v == 'string') v = parseFloat(v)
    if (typeof v == 'number' && ! isNaN(v)) clean_values.push(v) 
  })
  var max = Math.max.apply(null,clean_values)
  var min = Math.min.apply(null,clean_values)
  var colors = []
  forArray(values, function(value){
    if (typeof value == 'string') value = parseFloat(value)
    if (typeof value == 'number'){
      if (value > 0){
        var a = value/max
        colors.push(color0.blend(color1, a).toString())
      }else{
        var a = value/min
        colors.push(color0.blend(color2, a).toString())
      }
    }else{
      colors.push(undefined)
    }
  })
  return colors
}

// from http://stackoverflow.com/questions/1885557/simplest-code-for-array-intersection-in-javascript
function intersect_sorted(a, b)
{
  var ai=0, bi=0;
  var result = new Array();

  while( ai < a.length && bi < b.length )
  {
     if      (a[ai] < b[bi] ){ ai++; }
     else if (a[ai] > b[bi] ){ bi++; }
     else /* they're equal */
     {
       result.push(a[ai]);
       ai++;
       bi++;
     }
  }

  return result;
}

function intersect(array1, array2){
  return array1.filter(function(n) {
      return array2.indexOf(n) != -1
  });
}

function clean_array_properties(array){
  var n = {}

  for(var i = 0; i < array.length; i += 1){
    n[i.toString()] = array[i]
  }

  return(n)
}

function save_file(data, file, type){
  var blob = new Blob([data], {type: type});
  saveAs(blob, file);
}

function save_binary(data, file, type){
  var bytes = new Uint8Array(data.length);

  for (var i=0; i<data.length; i++) {
    bytes[i] = data.charCodeAt(i);
  }

  save_file(bytes, file, type)
}

function save_base64(data, file, type){
  data = atob(data)

  save_binary(data, file, type);
}

function is_array(obj){
  return obj.constructor === Array;
}
