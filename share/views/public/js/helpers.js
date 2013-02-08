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

function remove_parameter(url, parameter){
  if (url.match("&" + parameter + "=")){
    return url.replace("&" + parameter + "=", '&REMOVE=').replace(/REMOVE=[^&]+/, '').replace(/\?&/, '?').replace(/&&/, '&').replace(/[?&]$/, '');
  }else{
    return url.replace("?" + parameter + "=", '?REMOVE=').replace(/REMOVE=[^&]+/, '').replace(/\?&/, '?').replace(/&&/, '&').replace(/[?&]$/, '');
  }
}

function clean_element(elem){
  return elem.replace(/\//g, '--')
}

function restore_element(elem){
  return unescape(elem.replace(/--/g, '/'));
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


//{{{ Array helpers

//if(!Array.indexOf){
//  Array.prototype.indexOf = function(obj){
//    for(var i=0; i<this.length; i++){
//      if(this[i]==obj){
//        return i;
//      }
//    }
//    return -1;
//  }
//}
//
//Array.prototype.remove = function(elem) {
//  var match = -1;
//
//  console.log(this)
//  while( (match = this.indexOf(elem)) != -1 ) {
//    this.splice(match, 1);
//  }
//};
//
//Array.prototype.uniq = function() {
// var myarray = this;
//
// new_arr = myarray.filter(function(elem, pos) {
//      return myarray.indexOf(elem) == pos;
// })
//
// return new_arr 
//};
//
