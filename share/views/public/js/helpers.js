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

function require_js(url, success){
  var async = false;
  var cache = production;
  console.log("Require js: " + url)
  if (undefined === success){
    async = false;
  }else{
    async = true;
  }

  url = url.replace('/js/', '/js-find/')
  $.ajax({url: url, cache:cache, dataType:'script', async: async, success: success} ).fail(function(jqxhr, settings, exception){
    console.log('Exception loading: ' + url)
    console.log(exception)
    console.log(jqxhr)
  })
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
 //return escape(text).replace(/\%/g, '\\%').replace(/\//g, '\\/').replace(/\./g, '\\.')
 return encodeURIComponent(text)//.replace(/[^\w-_]/g, function(s){return '\\' + s})
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
