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
  if (url.match("&" + parameter)){
    return url.replace("&" + parameter + "=", '&REMOVE=').replace(/REMOVE=[^?]+/, '').replace(/\?&/, '?').replace(/&&/, '&').replace(/[?&]$/, '');
  }else{
    return url.replace("?" + parameter + "=", '?REMOVE=').replace(/REMOVE=[^?]+/, '').replace(/\?&/, '?').replace(/&&/, '&').replace(/[?&]$/, '');
  }
}
